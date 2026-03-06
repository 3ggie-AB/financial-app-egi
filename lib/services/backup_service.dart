import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'database_service.dart';

class BackupService {
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  final _googleSignIn = GoogleSignIn(scopes: [
    'email',
    drive.DriveApi.driveFileScope,
  ]);

  bool get isSignedIn => _googleSignIn.currentUser != null;
  String? get userEmail => _googleSignIn.currentUser?.email;
  String? get userName => _googleSignIn.currentUser?.displayName;

  // ─── GOOGLE SIGN IN ───────────────────────────────────────────
  Future<bool> signInGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      return account != null;
    } catch (e) {
      debugPrint('Google Sign In error: $e');
      return false;
    }
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }

  // ─── GOOGLE DRIVE BACKUP ─────────────────────────────────────
  Future<drive.DriveApi?> _getDriveApi() async {
    final account = _googleSignIn.currentUser;
    if (account == null) return null;
    final headers = await account.authHeaders;
    final client = _GoogleAuthClient(headers);
    return drive.DriveApi(client);
  }

  Future<String?> backupToDrive() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return 'Belum login ke Google';

      final data = await DatabaseService.instance.exportAll();
      final jsonStr = jsonEncode(data);
      final bytes = utf8.encode(jsonStr);

      // Check for existing backup file
      final fileName = 'financeku_backup.json';
      final existingFiles = await driveApi.files.list(
        q: "name='$fileName' and trashed=false",
        spaces: 'drive',
      );

      final fileMetadata = drive.File()
        ..name = fileName
        ..description = 'FinanceKu Backup - ${DateTime.now().toIso8601String()}';

      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: 'application/json',
      );

      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        // Update existing file
        final fileId = existingFiles.files!.first.id!;
        await driveApi.files.update(fileMetadata, fileId, uploadMedia: media);
      } else {
        // Create new file
        await driveApi.files.create(fileMetadata, uploadMedia: media);
      }

      return null; // success
    } catch (e) {
      return 'Gagal backup: $e';
    }
  }

  Future<String?> restoreFromDrive() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return 'Belum login ke Google';

      final files = await driveApi.files.list(
        q: "name='financeku_backup.json' and trashed=false",
        spaces: 'drive',
      );

      if (files.files == null || files.files!.isEmpty) {
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
      return null; // success
    } catch (e) {
      return 'Gagal restore: $e';
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

  // ─── LOCAL JSON EXPORT ────────────────────────────────────────
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
      return null; // success
    } catch (e) {
      return 'Gagal import: $e';
    }
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
