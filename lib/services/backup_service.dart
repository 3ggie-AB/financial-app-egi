import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

// Conditional import: mobile pakai google_sign_in, desktop pakai OAuth2 browser
import 'package:google_sign_in/google_sign_in.dart'
    if (dart.library.html) 'package:google_sign_in/google_sign_in.dart';

enum SyncStatus { idle, syncing, success, error, conflict }

class SyncState {
  final SyncStatus status;
  final String? message;
  final DateTime? lastSync;

  const SyncState({
    this.status = SyncStatus.idle,
    this.message,
    this.lastSync,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? message,
    DateTime? lastSync,
  }) =>
      SyncState(
        status: status ?? this.status,
        message: message ?? this.message,
        lastSync: lastSync ?? this.lastSync,
      );
}

// ─── Deteksi platform desktop ────────────────────────────────────────────────
bool get _isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);

// ─── Simple HTTP client untuk desktop OAuth ──────────────────────────────────
class _AuthenticatedClient extends http.BaseClient {
  final Map<String, String> _headers;
  final _inner = http.Client();

  _AuthenticatedClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

class BackupService extends ChangeNotifier {
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  // ── Mobile: google_sign_in ─────────────────────────────────────
  GoogleSignIn? _googleSignIn;

  // ── Desktop: simpan token dari OAuth2 ─────────────────────────
  String? _desktopAccessToken;
  String? _desktopEmail;
  String? _desktopName;
  DateTime? _desktopTokenExpiry;

  SyncState _syncState = const SyncState();
  SyncState get syncState => _syncState;

  bool get isSignedIn {
    if (_isDesktop) {
      return _desktopAccessToken != null && _desktopEmail != null;
    }
    return _googleSignIn?.currentUser != null;
  }

  String? get userEmail {
    if (_isDesktop) return _desktopEmail;
    return _googleSignIn?.currentUser?.email;
  }

  String? get userName {
    if (_isDesktop) return _desktopName;
    return _googleSignIn?.currentUser?.displayName;
  }

  static const _prefsLastSync = 'last_sync_time';
  static const _prefsAutoSync = 'auto_sync_enabled';
  static const _prefsDesktopToken = 'desktop_access_token';
  static const _prefsDesktopEmail = 'desktop_email';
  static const _prefsDesktopName = 'desktop_name';
  static const _prefsDesktopExpiry = 'desktop_token_expiry';
  static const _backupFileName = 'financeku_backup.json';

  bool _autoSyncEnabled = true;
  bool get autoSyncEnabled => _autoSyncEnabled;

  // ─── INIT ──────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _autoSyncEnabled = prefs.getBool(_prefsAutoSync) ?? true;

    final lastSyncStr = prefs.getString(_prefsLastSync);
    if (lastSyncStr != null) {
      _syncState = SyncState(
        status: SyncStatus.idle,
        lastSync: DateTime.tryParse(lastSyncStr),
      );
    }

    if (_isDesktop) {
      // Load saved desktop token
      _desktopAccessToken = prefs.getString(_prefsDesktopToken);
      _desktopEmail = prefs.getString(_prefsDesktopEmail);
      _desktopName = prefs.getString(_prefsDesktopName);
      final expiryStr = prefs.getString(_prefsDesktopExpiry);
      if (expiryStr != null) {
        _desktopTokenExpiry = DateTime.tryParse(expiryStr);
      }

      // Cek apakah token masih valid
      if (_desktopTokenExpiry != null &&
          DateTime.now().isAfter(_desktopTokenExpiry!)) {
        // Token expired, clear
        await _clearDesktopToken();
      }
    } else {
      // Mobile: pakai google_sign_in
      _googleSignIn = GoogleSignIn(
        scopes: ['email', drive.DriveApi.driveFileScope],
      );
      try {
        await _googleSignIn!.signInSilently();
      } catch (_) {}
    }

    notifyListeners();
  }

  Future<void> setAutoSync(bool value) async {
    _autoSyncEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsAutoSync, value);
    notifyListeners();
  }

  // ─── SIGN IN ───────────────────────────────────────────────────
  Future<bool> signInGoogle() async {
    if (_isDesktop) {
      return await _signInDesktop();
    } else {
      return await _signInMobile();
    }
  }

  Future<bool> _signInMobile() async {
    try {
      final account = await _googleSignIn!.signIn();
      notifyListeners();
      return account != null;
    } catch (e) {
      debugPrint('Mobile Google Sign In error: $e');
      return false;
    }
  }

  /// Desktop OAuth2: buka browser, user login, ambil token via redirect ke localhost
  Future<bool> _signInDesktop() async {
    // Baca dari .env — jangan hardcode di sini!
    final clientId = dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
    final clientSecret = dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '';
    const redirectPort = 8085;
    const redirectUri = 'http://localhost:$redirectPort';

    if (clientId.isEmpty) {
      debugPrint('⚠️ GOOGLE_CLIENT_ID tidak ditemukan di file .env');
      _setSyncState(SyncStatus.error,
          'Client ID belum dikonfigurasi di file .env');
      notifyListeners();
      return false;
    }

    try {
      // 1. Buat state random untuk security
      final state = DateTime.now().millisecondsSinceEpoch.toString();

      // 2. Build URL OAuth2
      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope':
            'email profile https://www.googleapis.com/auth/drive.file',
        'state': state,
        'access_type': 'offline',
        'prompt': 'consent',
      });

      // 3. Buka browser
      await _launchBrowser(authUrl.toString());

      // 4. Listen di localhost untuk redirect
      final server = await HttpServer.bind('localhost', redirectPort);
      debugPrint('Waiting for OAuth redirect on localhost:$redirectPort...');

      String? code;
      await for (final request in server) {
        final uri = request.uri;
        code = uri.queryParameters['code'];
        final returnedState = uri.queryParameters['state'];

        if (returnedState != state) {
          request.response
            ..statusCode = 400
            ..write('State mismatch. Coba lagi.')
            ..close();
          await server.close();
          return false;
        }

        // Kirim response ke browser
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write('''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>FinanceKu</title></head>
<body style="font-family:sans-serif;text-align:center;padding:60px;background:#1A1A2E;color:white">
  <h2 style="color:#6C63FF">✅ Login Berhasil!</h2>
  <p>Kembali ke aplikasi FinanceKu.</p>
  <script>window.close();</script>
</body>
</html>
          ''')
          ..close();
        await server.close();
        break;
      }

      if (code == null) return false;

      // 5. Tukar code dengan access token
      final tokenResponse = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
        },
      );

      if (tokenResponse.statusCode != 200) {
        debugPrint('Token exchange failed: ${tokenResponse.body}');
        return false;
      }

      final tokenData = jsonDecode(tokenResponse.body);
      final accessToken = tokenData['access_token'] as String;
      final expiresIn = tokenData['expires_in'] as int? ?? 3600;
      final expiry = DateTime.now().add(Duration(seconds: expiresIn));

      // 6. Ambil info user
      final userResponse = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      String email = '';
      String name = '';
      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        email = userData['email'] ?? '';
        name = userData['name'] ?? '';
      }

      // 7. Simpan token
      _desktopAccessToken = accessToken;
      _desktopEmail = email;
      _desktopName = name;
      _desktopTokenExpiry = expiry;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsDesktopToken, accessToken);
      await prefs.setString(_prefsDesktopEmail, email);
      await prefs.setString(_prefsDesktopName, name);
      await prefs.setString(_prefsDesktopExpiry, expiry.toIso8601String());

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Desktop OAuth error: $e');
      _setSyncState(SyncStatus.error, 'Login gagal: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> _launchBrowser(String url) async {
    try {
      if (Platform.isWindows) {
        // Pakai rundll32 agar URL dengan & tidak terpotong
        await Process.run('rundll32', ['url.dll,FileProtocolHandler', url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      }
    } catch (e) {
      debugPrint('Launch browser error: $e\nBuka manual: $url');
    }
  }

  Future<void> _clearDesktopToken() async {
    _desktopAccessToken = null;
    _desktopEmail = null;
    _desktopName = null;
    _desktopTokenExpiry = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsDesktopToken);
    await prefs.remove(_prefsDesktopEmail);
    await prefs.remove(_prefsDesktopName);
    await prefs.remove(_prefsDesktopExpiry);
  }

  Future<void> signOutGoogle() async {
    if (_isDesktop) {
      await _clearDesktopToken();
    } else {
      await _googleSignIn?.signOut();
    }
    notifyListeners();
  }

  // ─── DRIVE API ────────────────────────────────────────────────
  Future<drive.DriveApi?> _getDriveApi() async {
    if (_isDesktop) {
      if (_desktopAccessToken == null) return null;

      // Cek token tidak expired
      if (_desktopTokenExpiry != null &&
          DateTime.now().isAfter(_desktopTokenExpiry!)) {
        await _clearDesktopToken();
        notifyListeners();
        return null;
      }

      final client = _AuthenticatedClient({
        'Authorization': 'Bearer $_desktopAccessToken',
        'Content-Type': 'application/json',
      });
      return drive.DriveApi(client);
    } else {
      final account = _googleSignIn?.currentUser;
      if (account == null) return null;
      try {
        final headers = await account.authHeaders;
        final client = _GoogleAuthClient(headers);
        return drive.DriveApi(client);
      } catch (e) {
        debugPrint('DriveApi error: $e');
        return null;
      }
    }
  }

  // ─── AUTO SYNC ────────────────────────────────────────────────
  DateTime? _lastTrigger;
  Future<void> triggerAutoSync() async {
    if (!_autoSyncEnabled || !isSignedIn) return;

    final now = DateTime.now();
    _lastTrigger = now;

    await Future.delayed(const Duration(seconds: 3));
    if (_lastTrigger != now) return;

    await backupToDrive(silent: true);
  }

  // ─── CHECK REMOTE NEWER ───────────────────────────────────────
  Future<bool> checkRemoteNewer() async {
    if (!isSignedIn) return false;
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      final files = await driveApi.files.list(
        q: "name='$_backupFileName' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id,modifiedTime)',
      );

      if (files.files == null || files.files!.isEmpty) return false;

      final remoteModified = files.files!.first.modifiedTime;
      if (remoteModified == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_prefsLastSync);
      if (lastSyncStr == null) return true;

      final lastLocalSync = DateTime.tryParse(lastSyncStr);
      if (lastLocalSync == null) return true;

      return remoteModified
          .isAfter(lastLocalSync.add(const Duration(seconds: 5)));
    } catch (e) {
      debugPrint('checkRemoteNewer error: $e');
      return false;
    }
  }

  // ─── BACKUP TO DRIVE ──────────────────────────────────────────
  Future<String?> backupToDrive({bool silent = false}) async {
    if (!silent) {
      _setSyncState(SyncStatus.syncing, 'Mengupload ke Drive...');
    } else {
      _syncState = _syncState.copyWith(status: SyncStatus.syncing);
      notifyListeners();
    }

    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        _setSyncState(SyncStatus.error, 'Belum login ke Google');
        return 'Belum login ke Google';
      }

      final data = await DatabaseService.instance.exportAll();
      final jsonStr = jsonEncode(data);
      final bytes = utf8.encode(jsonStr);

      final existingFiles = await driveApi.files.list(
        q: "name='$_backupFileName' and trashed=false",
        spaces: 'drive',
      );

      final fileMetadata = drive.File()
        ..name = _backupFileName
        ..description =
            'FinanceKu Auto-Sync - ${DateTime.now().toIso8601String()}';

      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: 'application/json',
      );

      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        final fileId = existingFiles.files!.first.id!;
        await driveApi.files.update(fileMetadata, fileId, uploadMedia: media);
      } else {
        await driveApi.files.create(fileMetadata, uploadMedia: media);
      }

      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsLastSync, now.toIso8601String());

      _setSyncState(SyncStatus.success, 'Tersinkron', lastSync: now);
      return null;
    } catch (e) {
      _setSyncState(SyncStatus.error, 'Gagal sync: $e');
      return 'Gagal backup: $e';
    }
  }

  // ─── RESTORE FROM DRIVE ───────────────────────────────────────
  Future<String?> restoreFromDrive() async {
    _setSyncState(SyncStatus.syncing, 'Mengunduh dari Drive...');
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        _setSyncState(SyncStatus.error, 'Belum login ke Google');
        return 'Belum login ke Google';
      }

      final files = await driveApi.files.list(
        q: "name='$_backupFileName' and trashed=false",
        spaces: 'drive',
      );

      if (files.files == null || files.files!.isEmpty) {
        _setSyncState(SyncStatus.error, 'Tidak ada backup di Drive');
        return 'Tidak ada backup di Google Drive';
      }

      final fileId = files.files!.first.id!;
      final response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = await response.stream.expand((e) => e).toList();
      final jsonStr = utf8.decode(bytes);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      await DatabaseService.instance.importAll(data);

      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsLastSync, now.toIso8601String());

      _setSyncState(SyncStatus.success, 'Restore berhasil', lastSync: now);
      return null;
    } catch (e) {
      _setSyncState(SyncStatus.error, 'Gagal restore: $e');
      return 'Gagal restore: $e';
    }
  }

  // ─── LOCAL JSON ───────────────────────────────────────────────
  Future<String?> exportToJson() async {
    try {
      final data = await DatabaseService.instance.exportAll();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final bytes = utf8.encode(jsonStr);
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file =
          File('${dir.path}/financeku_backup_$timestamp.json');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  Future<String?> importFromJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) {
        return 'Tidak ada file dipilih';
      }
      final file = File(result.files.first.path!);
      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      await DatabaseService.instance.importAll(data);
      return null;
    } catch (e) {
      return 'Gagal import: $e';
    }
  }

  Future<List<drive.File>> listDriveBackups() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return [];
      final files = await driveApi.files.list(
        q: "name contains 'financeku' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id,name,createdTime,modifiedTime,size)',
      );
      return files.files ?? [];
    } catch (e) {
      return [];
    }
  }

  // ─── HELPER ───────────────────────────────────────────────────
  void _setSyncState(SyncStatus status, String? message,
      {DateTime? lastSync}) {
    _syncState = SyncState(
      status: status,
      message: message,
      lastSync: lastSync ?? _syncState.lastSync,
    );
    notifyListeners();
  }
}

// ─── Mobile Google Auth Client ────────────────────────────────────────────────
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final _client = http.Client();
  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}