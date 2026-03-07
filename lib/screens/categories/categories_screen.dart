// screens/categories/categories_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/finance_provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/color_picker_widget.dart';

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
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        actions: [
          // Tombol tambah banyak sekaligus
          IconButton(
            icon: const Icon(Icons.playlist_add_rounded),
            tooltip: 'Tambah Banyak Sekaligus',
            onPressed: () => _showBulkAddSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'categories_fab',
        onPressed: () => _showCategoryDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _catList(fp.expenseCategories, context),
          _catList(fp.incomeCategories, context),
        ],
      ),
    );
  }

  Widget _catList(List<AppCategory> cats, BuildContext context) {
    if (cats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined,
                size: 56,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.3)),
            const SizedBox(height: 12),
            const Text('Belum ada kategori'),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Kategori'),
              onPressed: () => _showCategoryDialog(context),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cats.length,
      itemBuilder: (_, i) {
        final cat = cats[i];
        final color = colorFromHex(cat.color);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.category_rounded, color: color),
            ),
            title: Text(cat.name),
            subtitle: Text(
              cat.color.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  onPressed: () => _showCategoryDialog(context, cat: cat),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.red),
                  onPressed: () => _delete(context, cat),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCategoryDialog(BuildContext context, {AppCategory? cat}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CategoryFormSheet(category: cat),
    );
  }

  // ── Tambah banyak sekaligus ──────────────────────────────────
  void _showBulkAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const BulkCategorySheet(),
    );
  }

  Future<void> _delete(BuildContext context, AppCategory cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus "${cat.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<FinanceProvider>().deleteCategory(cat.id);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BULK ADD SHEET — tambah banyak kategori sekaligus
// ─────────────────────────────────────────────────────────────────────────────
class BulkCategorySheet extends StatefulWidget {
  const BulkCategorySheet({super.key});

  @override
  State<BulkCategorySheet> createState() => _BulkCategorySheetState();
}

class _BulkCategorySheetState extends State<BulkCategorySheet> {
  TransactionType _type = TransactionType.expense;
  bool _isSaving = false;

  // List entri: {name, color}
  final List<Map<String, dynamic>> _entries = [
    {'name': '', 'color': '#F44336'},
  ];

  final _colors = [
    '#F44336', '#E91E63', '#9C27B0', '#3F51B5', '#2196F3',
    '#00BCD4', '#009688', '#4CAF50', '#8BC34A', '#FFEB3B',
    '#FF9800', '#FF5722', '#795548', '#607D8B', '#6C63FF',
  ];

  void _addEntry() {
    setState(() {
      final nextColor = _colors[_entries.length % _colors.length];
      _entries.add({'name': '', 'color': nextColor});
    });
  }

  void _removeEntry(int i) {
    if (_entries.length <= 1) return;
    setState(() => _entries.removeAt(i));
  }

  Future<void> _saveAll() async {
    final valid = _entries.where((e) => (e['name'] as String).trim().isNotEmpty).toList();
    if (valid.isEmpty) return;

    setState(() => _isSaving = true);
    final fp = context.read<FinanceProvider>();

    for (final e in valid) {
      await fp.addCategory(AppCategory(
        id: DatabaseService.instance.newId,
        name: (e['name'] as String).trim(),
        type: _type,
        color: e['color'] as String,
      ));
    }

    setState(() => _isSaving = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ ${valid.length} kategori berhasil ditambahkan'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Text('Tambah Banyak Kategori',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          // Jenis
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Pengeluaran'),
                  selected: _type == TransactionType.expense,
                  selectedColor: Colors.red.withOpacity(0.2),
                  onSelected: (v) {
                    if (v) setState(() => _type = TransactionType.expense);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Pemasukan'),
                  selected: _type == TransactionType.income,
                  selectedColor: Colors.green.withOpacity(0.2),
                  onSelected: (v) {
                    if (v) setState(() => _type = TransactionType.income);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List entri
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _entries.length + 1,
              itemBuilder: (_, i) {
                if (i == _entries.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 80),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tambah Baris'),
                      onPressed: _addEntry,
                    ),
                  );
                }
                final entry = _entries[i];
                final color = colorFromHex(entry['color'] as String);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Color picker circle
                        GestureDetector(
                          onTap: () => _pickColor(i),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.3)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Nama input
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Nama kategori ${i + 1}...',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            onChanged: (v) => _entries[i]['name'] = v,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Hapus baris
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline_rounded,
                              color: _entries.length > 1
                                  ? Colors.red
                                  : Colors.grey,
                              size: 20),
                          onPressed: () => _removeEntry(i),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Tombol simpan
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                top: 8,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          'Simpan ${_entries.where((e) => (e['name'] as String).trim().isNotEmpty).length} Kategori',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pickColor(int index) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Warna',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colors.map((hex) {
                final isSelected =
                    _entries[index]['color'] == hex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _entries[index]['color'] = hex);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: isSelected ? 40 : 36,
                    height: isSelected ? 40 : 36,
                    decoration: BoxDecoration(
                      color: colorFromHex(hex),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY FORM SHEET — tambah / edit 1 kategori
// ─────────────────────────────────────────────────────────────────────────────
class CategoryFormSheet extends StatefulWidget {
  final AppCategory? category;
  final TransactionType? initialType; // untuk pre-fill dari transaksi
  final Function(AppCategory)? onAdded; // callback setelah tambah

  const CategoryFormSheet({
    super.key,
    this.category,
    this.initialType,
    this.onAdded,
  });

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _nameCtrl = TextEditingController();
  TransactionType _type = TransactionType.expense;
  String _color = '#2196F3';

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameCtrl.text = widget.category!.name;
      _type = widget.category!.type;
      _color = widget.category!.color;
    } else if (widget.initialType != null) {
      _type = widget.initialType!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(_color);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.category == null ? 'Tambah Kategori' : 'Edit Kategori',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.category_rounded, color: color),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Nama Kategori',
                prefixIcon: Icon(Icons.category_outlined),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Jenis', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Pengeluaran'),
                  selected: _type == TransactionType.expense,
                  selectedColor: Colors.red.withOpacity(0.2),
                  onSelected: (v) {
                    if (v) setState(() => _type = TransactionType.expense);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Pemasukan'),
                  selected: _type == TransactionType.income,
                  selectedColor: Colors.green.withOpacity(0.2),
                  onSelected: (v) {
                    if (v) setState(() => _type = TransactionType.income);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Warna', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            ColorPickerWidget(
              selectedColor: _color,
              onColorChanged: (c) => setState(() => _color = c),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  widget.category == null ? 'Tambah' : 'Simpan',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final fp = context.read<FinanceProvider>();
    if (widget.category == null) {
      final newCat = AppCategory(
        id: DatabaseService.instance.newId,
        name: _nameCtrl.text.trim(),
        type: _type,
        color: _color,
      );
      await fp.addCategory(newCat);
      widget.onAdded?.call(newCat);
    } else {
      widget.category!.name = _nameCtrl.text.trim();
      widget.category!.type = _type;
      widget.category!.color = _color;
      await fp.updateCategory(widget.category!);
    }
    if (mounted) Navigator.pop(context);
  }
}