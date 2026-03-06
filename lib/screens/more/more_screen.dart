import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../categories/categories_screen.dart';
import '../tags/tags_screen.dart';
import '../backup/backup_screen.dart';
import '../budgets/budgets_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final scheme = Theme.of(context).colorScheme;

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
          _menuItem(context, Icons.backup_rounded, 'Backup & Restore',
              'Google Drive atau file JSON', Colors.green, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen()));
          }),
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
                onChanged: (v) => themeProvider.setTheme(v ? ThemeMode.dark : ThemeMode.light),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
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
