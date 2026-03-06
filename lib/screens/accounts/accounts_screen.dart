import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/finance_provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

String _fmt(double v) =>
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Rekening')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAccountDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: fp.accounts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_rounded,
                      size: 64, color: scheme.onSurfaceVariant.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  const Text('Belum ada rekening'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                // Total Balance Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.primary.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Saldo',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(_fmt(fp.totalBalance),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Account List
                ...fp.accounts.map((a) => _accountCard(context, a, fp)),
              ],
            ),
    );
  }

  Widget _accountCard(BuildContext context, Account account, FinanceProvider fp) {
    final color = _hexColor(account.color);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_accountIcon(account.type), color: color),
        ),
        title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(_accountTypeLabel(account.type),
            style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_fmt(account.balance),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: account.balance >= 0 ? Colors.green : Colors.red,
                    fontSize: 15)),
            Text(account.currency, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        onTap: () => _showAccountDialog(context, account: account),
      ),
    );
  }

  String _accountTypeLabel(String type) => switch (type) {
        'cash' => 'Tunai',
        'bank' => 'Bank',
        'credit' => 'Kartu Kredit',
        'ewallet' => 'E-Wallet',
        'investment' => 'Investasi',
        _ => type,
      };

  IconData _accountIcon(String type) => switch (type) {
        'cash' => Icons.account_balance_wallet_rounded,
        'bank' => Icons.account_balance_rounded,
        'credit' => Icons.credit_card_rounded,
        'ewallet' => Icons.phone_android_rounded,
        'investment' => Icons.trending_up_rounded,
        _ => Icons.wallet_rounded,
      };

  Color _hexColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  void _showAccountDialog(BuildContext context, {Account? account}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AccountFormSheet(account: account),
    );
  }
}

class AccountFormSheet extends StatefulWidget {
  final Account? account;
  const AccountFormSheet({super.key, this.account});

  @override
  State<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<AccountFormSheet> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  String _type = 'cash';
  String _color = '#4CAF50';
  bool _isLoading = false;

  final _types = ['cash', 'bank', 'credit', 'ewallet', 'investment'];
  final _colors = ['#4CAF50', '#2196F3', '#F44336', '#FF9800', '#9C27B0', '#00BCD4', '#795548', '#607D8B'];

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameCtrl.text = widget.account!.name;
      _balanceCtrl.text = widget.account!.balance.toStringAsFixed(0);
      _type = widget.account!.type;
      _color = widget.account!.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.account == null ? 'Tambah Rekening' : 'Edit Rekening',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (widget.account != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: _delete,
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nama Rekening', prefixIcon: Icon(Icons.label_rounded)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _balanceCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Saldo Awal', prefixIcon: Icon(Icons.money_rounded)),
          ),
          const SizedBox(height: 12),
          const Text('Jenis', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _types.map((t) => ChoiceChip(
              label: Text(_typeLabel(t)),
              selected: _type == t,
              onSelected: (v) => setState(() { if (v) _type = t; }),
            )).toList(),
          ),
          const SizedBox(height: 12),
          const Text('Warna', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _colors.map((c) {
              final color = Color(int.parse('FF${c.replaceAll('#', '')}', radix: 16));
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: _color == c ? Border.all(color: Colors.black, width: 2) : null,
                  ),
                  child: _color == c ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text(widget.account == null ? 'Tambah' : 'Simpan',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(String t) => switch (t) {
        'cash' => 'Tunai',
        'bank' => 'Bank',
        'credit' => 'Kredit',
        'ewallet' => 'E-Wallet',
        'investment' => 'Investasi',
        _ => t,
      };

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    final fp = context.read<FinanceProvider>();
    final balance = double.tryParse(_balanceCtrl.text) ?? 0;

    if (widget.account == null) {
      await fp.addAccount(Account(
        id: DatabaseService.instance.newId,
        name: _nameCtrl.text,
        type: _type,
        balance: balance,
        color: _color,
        createdAt: DateTime.now(),
      ));
    } else {
      await fp.updateAccount(widget.account!.copyWith(
        name: _nameCtrl.text,
        type: _type,
        balance: balance,
        color: _color,
      ));
    }

    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Rekening?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<FinanceProvider>().deleteAccount(widget.account!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}
