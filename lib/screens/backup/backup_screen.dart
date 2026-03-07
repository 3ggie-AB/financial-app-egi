import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/backup_service.dart';
import '../../providers/finance_provider.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final backup = context.watch<BackupService>();
    final isLoggedIn = backup.isSignedIn;
    final state = backup.syncState;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Sinkronisasi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Google Drive + Auto Sync ─────────────────────────
          _sectionHeader('Google Drive'),
          Card(
            child: Column(
              children: [
                if (isLoggedIn) ...[
                  // User info
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
                    title: Text(backup.userName ?? 'Google Account'),
                    subtitle: Text(backup.userEmail ?? ''),
                    trailing: TextButton(
                      onPressed: () async {
                        await backup.signOutGoogle();
                      },
                      child: const Text('Keluar',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const Divider(height: 1),

                  // Status sync
                  _SyncStatusTile(state: state),
                  const Divider(height: 1),

                  // Auto sync toggle
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.sync_rounded, color: Colors.purple),
                    ),
                    title: const Text('Auto Sync'),
                    subtitle: const Text(
                      'Sinkron otomatis setiap ada perubahan data',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: backup.autoSyncEnabled,
                    onChanged: (v) => backup.setAutoSync(v),
                  ),
                  const Divider(height: 1),

                  // Manual backup
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.backup_rounded, color: Colors.green),
                    ),
                    title: const Text('Backup Sekarang'),
                    subtitle: const Text('Upload data ke Google Drive'),
                    trailing: state.status == SyncStatus.syncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: state.status == SyncStatus.syncing
                        ? null
                        : () async {
                            final err = await backup.backupToDrive();
                            if (context.mounted) {
                              _showSnack(context,
                                  err ?? '✓ Berhasil backup ke Google Drive',
                                  isError: err != null);
                            }
                          },
                  ),
                  const Divider(height: 1),

                  // Restore
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.restore_rounded, color: Colors.orange),
                    ),
                    title: const Text('Restore dari Drive'),
                    subtitle: const Text('Ambil data dari cloud (timpa data lokal)'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _confirmRestore(context, backup),
                  ),
                ] else ...[
                  // Login
                  ListTile(
                    leading: const Icon(Icons.login_rounded, color: Colors.blue),
                    title: const Text('Login dengan Google'),
                    subtitle: const Text(
                        'Diperlukan untuk backup & sinkronisasi otomatis'),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        final ok = await backup.signInGoogle();
                        if (!ok && context.mounted) {
                          _showSnack(context, 'Login gagal', isError: true);
                        }
                      },
                      child: const Text('Login'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Local JSON ───────────────────────────────────────
          _sectionHeader('File JSON Lokal'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.download_rounded, color: Colors.blue),
                  ),
                  title: const Text('Export ke JSON'),
                  subtitle: const Text('Simpan backup ke penyimpanan lokal'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final path = await backup.exportToJson();
                    if (context.mounted) {
                      _showSnack(context,
                          path != null ? '✓ File disimpan di: $path' : 'Gagal export',
                          isError: path == null);
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.upload_rounded, color: Colors.purple),
                  ),
                  title: const Text('Import dari JSON'),
                  subtitle: const Text('Pilih file backup (timpa data lokal)'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _confirmImportJson(context, backup),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Info card
          Card(
            color: Colors.blue.withOpacity(0.06),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Text('Cara Kerja Auto Sync',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Data otomatis di-upload ke Drive milik kamu setiap ada perubahan\n'
                    '• Saat buka app, akan dicek apakah ada data lebih baru di Drive\n'
                    '• Kamu bebas pilih pakai data lokal atau data dari Drive\n'
                    '• Quota Drive yang dipakai adalah milik kamu sendiri (~15GB gratis)\n'
                    '• Developer tidak menyimpan data apapun di server',
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

  Future<void> _confirmRestore(BuildContext context, BackupService backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore dari Drive?'),
        content: const Text('Semua data lokal akan digantikan dengan data dari Google Drive.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lanjutkan')),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final err = await backup.restoreFromDrive();
      if (context.mounted) {
        context.read<FinanceProvider>().loadAll();
        _showSnack(context, err ?? '✓ Berhasil restore dari Google Drive',
            isError: err != null);
      }
    }
  }

  Future<void> _confirmImportJson(
      BuildContext context, BackupService backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import dari JSON?'),
        content: const Text(
            'Semua data lokal akan digantikan dengan data dari file JSON.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lanjutkan')),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final err = await backup.importFromJson();
      if (context.mounted) {
        _showSnack(context, err ?? '✓ Berhasil import data', isError: err != null);
      }
    }
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
      );
}

// ── Tile status sync ─────────────────────────────────────────────────────────
class _SyncStatusTile extends StatelessWidget {
  final SyncState state;
  const _SyncStatusTile({required this.state});

  @override
  Widget build(BuildContext context) {
    final color = _color(state.status);
    final lastSyncText = state.lastSync != null
        ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(state.lastSync!)
        : 'Belum pernah sync';

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: state.status == SyncStatus.syncing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(_icon(state.status), color: color),
      ),
      title: Text(_label(state.status),
          style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      subtitle: Text(lastSyncText, style: const TextStyle(fontSize: 12)),
    );
  }

  Color _color(SyncStatus s) => switch (s) {
        SyncStatus.syncing => Colors.blue,
        SyncStatus.success => Colors.green,
        SyncStatus.error => Colors.red,
        SyncStatus.conflict => Colors.orange,
        SyncStatus.idle => Colors.grey,
      };

  IconData _icon(SyncStatus s) => switch (s) {
        SyncStatus.syncing => Icons.sync_rounded,
        SyncStatus.success => Icons.cloud_done_rounded,
        SyncStatus.error => Icons.cloud_off_rounded,
        SyncStatus.conflict => Icons.warning_amber_rounded,
        SyncStatus.idle => Icons.cloud_queue_rounded,
      };

  String _label(SyncStatus s) => switch (s) {
        SyncStatus.syncing => 'Sedang menyinkron...',
        SyncStatus.success => 'Tersinkron',
        SyncStatus.error => 'Gagal sinkronisasi',
        SyncStatus.conflict => 'Ada konflik data',
        SyncStatus.idle => 'Siap sinkron',
      };
}