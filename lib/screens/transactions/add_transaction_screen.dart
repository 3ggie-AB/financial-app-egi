import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/finance_provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import 'scan_receipt_screen.dart';
import '../categories/categories_screen.dart';
import '../tags/tags_screen.dart';

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

  // State utama — ini sumber kebenaran, bukan _tabController.index
  TransactionType _type = TransactionType.expense;
  String? _accountId;
  String? _toAccountId;
  String? _categoryId;
  List<String> _tagIds = [];
  DateTime _date = DateTime.now();
  RecurringPeriod _recurring = RecurringPeriod.none;
  bool _isLoading = false;

  // Flag agar listener tidak trigger saat init
  bool _listenerReady = false;

  bool get _isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();

    // Tentukan index awal dari data transaksi (edit) atau default (tambah)
    final initialIndex = _isEdit ? widget.transaction!.type.index : 0;

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );

    // Isi form kalau mode edit
    if (_isEdit) {
      final t = widget.transaction!;
      _type = t.type;
      _amountCtrl.text = t.amount.toStringAsFixed(0);
      _noteCtrl.text = t.note ?? '';
      _accountId = t.accountId;
      _toAccountId = t.toAccountId;
      // Jangan set _categoryId kalau type == transfer
      _categoryId = t.type == TransactionType.transfer ? null : t.categoryId;
      _tagIds = List.from(t.tagIds);
      _date = t.date;
      _recurring = t.recurring;
    }

    // Pasang listener SETELAH init selesai
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenerReady = true;
    });

    _tabController.addListener(() {
      // Hanya proses saat animasi tab benar-benar selesai
      if (!_listenerReady) return;
      if (_tabController.indexIsChanging) return;

      final newType = TransactionType.values[_tabController.index];
      if (_type == newType) return; // tidak ada perubahan, skip

      setState(() {
        _type = newType;
        _categoryId = null; // reset kategori saat ganti tab
        // toAccountId hanya relevan untuk transfer
        if (_type != TransactionType.transfer) {
          _toAccountId = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ─── SAVE ─────────────────────────────────────────────────────
  Future<void> _save() async {
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? 0;

    if (amount <= 0) {
      _showError('Masukkan jumlah yang valid');
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
    if (_type == TransactionType.transfer) {
      if (_toAccountId == null) {
        _showError('Pilih rekening tujuan');
        return;
      }
      if (_toAccountId == _accountId) {
        _showError('Rekening asal dan tujuan tidak boleh sama');
        return;
      }
    }

    setState(() => _isLoading = true);
    final fp = context.read<FinanceProvider>();

    // Transfer tidak pakai kategori user — pakai id khusus
    final categoryId =
        _type == TransactionType.transfer ? 'transfer' : _categoryId!;

    final newT = AppTransaction(
      id: _isEdit
          ? widget.transaction!.id
          : DatabaseService.instance.newId,
      type: _type,
      amount: amount,
      accountId: _accountId!,
      toAccountId:
          _type == TransactionType.transfer ? _toAccountId : null,
      categoryId: categoryId,
      tagIds: List.from(_tagIds),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      date: _date,
      recurring: _recurring,
      createdAt:
          _isEdit ? widget.transaction!.createdAt : DateTime.now(),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red,
    ));
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text('Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context
          .read<FinanceProvider>()
          .deleteTransaction(widget.transaction!);
      if (mounted) Navigator.pop(context);
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;

    final tabColors = [
      AppTheme.expenseColor,
      AppTheme.incomeColor,
      AppTheme.transferColor,
    ];
    final currentColor = tabColors[_tabController.index];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'),
        actions: [
          if (!_isEdit)
            Tooltip(
              message: 'Scan Nota',
              child: IconButton(
                icon: const Icon(Icons.document_scanner_rounded),
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ScanReceiptScreen()),
                  );
                  if (result == true && mounted) Navigator.pop(context);
                },
              ),
            ),
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red),
              onPressed: _delete,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: currentColor,
          labelColor: currentColor,
          unselectedLabelColor: scheme.onSurfaceVariant,
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
          // Banner scan nota (hanya tambah)
          if (!_isEdit) ...[
            _scanBanner(context),
            const SizedBox(height: 12),
          ],

          // ── JUMLAH ──────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jumlah',
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Rp ',
                          style: TextStyle(
                              fontSize: 20,
                              color: currentColor,
                              fontWeight: FontWeight.bold)),
                      Expanded(
                        child: TextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: currentColor),
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

          // ── REKENING ASAL ────────────────────────────────────
          _sectionLabel('Rekening${_type == TransactionType.transfer ? ' Asal' : ''}'),
          _accountSelector(fp, isTo: false),
          const SizedBox(height: 12),

          // ── REKENING TUJUAN (transfer only) ──────────────────
          if (_type == TransactionType.transfer) ...[
            _sectionLabel('Rekening Tujuan'),
            _accountSelector(fp, isTo: true),
            const SizedBox(height: 12),
          ],

          // ── KATEGORI (bukan transfer) ─────────────────────────
          if (_type != TransactionType.transfer) ...[
            _sectionLabel('Kategori'),
            _categorySelector(fp),
            const SizedBox(height: 12),
          ],

          // ── TAG ───────────────────────────────────────────────
          _sectionLabel('Tag (opsional)'),
          _tagSelector(fp),
          const SizedBox(height: 12),

          // ── TANGGAL ───────────────────────────────────────────
          _sectionLabel('Tanggal'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today_rounded),
              title: Text(
                  DateFormat('dd MMMM yyyy', 'id_ID').format(_date)),
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

          // ── TRANSAKSI BERULANG ────────────────────────────────
          _sectionLabel('Transaksi Berulang'),
          _recurringSelector(),
          const SizedBox(height: 12),

          // ── CATATAN ───────────────────────────────────────────
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

          // ── TOMBOL SIMPAN ─────────────────────────────────────
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: currentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      _isEdit
                          ? 'Simpan Perubahan'
                          : 'Simpan Transaksi',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─── WIDGETS ──────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      );

  /// Selector rekening — isTo=false untuk asal, isTo=true untuk tujuan
  Widget _accountSelector(FinanceProvider fp, {required bool isTo}) {
    final selected = isTo ? _toAccountId : _accountId;
    final accounts = fp.accounts;

    if (accounts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Belum ada rekening. Tambahkan di menu Rekening.',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: accounts.map((a) {
        final isSelected = selected == a.id;
        // Untuk rekening tujuan, sembunyikan rekening asal
        if (isTo && a.id == _accountId) return const SizedBox.shrink();
        return ChoiceChip(
          label: Text(a.name),
          selected: isSelected,
          onSelected: (v) {
            setState(() {
              if (isTo) {
                _toAccountId = v ? a.id : null;
              } else {
                _accountId = v ? a.id : null;
                // Reset tujuan jika sama dengan asal baru
                if (_toAccountId == a.id) _toAccountId = null;
              }
            });
          },
        );
      }).toList(),
    );
  }

  /// Selector kategori — otomatis filter sesuai tab aktif
  Widget _categorySelector(FinanceProvider fp) {
    final cats = _type == TransactionType.income
        ? fp.incomeCategories
        : fp.expenseCategories;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...cats.map<Widget>((c) {
          final isSelected = _categoryId == c.id;
          return ChoiceChip(
            label: Text(c.name),
            selected: isSelected,
            onSelected: (v) {
              setState(() => _categoryId = v ? c.id : null);
            },
          );
        }),
        // Tombol tambah kategori baru langsung dari form transaksi
        ActionChip(
          avatar: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Baru'),
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          labelStyle: const TextStyle(color: AppTheme.primaryColor),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => CategoryFormSheet(
                initialType: _type,
                onAdded: (newCat) {
                  setState(() => _categoryId = newCat.id);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  /// Selector tag — multi-select dengan tombol tambah inline
  Widget _tagSelector(FinanceProvider fp) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...fp.tags.map((t) {
          final isSelected = _tagIds.contains(t.id);
          return FilterChip(
            label: Text(t.name),
            selected: isSelected,
            onSelected: (v) {
              setState(() {
                if (v) {
                  if (!_tagIds.contains(t.id)) _tagIds.add(t.id);
                } else {
                  _tagIds.remove(t.id);
                }
              });
            },
          );
        }),
        // Tombol tambah tag baru langsung
        ActionChip(
          avatar: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Baru'),
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          labelStyle: const TextStyle(color: AppTheme.primaryColor),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => TagFormSheet(
                onAdded: (newTag) {
                  setState(() => _tagIds.add(newTag.id));
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _recurringSelector() {
    final options = [
      (RecurringPeriod.none, 'Tidak', Icons.block_rounded),
      (RecurringPeriod.daily, 'Harian', Icons.today_rounded),
      (RecurringPeriod.weekly, 'Mingguan', Icons.view_week_rounded),
      (RecurringPeriod.monthly, 'Bulanan', Icons.calendar_month_rounded),
      (RecurringPeriod.yearly, 'Tahunan', Icons.calendar_today_rounded),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((opt) {
                final isSelected = _recurring == opt.$1;
                return ChoiceChip(
                  avatar: Icon(opt.$3,
                      size: 14,
                      color: isSelected ? Colors.white : Colors.grey),
                  label: Text(opt.$2),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontSize: 12),
                  onSelected: (v) {
                    if (v) setState(() => _recurring = opt.$1);
                  },
                );
              }).toList(),
            ),
            if (_recurring != RecurringPeriod.none) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppTheme.primaryColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Akan otomatis dibuat ulang setiap ${_recurringLabel(_recurring)}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _recurringLabel(RecurringPeriod p) => switch (p) {
        RecurringPeriod.daily => 'hari',
        RecurringPeriod.weekly => 'minggu',
        RecurringPeriod.monthly => 'bulan',
        RecurringPeriod.yearly => 'tahun',
        RecurringPeriod.none => '',
      };

  Widget _scanBanner(BuildContext context) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const ScanReceiptScreen()),
        );
        if (result == true && mounted) Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppTheme.primaryColor.withOpacity(0.15),
            AppTheme.primaryColor.withOpacity(0.05),
          ]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.document_scanner_rounded,
                  color: AppTheme.primaryColor, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Punya nota belanja?',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('Foto nota → otomatis jadi transaksi',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}