import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../services/security_service.dart';
import '../categories/categories_screen.dart';
import '../tags/tags_screen.dart';
import '../backup/backup_screen.dart';
import '../budgets/budgets_screen.dart';
import '../notifications/notification_settings_screen.dart';
import '../security/security_settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final security = context.watch<SecurityService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Lainnya')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Kelola'),
          _menuItem(context, Icons.category_rounded, 'Kategori',
              'Kelola kategori transaksi', Colors.blue, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen()));
          }),
          _menuItem(context, Icons.label_rounded, 'Tag',
              'Kelola tag transaksi', Colors.purple, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TagsScreen()));
          }),
          _menuItem(context, Icons.account_balance_wallet_rounded, 'Budget',
              'Atur batas pengeluaran', Colors.orange, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsScreen()));
          }),
          const SizedBox(height: 16),

          _sectionHeader('Data & Backup'),
          _menuItem(context, Icons.backup_rounded, 'Backup & Sinkronisasi',
              'Google Drive · Auto Sync', Colors.green, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen()));
          }),
          const SizedBox(height: 16),

          _sectionHeader('Notifikasi'),
          _menuItem(context, Icons.notifications_rounded, 'Pengaturan Notifikasi',
              'Budget warning · Ringkasan · Pengingat harian', Colors.deepPurple, () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()));
          }),
          const SizedBox(height: 16),

          _sectionHeader('Keamanan'),
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (security.lockEnabled ? Colors.green : Colors.grey).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  security.lockEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                  color: security.lockEnabled ? Colors.green : Colors.grey,
                ),
              ),
              title: const Text('PIN & Biometrik',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(
                security.lockEnabled
                    ? 'Aktif · ${security.bioEnabled ? "Fingerprint ON" : "Fingerprint OFF"}'
                    : 'Tidak aktif · Ketuk untuk mengaktifkan',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (security.lockEnabled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('ON',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SecuritySettingsScreen())),
            ),
          ),
          const SizedBox(height: 16),

          _sectionHeader('Tampilan'),
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.dark_mode_rounded, color: Colors.indigo),
              ),
              title: const Text('Tema Gelap'),
              trailing: Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (v) =>
                    themeProvider.setTheme(v ? ThemeMode.dark : ThemeMode.light),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _sectionHeader('Zona Bahaya'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.red.withOpacity(0.4), width: 1.2),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_forever_rounded, color: Colors.red),
              ),
              title: const Text('Hapus Semua Data',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Hapus seluruh transaksi, rekening, kategori & tag',
                  style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.red),
              onTap: () => _showDeleteWarning1(context),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showDeleteWarning1(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
        title: const Text('Hapus Semua Data?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Tindakan ini akan menghapus SEMUA data termasuk:\n\n'
          '• Seluruh transaksi\n• Semua rekening\n• Semua kategori\n'
          '• Semua tag\n• Semua budget\n\n'
          'Data yang dihapus tidak dapat dikembalikan.',
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () { Navigator.pop(ctx); _showDeleteWarning2(context); },
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteWarning2(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 52),
            title: const Text('Yakin Ingin Menghapus?',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Expanded(child: Text(
                      'Ini adalah konfirmasi terakhir.\nSemua data akan PERMANEN terhapus!',
                      style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                    )),
                  ]),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pastikan Anda sudah melakukan backup sebelum melanjutkan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                child: const Text('Tidak, Batalkan', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isDeleting ? null : () async {
                  setState(() => isDeleting = true);
                  await context.read<FinanceProvider>().deleteAllData();
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Row(children: [
                        Icon(Icons.check_circle_outline, color: Colors.white),
                        SizedBox(width: 10),
                        Text('Semua data berhasil dihapus'),
                      ]),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
                child: isDeleting
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Ya, Hapus Semua', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
      );

  Widget _menuItem(BuildContext context, IconData icon, String title,
      String subtitle, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}