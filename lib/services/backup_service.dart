import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

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

  SyncState copyWith({SyncStatus? status, String? message, DateTime? lastSync}) =>
      SyncState(
        status: status ?? this.status,
        message: message ?? this.message,
        lastSync: lastSync ?? this.lastSync,
      );
}

class BackupService extends ChangeNotifier {
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  final _googleSignIn = GoogleSignIn(scopes: [
    'email',
    drive.DriveApi.driveFileScope,
  ]);

  SyncState _syncState = const SyncState();
  SyncState get syncState => _syncState;

  bool get isSignedIn => _googleSignIn.currentUser != null;
  String? get userEmail => _googleSignIn.currentUser?.email;
  String? get userName => _googleSignIn.currentUser?.displayName;

  static const _prefsLastSync = 'last_sync_time';
  static const _prefsAutoSync = 'auto_sync_enabled';
  static const _backupFileName = 'financeku_backup.json';

  bool _autoSyncEnabled = true;
  bool get autoSyncEnabled => _autoSyncEnabled;

  // ─── INIT ─────────────────────────────────────────────────────
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

    // Coba silent sign in (pakai akun yang sudah pernah login)
    try {
      await _googleSignIn.signInSilently();
    } catch (_) {}

    notifyListeners();
  }

  Future<void> setAutoSync(bool value) async {
    _autoSyncEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsAutoSync, value);
    notifyListeners();
  }

  // ─── GOOGLE SIGN IN ───────────────────────────────────────────
  Future<bool> signInGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      notifyListeners();
      return account != null;
    } catch (e) {
      debugPrint('Google Sign In error: $e');
      return false;
    }
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
    notifyListeners();
  }

  // ─── DRIVE API ────────────────────────────────────────────────
  Future<drive.DriveApi?> _getDriveApi() async {
    final account = _googleSignIn.currentUser;
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

  // ─── AUTO SYNC (dipanggil setelah ada perubahan data) ─────────
  /// Dipanggil oleh FinanceProvider setiap kali ada perubahan data.
  /// Debounce 3 detik agar tidak spam ke Drive.
  DateTime? _lastTrigger;
  Future<void> triggerAutoSync() async {
    if (!_autoSyncEnabled || !isSignedIn) return;

    final now = DateTime.now();
    _lastTrigger = now;

    // Debounce: tunggu 3 detik, kalau ada trigger baru, batalkan yang lama
    await Future.delayed(const Duration(seconds: 3));
    if (_lastTrigger != now) return; // ada trigger yang lebih baru

    await backupToDrive(silent: true);
  }

  // ─── CHECK ON APP OPEN ────────────────────────────────────────
  /// Dipanggil saat app dibuka. Cek apakah data di Drive lebih baru.
  /// Return true jika ada data lebih baru di Drive (perlu konfirmasi user).
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
      if (lastSyncStr == null) return true; // belum pernah sync lokal

      final lastLocalSync = DateTime.tryParse(lastSyncStr);
      if (lastLocalSync == null) return true;

      // Drive lebih baru dari last sync lokal kita
      return remoteModified.isAfter(lastLocalSync.add(const Duration(seconds: 5)));
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
        ..description = 'FinanceKu Auto-Sync - ${DateTime.now().toIso8601String()}';

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
      final file = File('${dir.path}/financeku_backup_$timestamp.json');
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
      if (result == null || result.files.isEmpty) return 'Tidak ada file dipilih';
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
  void _setSyncState(SyncStatus status, String? message, {DateTime? lastSync}) {
    _syncState = SyncState(
      status: status,
      message: message,
      lastSync: lastSync ?? _syncState.lastSync,
    );
    notifyListeners();
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final _client = http.Client();
  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}