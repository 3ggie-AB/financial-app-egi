import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/finance_provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

class AddTransactionScreen extends StatefulWidget {
  final AppTransaction? transaction;
  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  TransactionType _type = TransactionType.expense;
  String? _accountId;
  String? _toAccountId;
  String? _categoryId;
  List<String> _tagIds = [];
  DateTime _date = DateTime.now();
  bool _isLoading = false;

  bool get _isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _type = TransactionType.values[_tabController.index];
        _categoryId = null;
      });
    });
    if (_isEdit) {
      final t = widget.transaction!;
      _type = t.type;
      _tabController.index = t.type.index;
      _amountCtrl.text = t.amount.toStringAsFixed(0);
      _noteCtrl.text = t.note ?? '';
      _accountId = t.accountId;
      _toAccountId = t.toAccountId;
      _categoryId = t.categoryId;
      _tagIds = List.from(t.tagIds);
      _date = t.date;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_amountCtrl.text.isEmpty) {
      _showError('Masukkan jumlah');
      return;
    }
    if (_accountId == null) {
      _showError('Pilih rekening');
      return;
    }
    if (_type != TransactionType.transfer && _categoryId == null) {
      _showError('Pilih kategori');
      return;
    }
    if (_type == TransactionType.transfer && _toAccountId == null) {
      _showError('Pilih rekening tujuan');
      return;
    }

    setState(() => _isLoading = true);
    final fp = context.read<FinanceProvider>();
    final amount = double.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? 0;

    // For transfer, use a dummy category id
    final categoryId = _type == TransactionType.transfer
        ? 'transfer'
        : _categoryId!;

    final newT = AppTransaction(
      id: _isEdit ? widget.transaction!.id : DatabaseService.instance.newId,
      type: _type,
      amount: amount,
      accountId: _accountId!,
      toAccountId: _toAccountId,
      categoryId: categoryId,
      tagIds: _tagIds,
      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
      date: _date,
      createdAt: _isEdit ? widget.transaction!.createdAt : DateTime.now(),
    );

    if (_isEdit) {
      await fp.updateTransaction(widget.transaction!, newT);
    } else {
      await fp.addTransaction(newT);
    }

    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text('Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<FinanceProvider>().deleteTransaction(widget.transaction!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;

    final tabColors = [AppTheme.expenseColor, AppTheme.incomeColor, AppTheme.transferColor];
    final currentColor = tabColors[_tabController.index];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: _delete,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: currentColor,
          labelColor: currentColor,
          tabs: const [
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Pemasukan'),
            Tab(text: 'Transfer'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Amount
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jumlah', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Rp ', style: TextStyle(fontSize: 20, color: currentColor, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: TextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: currentColor),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            filled: false,
                            hintText: '0',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Account
          _sectionLabel('Rekening'),
          _accountSelector(fp, false),
          const SizedBox(height: 12),

          // To Account (transfer only)
          if (_type == TransactionType.transfer) ...[
            _sectionLabel('Rekening Tujuan'),
            _accountSelector(fp, true),
            const SizedBox(height: 12),
          ],

          // AppCategory (not for transfer)
          if (_type != TransactionType.transfer) ...[
            _sectionLabel('Kategori'),
            _categorySelector(fp),
            const SizedBox(height: 12),
          ],

          // Tags
          _sectionLabel('Tag'),
          _tagSelector(fp),
          const SizedBox(height: 12),

          // Date
          _sectionLabel('Tanggal'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today_rounded),
              title: Text(DateFormat('dd MMMM yyyy', 'id_ID').format(_date)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
          ),
          const SizedBox(height: 12),

          // Note
          _sectionLabel('Catatan (opsional)'),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Tambahkan catatan...',
              prefixIcon: Icon(Icons.note_rounded),
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: currentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Transaksi',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      );

  Widget _accountSelector(FinanceProvider fp, bool isTo) {
    final selected = isTo ? _toAccountId : _accountId;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: fp.accounts.map((a) {
        final isSelected = selected == a.id;
        return ChoiceChip(
          label: Text(a.name),
          selected: isSelected,
          onSelected: (v) => setState(() {
            if (isTo) {
              _toAccountId = v ? a.id : null;
            } else {
              _accountId = v ? a.id : null;
            }
          }),
        );
      }).toList(),
    );
  }

  Widget _categorySelector(FinanceProvider fp) {
    final cats = _type == TransactionType.income ? fp.incomeCategories : fp.expenseCategories;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cats.map<Widget>((c) {
        final isSelected = _categoryId == c.id;
        return ChoiceChip(
          label: Text(c.name),
          selected: isSelected,
          onSelected: (v) => setState(() => _categoryId = v ? c.id : null),
        );
      }).toList(),
    );
  }

  Widget _tagSelector(FinanceProvider fp) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: fp.tags.map((t) {
        final isSelected = _tagIds.contains(t.id);
        return FilterChip(
          label: Text(t.name),
          selected: isSelected,
          onSelected: (v) => setState(() {
            if (v) {
              _tagIds.add(t.id);
            } else {
              _tagIds.remove(t.id);
            }
          }),
        );
      }).toList(),
    );
  }
}
