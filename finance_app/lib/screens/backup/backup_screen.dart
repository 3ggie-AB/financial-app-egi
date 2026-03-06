import 'package:flutter/material.dart';
import '../../services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _backup = BackupService.instance;
  bool _isLoading = false;
  String _status = '';

  void _setLoading(bool v, [String status = '']) {
    setState(() { _isLoading = v; _status = status; });
  }

  Future<void> _showConfirm(String title, String body, Future<void> Function() action) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lanjutkan')),
        ],
      ),
    );
    if (confirm == true) await action();
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _backup.isSignedIn;
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Google Drive Section
          _sectionHeader('Google Drive'),
          Card(
            child: Column(
              children: [
                if (isLoggedIn)
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
                    title: Text(_backup.userName ?? 'Google Account'),
                    subtitle: Text(_backup.userEmail ?? ''),
                    trailing: TextButton(
                      onPressed: () async {
                        await _backup.signOutGoogle();
                        setState(() {});
                      },
                      child: const Text('Keluar', style: TextStyle(color: Colors.red)),
                    ),
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.login_rounded, color: Colors.blue),
                    title: const Text('Login dengan Google'),
                    subtitle: const Text('Diperlukan untuk backup ke Drive'),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        final ok = await _backup.signInGoogle();
                        setState(() {});
                        if (!ok && mounted) _showSnack('Login gagal', isError: true);
                      },
                      child: const Text('Login'),
                    ),
                  ),
                if (isLoggedIn) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.backup_rounded, color: Colors.green),
                    title: const Text('Backup ke Google Drive'),
                    subtitle: const Text('Simpan data ke cloud'),
                    trailing: _isLoading
                        ? const CircularProgressIndicator()
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: _isLoading ? null : () async {
                      _setLoading(true, 'Mengupload ke Drive...');
                      final err = await _backup.backupToDrive();
                      _setLoading(false);
                      _showSnack(err ?? '✓ Berhasil backup ke Google Drive', isError: err != null);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restore_rounded, color: Colors.orange),
                    title: const Text('Restore dari Google Drive'),
                    subtitle: const Text('Ambil data dari cloud (akan menimpa data lokal)'),
                    trailing: _isLoading
                        ? const CircularProgressIndicator()
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: _isLoading ? null : () => _showConfirm(
                      'Restore dari Drive?',
                      'Semua data lokal akan digantikan dengan data dari Google Drive.',
                      () async {
                        _setLoading(true, 'Mengunduh dari Drive...');
                        final err = await _backup.restoreFromDrive();
                        _setLoading(false);
                        _showSnack(err ?? '✓ Berhasil restore dari Google Drive', isError: err != null);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Local JSON Section
          _sectionHeader('File JSON Lokal'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download_rounded, color: Colors.blue),
                  title: const Text('Export ke JSON'),
                  subtitle: const Text('Simpan backup ke penyimpanan lokal'),
                  trailing: _isLoading
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: _isLoading ? null : () async {
                    _setLoading(true, 'Mengekspor data...');
                    final path = await _backup.exportToJson();
                    _setLoading(false);
                    if (path != null) {
                      _showSnack('✓ File disimpan di: $path');
                    } else {
                      _showSnack('Gagal export', isError: true);
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.upload_rounded, color: Colors.purple),
                  title: const Text('Import dari JSON'),
                  subtitle: const Text('Pilih file backup JSON (akan menimpa data lokal)'),
                  trailing: _isLoading
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: _isLoading ? null : () => _showConfirm(
                    'Import dari JSON?',
                    'Semua data lokal akan digantikan dengan data dari file JSON.',
                    () async {
                      _setLoading(true, 'Mengimpor data...');
                      final err = await _backup.importFromJson();
                      _setLoading(false);
                      _showSnack(err ?? '✓ Berhasil import data', isError: err != null);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(_status, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),

          // Info Card
          Card(
            color: Colors.blue.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Text('Informasi Backup', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Backup menyimpan semua data: rekening, kategori, tag, dan transaksi\n'
                    '• Restore akan menimpa SEMUA data yang ada\n'
                    '• Disarankan backup secara rutin\n'
                    '• File JSON bisa dibuka dan diedit secara manual',
                    style: TextStyle(fontSize: 12, height: 1.8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
      );
}
