import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/finance_provider.dart';
import '../../services/database_service.dart';

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
                final color = Color(int.parse(
                    'FF${tag.color.replaceAll('#', '')}', radix: 16));
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.2), shape: BoxShape.circle),
                      child: Icon(Icons.label_rounded, color: color, size: 18),
                    ),
                    title: Text(tag.name),
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
      builder: (_) => TagFormSheet(tag: tag),
    );
  }
}

class TagFormSheet extends StatefulWidget {
  final Tag? tag;
  const TagFormSheet({super.key, this.tag});

  @override
  State<TagFormSheet> createState() => _TagFormSheetState();
}

class _TagFormSheetState extends State<TagFormSheet> {
  final _nameCtrl = TextEditingController();
  String _color = '#9C27B0';

  final _colors = ['#F44336', '#E91E63', '#9C27B0', '#3F51B5', '#2196F3',
      '#00BCD4', '#4CAF50', '#FF9800', '#FF5722', '#607D8B'];

  @override
  void initState() {
    super.initState();
    if (widget.tag != null) {
      _nameCtrl.text = widget.tag!.name;
      _color = widget.tag!.color;
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
          Text(widget.tag == null ? 'Tambah Tag' : 'Edit Tag',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nama Tag'),
          ),
          const SizedBox(height: 12),
          const Text('Warna'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _colors.map((c) {
              final col = Color(int.parse('FF${c.replaceAll('#', '')}', radix: 16));
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: col,
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
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(widget.tag == null ? 'Tambah' : 'Simpan',
                  style: const TextStyle(fontSize: 15)),
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
      await fp.updateTag(Tag(id: widget.tag!.id, name: _nameCtrl.text, color: _color));
    }
    if (mounted) Navigator.pop(context);
  }
}
