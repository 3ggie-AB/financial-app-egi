import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/finance_provider.dart';
import '../../services/database_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Pengeluaran'), Tab(text: 'Pemasukan')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _catList(fp.expenseCategories),
          _catList(fp.incomeCategories),
        ],
      ),
    );
  }

  Widget _catList(List<AppCategory> cats) {
    if (cats.isEmpty) {
      return const Center(child: Text('Belum ada kategori'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cats.length,
      itemBuilder: (_, i) {
        final cat = cats[i];
        final color = _hexColor(cat.color);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.category_rounded, color: color),
            ),
            title: Text(cat.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  onPressed: () => _showCategoryDialog(context, cat: cat),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                  onPressed: () => _delete(cat),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _hexColor(String hex) {
    try { return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16)); }
    catch (_) { return Colors.blue; }
  }

  void _showCategoryDialog(BuildContext context, {AppCategory? cat}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryFormSheet(category: cat),
    );
  }

  Future<void> _delete(AppCategory cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus "${cat.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<FinanceProvider>().deleteCategory(cat.id);
    }
  }
}

class CategoryFormSheet extends StatefulWidget {
  final AppCategory? category;
  const CategoryFormSheet({super.key, this.category});

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _nameCtrl = TextEditingController();
  TransactionType _type = TransactionType.expense;
  String _color = '#2196F3';

  final _colors = ['#F44336', '#E91E63', '#9C27B0', '#3F51B5', '#2196F3',
      '#00BCD4', '#009688', '#4CAF50', '#8BC34A', '#CDDC39',
      '#FFEB3B', '#FF9800', '#FF5722', '#795548', '#607D8B'];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameCtrl.text = widget.category!.name;
      _type = widget.category!.type;
      _color = widget.category!.color;
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
          Text(widget.category == null ? 'Tambah Kategori' : 'Edit Kategori',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nama Kategori'),
          ),
          const SizedBox(height: 12),
          const Text('Jenis', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Pengeluaran'),
                selected: _type == TransactionType.expense,
                onSelected: (v) { if (v) setState(() => _type = TransactionType.expense); },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Pemasukan'),
                selected: _type == TransactionType.income,
                onSelected: (v) { if (v) setState(() => _type = TransactionType.income); },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Warna', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colors.map<Widget>((c) {
              final color = Color(int.parse('FF${c.replaceAll('#', '')}', radix: 16));
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: _color == c ? Border.all(color: Colors.black, width: 2) : null,
                  ),
                  child: _color == c ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(widget.category == null ? 'Tambah' : 'Simpan',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    final fp = context.read<FinanceProvider>();
    if (widget.category == null) {
      await fp.addCategory(AppCategory(
        id: DatabaseService.instance.newId,
        name: _nameCtrl.text,
        type: _type,
        color: _color,
      ));
    } else {
      widget.category!.name = _nameCtrl.text;
      widget.category!.type = _type;
      widget.category!.color = _color;
      await fp.updateCategory(widget.category!);
    }
    if (mounted) Navigator.pop(context);
  }
}
