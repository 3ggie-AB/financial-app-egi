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
      appBar: AppBar(title: const Text('Tag')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTagDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: fp.tags.isEmpty
          ? const Center(child: Text('Belum ada tag'))
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
                      child: Icon(Icons.label_rounded, color: color, size: 18),
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
                            await context.read<FinanceProvider>().deleteTag(tag.id);
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
}

// ─────────────────────────────────────────────────────────────────────────────
// TAG FORM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class TagFormSheet extends StatefulWidget {
  final Tag? tag;
  const TagFormSheet({super.key, this.tag});

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
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.tag == null ? 'Tambah Tag' : 'Edit Tag',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Preview chip
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorFromHex(_color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorFromHex(_color), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.label_rounded, color: colorFromHex(_color), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _nameCtrl.text.isEmpty ? 'Preview' : _nameCtrl.text,
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

          // Nama tag
          TextField(
            controller: _nameCtrl,
            onChanged: (_) => setState(() {}), // update preview
            decoration: const InputDecoration(
              labelText: 'Nama Tag',
              prefixIcon: Icon(Icons.label_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Color picker custom
          const Text('Warna', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          ColorPickerWidget(
            selectedColor: _color,
            onColorChanged: (c) => setState(() => _color = c),
          ),
          const SizedBox(height: 20),

          // Tombol simpan
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorFromHex(_color),
                foregroundColor: colorFromHex(_color).computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                widget.tag == null ? 'Tambah Tag' : 'Simpan',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    final fp = context.read<FinanceProvider>();
    if (widget.tag == null) {
      await fp.addTag(Tag(
        id: DatabaseService.instance.newId,
        name: _nameCtrl.text,
        color: _color,
      ));
    } else {
      await fp.updateTag(Tag(
        id: widget.tag!.id,
        name: _nameCtrl.text,
        color: _color,
      ));
    }
    if (mounted) Navigator.pop(context);
  }
}