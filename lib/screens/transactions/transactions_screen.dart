import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/finance_provider.dart';
import '../../models/models.dart';
import 'transaction_tile.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionType? _filterType;
  String? _filterAccount;
  String? _filterCategory;
  DateTime _selectedMonth = DateTime.now();
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;

    var txns = fp.transactionsForMonth(_selectedMonth);
    if (_filterType != null) txns = txns.where((t) => t.type == _filterType).toList();
    if (_filterAccount != null) txns = txns.where((t) => t.accountId == _filterAccount).toList();
    if (_filterCategory != null) txns = txns.where((t) => t.categoryId == _filterCategory).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      txns = txns.where((t) {
        final cat = fp.categoryById(t.categoryId);
        return (cat?.name.toLowerCase().contains(q) ?? false) ||
            (t.note?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Group by date
    final Map<String, List<AppTransaction>> grouped = {};
    for (final t in txns) {
      final key = DateFormat('dd MMMM yyyy', 'id_ID').format(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Cari transaksi...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _search = ''))
                    : null,
              ),
            ),
          ),
          // Month selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: () => setState(() => _selectedMonth =
                      DateTime(_selectedMonth.year, _selectedMonth.month - 1)),
                  icon: const Icon(Icons.chevron_left_rounded)),
              Text(
                DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              IconButton(
                  onPressed: () => setState(() => _selectedMonth =
                      DateTime(_selectedMonth.year, _selectedMonth.month + 1)),
                  icon: const Icon(Icons.chevron_right_rounded)),
            ],
          ),
          // Filter chips
          if (_filterType != null || _filterAccount != null || _filterCategory != null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_filterType != null)
                    _chip(_filterType!.name, () => setState(() => _filterType = null)),
                  if (_filterAccount != null)
                    _chip(fp.accountById(_filterAccount!)?.name ?? '', () => setState(() => _filterAccount = null)),
                  if (_filterCategory != null)
                    _chip(fp.categoryById(_filterCategory!)?.name ?? '', () => setState(() => _filterCategory = null)),
                ],
              ),
            ),
          // Transactions list
          Expanded(
            child: grouped.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 64,
                            color: scheme.onSurfaceVariant.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text('Tidak ada transaksi',
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    children: grouped.entries.map((entry) {
                      final dayTotal = entry.value.fold(0.0, (sum, t) {
                        if (t.type == TransactionType.income) return sum + t.amount;
                        if (t.type == TransactionType.expense) return sum - t.amount;
                        return sum;
                      });
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: scheme.onSurfaceVariant)),
                                Text(
                                  '${dayTotal >= 0 ? '+' : ''}${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(dayTotal)}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: dayTotal >= 0 ? Colors.green : Colors.red),
                                ),
                              ],
                            ),
                          ),
                          ...entry.value.map((t) => TransactionTile(
                              transaction: t, showDate: false)),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onRemove,
      ),
    );
  }

  void _showFilterSheet() {
    final fp = context.read<FinanceProvider>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Jenis', style: TextStyle(fontWeight: FontWeight.w500)),
            Wrap(
              spacing: 8,
              children: TransactionType.values.map((t) => FilterChip(
                label: Text(t.name),
                selected: _filterType == t,
                onSelected: (v) {
                  setState(() => _filterType = v ? t : null);
                  Navigator.pop(ctx);
                },
              )).toList(),
            ),
            const SizedBox(height: 12),
            const Text('Rekening', style: TextStyle(fontWeight: FontWeight.w500)),
            Wrap(
              spacing: 8,
              children: fp.accounts.map((a) => FilterChip(
                label: Text(a.name),
                selected: _filterAccount == a.id,
                onSelected: (v) {
                  setState(() => _filterAccount = v ? a.id : null);
                  Navigator.pop(ctx);
                },
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
