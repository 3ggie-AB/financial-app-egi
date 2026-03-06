import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/finance_provider.dart';
import '../../services/database_service.dart';

String _fmt(double v) =>
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBudgetDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: fp.budgets.isEmpty
          ? const Center(child: Text('Belum ada budget'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: fp.budgets.length,
              itemBuilder: (_, i) {
                final b = fp.budgets[i];
                final cat = fp.categoryById(b.categoryId);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(cat?.name ?? 'Budget',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                              onPressed: () async {
                                await fp.deleteBudget(b.id);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_fmt(b.spentAmount)} digunakan',
                                style: const TextStyle(fontSize: 13)),
                            Text('dari ${_fmt(b.limitAmount)}',
                                style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: b.percentage,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(
                                b.isOverBudget ? Colors.red : Colors.green),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (b.isOverBudget)
                          Text('Melebihi budget ${_fmt(b.spentAmount - b.limitAmount)}',
                              style: const TextStyle(color: Colors.red, fontSize: 12))
                        else
                          Text('Sisa ${_fmt(b.remaining)}',
                              style: const TextStyle(color: Colors.green, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('dd MMM', 'id_ID').format(b.startDate)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(b.endDate)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showBudgetDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const BudgetFormSheet(),
    );
  }
}

class BudgetFormSheet extends StatefulWidget {
  const BudgetFormSheet({super.key});

  @override
  State<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<BudgetFormSheet> {
  final _amountCtrl = TextEditingController();
  String? _categoryId;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tambah Budget', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: fp.expenseCategories.map((c) => ChoiceChip(
              label: Text(c.name),
              selected: _categoryId == c.id,
              onSelected: (v) => setState(() => _categoryId = v ? c.id : null),
            )).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Batas Anggaran (Rp)',
              prefixIcon: Icon(Icons.money_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(DateFormat('dd MMM yyyy').format(_startDate), style: const TextStyle(fontSize: 12)),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => _startDate = d);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(DateFormat('dd MMM yyyy').format(_endDate), style: const TextStyle(fontSize: 12)),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => _endDate = d);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tambah Budget', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_categoryId == null || _amountCtrl.text.isEmpty) return;
    final limit = double.tryParse(_amountCtrl.text) ?? 0;
    await context.read<FinanceProvider>().addBudget(Budget(
      id: DatabaseService.instance.newId,
      categoryId: _categoryId!,
      limitAmount: limit,
      startDate: _startDate,
      endDate: _endDate,
    ));
    if (mounted) Navigator.pop(context);
  }
}
