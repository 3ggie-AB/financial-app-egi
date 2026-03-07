// screens/tags/tags_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/finance_provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/color_picker_widget.dart';

class TagsScreen extends StatelessWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tag'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_rounded),
            tooltip: 'Tambah Banyak Sekaligus',
            onPressed: () => _showBulkAddSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'tags_fab',
        onPressed: () => _showTagDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: fp.tags.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.label_outline_rounded,
                      size: 56,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.3)),
                  const SizedBox(height: 12),
                  const Text('Belum ada tag'),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tambah Tag'),
                    onPressed: () => _showTagDialog(context),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: fp.tags.length,
              itemBuilder: (_, i) {
                final tag = fp.tags[i];
                final color = colorFromHex(tag.color);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child:
                          Icon(Icons.label_rounded, color: color, size: 18),
                    ),
                    title: Text(tag.name),
                    subtitle: Text(
                      tag.color.toUpperCase(),
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
                          onPressed: () => _showTagDialog(context, tag: tag),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: Colors.red),
                          onPressed: () async {
                            await context
                                .read<FinanceProvider>()
                                .deleteTag(tag.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showTagDialog(BuildContext context, {Tag? tag}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TagFormSheet(tag: tag),
    );
  }

  void _showBulkAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const BulkTagSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BULK TAG SHEET
// ─────────────────────────────────────────────────────────────────────────────
class BulkTagSheet extends StatefulWidget {
  const BulkTagSheet({super.key});

  @override
  State<BulkTagSheet> createState() => _BulkTagSheetState();
}

class _BulkTagSheetState extends State<BulkTagSheet> {
  bool _isSaving = false;

  final List<Map<String, dynamic>> _entries = [
    {'name': '', 'color': '#9C27B0'},
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
    final valid =
        _entries.where((e) => (e['name'] as String).trim().isNotEmpty).toList();
    if (valid.isEmpty) return;

    setState(() => _isSaving = true);
    final fp = context.read<FinanceProvider>();

    for (final e in valid) {
      await fp.addTag(Tag(
        id: DatabaseService.instance.newId,
        name: (e['name'] as String).trim(),
        color: e['color'] as String,
      ));
    }

    setState(() => _isSaving = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ ${valid.length} tag berhasil ditambahkan'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Text('Tambah Banyak Tag',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                            child: const Icon(Icons.label_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Nama tag ${i + 1}...',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            onChanged: (v) => _entries[i]['name'] = v,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle_outline_rounded,
                            color: _entries.length > 1
                                ? Colors.red
                                : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => _removeEntry(i),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
                          'Simpan ${_entries.where((e) => (e['name'] as String).trim().isNotEmpty).length} Tag',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
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
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colors.map((hex) {
                final isSelected = _entries[index]['color'] == hex;
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
                              color:
                                  Theme.of(context).colorScheme.onSurface,
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
// TAG FORM SHEET — tambah / edit 1 tag
// ─────────────────────────────────────────────────────────────────────────────
class TagFormSheet extends StatefulWidget {
  final Tag? tag;
  final Function(Tag)? onAdded; // callback setelah tambah dari transaksi

  const TagFormSheet({super.key, this.tag, this.onAdded});

  @override
  State<TagFormSheet> createState() => _TagFormSheetState();
}

class _TagFormSheetState extends State<TagFormSheet> {
  final _nameCtrl = TextEditingController();
  String _color = '#9C27B0';

  @override
  void initState() {
    super.initState();
    if (widget.tag != null) {
      _nameCtrl.text = widget.tag!.name;
      _color = widget.tag!.color;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.tag == null ? 'Tambah Tag' : 'Edit Tag',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorFromHex(_color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: colorFromHex(_color), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.label_rounded,
                        color: colorFromHex(_color), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _nameCtrl.text.isEmpty
                          ? 'Preview'
                          : _nameCtrl.text,
                      style: TextStyle(
                        color: colorFromHex(_color),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Nama Tag',
              prefixIcon: Icon(Icons.label_outlined),
            ),
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
                backgroundColor: colorFromHex(_color),
                foregroundColor:
                    colorFromHex(_color).computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                widget.tag == null ? 'Tambah Tag' : 'Simpan',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final fp = context.read<FinanceProvider>();
    if (widget.tag == null) {
      final newTag = Tag(
        id: DatabaseService.instance.newId,
        name: _nameCtrl.text.trim(),
        color: _color,
      );
      await fp.addTag(newTag);
      widget.onAdded?.call(newTag);
    } else {
      await fp.updateTag(Tag(
        id: widget.tag!.id,
        name: _nameCtrl.text.trim(),
        color: _color,
      ));
    }
    if (mounted) Navigator.pop(context);
  }
}