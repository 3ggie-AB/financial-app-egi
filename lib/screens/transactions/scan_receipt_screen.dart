// lib/screens/transactions/scan_receipt_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/receipt_service.dart';
import '../../providers/finance_provider.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  File? _imageFile;
  ReceiptResult? _result;
  bool _isProcessing = false;
  bool _isSaving = false;

  // Form controllers (auto-filled dari scan)
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _accountId;
  String? _categoryId;
  DateTime _date = DateTime.now();
  TransactionType _type = TransactionType.expense;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── AMBIL FOTO ─────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1800,
    );
    if (picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
      _result = null;
      _isProcessing = true;
    });

    await _processImage();
  }

  Future<void> _processImage() async {
    if (_imageFile == null) return;

    final result = await ReceiptService.instance.processImage(_imageFile!);

    setState(() {
      _result = result;
      _isProcessing = false;

      // Auto-fill form
      if (result.totalAmount != null) {
        _amountCtrl.text = result.totalAmount!.toStringAsFixed(0);
      }
      if (result.merchantName != null && result.merchantName!.isNotEmpty) {
        _noteCtrl.text = result.merchantName!;
      }
      if (result.date != null) {
        _date = result.date!;
      }
    });

    // Auto-select kategori yang sesuai
    if (result.suggestedCategory != null && mounted) {
      final fp = context.read<FinanceProvider>();
      final matchCat = fp.expenseCategories.firstWhere(
        (c) => c.name.toLowerCase().contains(
            result.suggestedCategory!.toLowerCase().split(' ').first.toLowerCase()),
        orElse: () => fp.expenseCategories.last,
      );
      setState(() => _categoryId = matchCat.id);
    }
  }

  // ── SAVE TRANSAKSI ─────────────────────────────────────────────
  Future<void> _save() async {
    if (_amountCtrl.text.isEmpty) {
      _showSnack('Masukkan jumlah terlebih dahulu');
      return;
    }
    if (_accountId == null) {
      _showSnack('Pilih rekening terlebih dahulu');
      return;
    }
    if (_categoryId == null) {
      _showSnack('Pilih kategori terlebih dahulu');
      return;
    }

    setState(() => _isSaving = true);

    final fp = context.read<FinanceProvider>();
    final amount = double.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? 0;

    await fp.addTransaction(AppTransaction(
      id: DatabaseService.instance.newId,
      type: _type,
      amount: amount,
      accountId: _accountId!,
      categoryId: _categoryId!,
      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
      date: _date,
      createdAt: DateTime.now(),
    ));

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 10),
            Text('Transaksi berhasil disimpan dari nota!'),
          ]),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fp = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Nota'),
        actions: [
          if (_result != null)
            TextButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: const Text('Simpan'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── AREA FOTO ───────────────────────────────────────
            _buildImageArea(),
            const SizedBox(height: 16),

            // ── TOMBOL PILIH SUMBER ─────────────────────────────
            if (_imageFile == null) _buildPickButtons(),

            // ── LOADING ─────────────────────────────────────────
            if (_isProcessing) _buildProcessing(),

            // ── HASIL + FORM ────────────────────────────────────
            if (_result != null && !_isProcessing) ...[
              _buildScanResult(),
              const SizedBox(height: 16),
              _buildForm(fp, scheme),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),

      // FAB kalau sudah ada gambar tapi belum proses
      floatingActionButton: _imageFile != null && _result == null && !_isProcessing
          ? FloatingActionButton.extended(
              onPressed: _processImage,
              icon: const Icon(Icons.document_scanner_rounded),
              label: const Text('Scan Ulang'),
            )
          : null,
    );
  }

  Widget _buildImageArea() {
    if (_imageFile == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_rounded, size: 56, color: Colors.grey),
              SizedBox(height: 8),
              Text('Foto nota belum dipilih',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            _imageFile!,
            width: double.infinity,
            height: 280,
            fit: BoxFit.cover,
          ),
        ),
        // Overlay kalau processing
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        // Tombol ganti foto
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _showPickerOptions(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Ganti', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Kamera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Galeri'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessing() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 2.5),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Memproses nota...',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text('Membaca teks & mendeteksi total',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanResult() {
    final r = _result!;
    final hasData = r.totalAmount != null || r.merchantName != null || r.date != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 8),
                const Text('Hasil Scan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                if (hasData)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.green, size: 13),
                        SizedBox(width: 4),
                        Text('Terdeteksi', style: TextStyle(color: Colors.green, fontSize: 11)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (r.merchantName != null)
              _resultRow(Icons.store_rounded, 'Merchant', r.merchantName!),
            if (r.totalAmount != null)
              _resultRow(Icons.payments_rounded, 'Total',
                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                      .format(r.totalAmount)),
            if (r.date != null)
              _resultRow(Icons.calendar_today_rounded, 'Tanggal',
                  DateFormat('dd MMMM yyyy', 'id_ID').format(r.date!)),
            if (r.suggestedCategory != null)
              _resultRow(Icons.category_rounded, 'Kategori Saran', r.suggestedCategory!),

            if (!hasData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Teks tidak terdeteksi dengan baik. Coba foto ulang dengan pencahayaan lebih terang.',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Item list
            if (r.items.isNotEmpty) ...[
              const Divider(height: 16),
              Text('${r.items.length} item terdeteksi',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              ...r.items.take(5).map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.fiber_manual_record_rounded,
                            size: 8, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.qty != null ? '${item.qty}x ${item.name}' : item.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        if (item.price != null)
                          Text(
                            NumberFormat.currency(
                                    locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                                .format(item.price),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  )),
              if (r.items.length > 5)
                Text('+${r.items.length - 5} item lainnya',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(FinanceProvider fp, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Konfirmasi Transaksi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // Jenis transaksi
        Row(
          children: [
            ChoiceChip(
              label: const Text('Pengeluaran'),
              selected: _type == TransactionType.expense,
              selectedColor: AppTheme.expenseColor.withOpacity(0.2),
              onSelected: (v) {
                if (v) setState(() { _type = TransactionType.expense; _categoryId = null; });
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Pemasukan'),
              selected: _type == TransactionType.income,
              selectedColor: AppTheme.incomeColor.withOpacity(0.2),
              onSelected: (v) {
                if (v) setState(() { _type = TransactionType.income; _categoryId = null; });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Jumlah
        TextField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Jumlah (Rp)',
            prefixIcon: Icon(Icons.payments_rounded),
          ),
        ),
        const SizedBox(height: 12),

        // Catatan / Merchant
        TextField(
          controller: _noteCtrl,
          decoration: const InputDecoration(
            labelText: 'Catatan / Nama Merchant',
            prefixIcon: Icon(Icons.note_rounded),
          ),
        ),
        const SizedBox(height: 12),

        // Tanggal
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today_rounded),
            title: Text(DateFormat('dd MMMM yyyy', 'id_ID').format(_date)),
            trailing: const Icon(Icons.edit_rounded, size: 18),
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

        // Rekening
        const Text('Rekening',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: fp.accounts.map((a) => ChoiceChip(
            label: Text(a.name),
            selected: _accountId == a.id,
            onSelected: (v) => setState(() => _accountId = v ? a.id : null),
          )).toList(),
        ),
        const SizedBox(height: 12),

        // Kategori
        const Text('Kategori',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (_type == TransactionType.expense
                  ? fp.expenseCategories
                  : fp.incomeCategories)
              .map((c) => ChoiceChip(
                    label: Text(c.name),
                    selected: _categoryId == c.id,
                    onSelected: (v) =>
                        setState(() => _categoryId = v ? c.id : null),
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),

        // Tombol simpan
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded),
            label: Text(
              _isSaving ? 'Menyimpan...' : 'Simpan Transaksi',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}