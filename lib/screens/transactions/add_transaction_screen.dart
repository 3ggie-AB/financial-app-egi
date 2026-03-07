import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/finance_provider.dart';
import '../../services/database_service.dart';
import '../../services/crypto_service.dart';
import '../../utils/app_theme.dart';
import 'scan_receipt_screen.dart';
import '../categories/categories_screen.dart';
import '../tags/tags_screen.dart';

// Tab order: 0=Pengeluaran, 1=Pemasukan, 2=Transfer
// TransactionType enum: income=0, expense=1, transfer=2
// Keduanya TIDAK sama, jadi harus pakai mapping eksplisit

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
  final _coinAmountCtrl = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _accountId;
  String? _toAccountId;
  String? _categoryId;
  List<String> _tagIds = [];
  DateTime _date = DateTime.now();
  RecurringPeriod _recurring = RecurringPeriod.none;
  bool _isLoading = false;

  CryptoPrice? _cryptoPrice;
  bool _isFetchingPrice = false;
  double? _convertedCoinAmount;
  bool _manualCoinInput = false;

  bool _listenerReady = false;
  bool get _isEdit => widget.transaction != null;

  // Mapping tab index → TransactionType
  // Tab 0 = Pengeluaran = expense
  // Tab 1 = Pemasukan   = income
  // Tab 2 = Transfer    = transfer
  static const _tabToType = [
    TransactionType.expense,
    TransactionType.income,
    TransactionType.transfer,
  ];

  int _typeToTabIndex(TransactionType t) {
    return _tabToType.indexOf(t);
  }

  @override
  void initState() {
    super.initState();

    // Set _type dari transaksi yang diedit, default expense
    if (_isEdit) {
      _type = widget.transaction!.type;
    } else {
      _type = TransactionType.expense;
    }

    // Tab index pakai mapping, bukan enum index
    final initialTabIndex = _typeToTabIndex(_type);

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialTabIndex,
    );

    if (_isEdit) {
      final t = widget.transaction!;
      _amountCtrl.text = t.amount.toStringAsFixed(0);
      _noteCtrl.text = _stripCryptoMeta(t.note ?? '');
      _accountId = t.accountId;
      _toAccountId = t.toAccountId;
      _categoryId = t.type == TransactionType.transfer ? null : t.categoryId;
      _tagIds = List.from(t.tagIds);
      _date = t.date;
      _recurring = t.recurring;

      final savedCoin = _extractCoinAmountFromNote(t.note ?? '');
      if (savedCoin != null) {
        _coinAmountCtrl.text = _fmtCoin(savedCoin);
        _convertedCoinAmount = savedCoin;
      }
    }

    _amountCtrl.addListener(_onAmountChanged);
    _coinAmountCtrl.addListener(_onCoinAmountChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenerReady = true;
      if (_isEdit && _type == TransactionType.transfer && _toAccountId != null) {
        final fp = context.read<FinanceProvider>();
        final toAcc = fp.accountById(_toAccountId!);
        if (toAcc?.type == 'crypto') {
          _fetchCryptoPrice(toAcc!.currency);
        }
      }
    });

    _tabController.addListener(() {
      if (!_listenerReady) return;
      if (_tabController.indexIsChanging) return;

      // Gunakan mapping eksplisit, bukan TransactionType.values[index]
      final newType = _tabToType[_tabController.index];
      if (_type == newType) return;

      setState(() {
        _type = newType;
        _categoryId = null;
        if (_type != TransactionType.transfer) {
          _toAccountId = null;
          _cryptoPrice = null;
          _convertedCoinAmount = null;
          _manualCoinInput = false;
          _coinAmountCtrl.clear();
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountCtrl.removeListener(_onAmountChanged);
    _coinAmountCtrl.removeListener(_onCoinAmountChanged);
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _coinAmountCtrl.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    if (!_manualCoinInput && _cryptoPrice != null) _recalcConversionFromIdr();
  }

  void _onCoinAmountChanged() {
    if (_manualCoinInput && _cryptoPrice != null) _recalcConversionFromCoin();
  }

  void _recalcConversionFromIdr() {
    if (_cryptoPrice == null) return;
    final idr = double.tryParse(_amountCtrl.text) ?? 0;
    final coin = (idr > 0 && _cryptoPrice!.priceIdr > 0) ? idr / _cryptoPrice!.priceIdr : null;
    setState(() => _convertedCoinAmount = coin);
    if (coin != null) {
      _coinAmountCtrl.removeListener(_onCoinAmountChanged);
      _coinAmountCtrl.text = _fmtCoin(coin);
      _coinAmountCtrl.addListener(_onCoinAmountChanged);
    }
  }

  void _recalcConversionFromCoin() {
    if (_cryptoPrice == null) return;
    final coin = double.tryParse(_coinAmountCtrl.text) ?? 0;
    final idr = (coin > 0 && _cryptoPrice!.priceIdr > 0) ? coin * _cryptoPrice!.priceIdr : null;
    setState(() => _convertedCoinAmount = coin > 0 ? coin : null);
    if (idr != null) {
      _amountCtrl.removeListener(_onAmountChanged);
      _amountCtrl.text = idr.toStringAsFixed(0);
      _amountCtrl.addListener(_onAmountChanged);
    }
  }

  Future<void> _fetchCryptoPrice(String symbol) async {
    setState(() {
      _isFetchingPrice = true;
      _cryptoPrice = null;
      if (!_manualCoinInput) _convertedCoinAmount = null;
    });
    final price = await CryptoService.instance.getPrice(symbol);
    if (mounted) {
      setState(() { _cryptoPrice = price; _isFetchingPrice = false; });
      if (_manualCoinInput) {
        _recalcConversionFromCoin();
      } else {
        _recalcConversionFromIdr();
      }
    }
  }

  String _stripCryptoMeta(String note) =>
      note.replaceAll(RegExp(r'\s*__crypto_coin_amount:[^_]+__'), '').trim();

  double? _extractCoinAmountFromNote(String note) {
    final match = RegExp(r'__crypto_coin_amount:([0-9.]+)__').firstMatch(note);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  // ─── SAVE ─────────────────────────────────────────────────────
  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? 0;

    if (amount <= 0) { _showError('Masukkan jumlah yang valid'); return; }
    if (_accountId == null) { _showError('Pilih rekening'); return; }
    if (_type != TransactionType.transfer && _categoryId == null) {
      _showError('Pilih kategori'); return;
    }
    if (_type == TransactionType.transfer) {
      if (_toAccountId == null) { _showError('Pilih rekening tujuan'); return; }
      if (_toAccountId == _accountId) {
        _showError('Rekening asal dan tujuan tidak boleh sama'); return;
      }
    }

    final fp = context.read<FinanceProvider>();
    final toAccount = _toAccountId != null ? fp.accountById(_toAccountId!) : null;
    final isCryptoTransfer = _type == TransactionType.transfer && toAccount?.type == 'crypto';

    if (isCryptoTransfer) {
      if (_cryptoPrice == null && !_manualCoinInput) {
        _showError('Harga crypto belum tersedia, coba lagi');
        return;
      }
      if (_convertedCoinAmount == null || _convertedCoinAmount! <= 0) {
        _showError('Masukkan jumlah coin yang valid');
        return;
      }
    }

    setState(() => _isLoading = true);

    final categoryId = _type == TransactionType.transfer ? 'transfer' : _categoryId!;
    String? noteValue = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    if (isCryptoTransfer && _convertedCoinAmount != null) {
      final meta = '__crypto_coin_amount:${_convertedCoinAmount!}__';
      noteValue = noteValue != null ? '$noteValue $meta' : meta;
    }

    final newT = AppTransaction(
      id: _isEdit ? widget.transaction!.id : DatabaseService.instance.newId,
      type: _type,
      amount: amount,
      accountId: _accountId!,
      toAccountId: _type == TransactionType.transfer ? _toAccountId : null,
      categoryId: categoryId,
      tagIds: List.from(_tagIds),
      note: noteValue,
      date: _date,
      recurring: _recurring,
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<FinanceProvider>().deleteTransaction(widget.transaction!);
      if (mounted) Navigator.pop(context);
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;
    final tabColors = [AppTheme.expenseColor, AppTheme.incomeColor, AppTheme.transferColor];
    final currentColor = tabColors[_tabController.index];

    final toAccount = _toAccountId != null ? fp.accountById(_toAccountId!) : null;
    final isCryptoTarget = toAccount?.type == 'crypto';

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
                    context, MaterialPageRoute(builder: (_) => const ScanReceiptScreen()));
                  if (result == true && mounted) Navigator.pop(context);
                },
              ),
            ),
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
          if (!_isEdit) ...[_scanBanner(context), const SizedBox(height: 12)],

          // ── JUMLAH ──────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCryptoTarget) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _manualCoinInput ? 'Jumlah Coin' : 'Jumlah IDR yang dikirim',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _manualCoinInput = !_manualCoinInput;
                              _convertedCoinAmount = null;
                            });
                            if (_manualCoinInput) {
                              _recalcConversionFromCoin();
                            } else {
                              _recalcConversionFromIdr();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.transferColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.transferColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.swap_horiz_rounded,
                                    color: AppTheme.transferColor, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  _manualCoinInput ? 'Ganti ke IDR' : 'Input ${toAccount!.currency}',
                                  style: const TextStyle(
                                      color: AppTheme.transferColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ] else
                    Text('Jumlah', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Text('Rp ',
                          style: TextStyle(
                              fontSize: 20, color: currentColor, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: TextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold, color: currentColor),
                          decoration: const InputDecoration(
                              border: InputBorder.none, filled: false, hintText: '0'),
                        ),
                      ),
                    ],
                  ),

                  if (isCryptoTarget && _manualCoinInput) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${toAccount!.currency} ',
                            style: const TextStyle(
                                fontSize: 16,
                                color: AppTheme.transferColor,
                                fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _coinAmountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.transferColor),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                filled: false,
                                hintText: '0.00000000',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (isCryptoTarget) ...[
                    const Divider(height: 16),
                    if (_isFetchingPrice)
                      const Row(children: [
                        SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('Mengambil harga live...',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ])
                    else if (_cryptoPrice != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('1 ${toAccount!.currency} = ${_fmtIdr(_cryptoPrice!.priceIdr)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Row(children: [
                            Icon(
                              _cryptoPrice!.change24h >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                              color: _cryptoPrice!.change24h >= 0 ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            Text('${_cryptoPrice!.change24h.abs().toStringAsFixed(2)}%',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: _cryptoPrice!.change24h >= 0 ? Colors.green : Colors.red)),
                          ]),
                        ],
                      ),
                      if (_convertedCoinAmount != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.transferColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(children: [
                            const Icon(Icons.swap_horiz_rounded,
                                color: AppTheme.transferColor, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _manualCoinInput
                                  ? RichText(
                                      text: TextSpan(style: const TextStyle(fontSize: 12), children: [
                                        const TextSpan(text: 'Setara: ', style: TextStyle(color: Colors.grey)),
                                        TextSpan(
                                          text: _fmtIdr(_convertedCoinAmount! * _cryptoPrice!.priceIdr),
                                          style: const TextStyle(
                                              color: AppTheme.transferColor, fontWeight: FontWeight.bold),
                                        ),
                                      ]))
                                  : RichText(
                                      text: TextSpan(style: const TextStyle(fontSize: 12), children: [
                                        const TextSpan(text: 'Akan diterima: ', style: TextStyle(color: Colors.grey)),
                                        TextSpan(
                                          text: '${_fmtCoin(_convertedCoinAmount!)} ${toAccount!.currency}',
                                          style: const TextStyle(
                                              color: AppTheme.transferColor, fontWeight: FontWeight.bold),
                                        ),
                                      ])),
                            ),
                          ]),
                        ),
                      ],
                    ] else
                      const Row(children: [
                        Icon(Icons.error_outline, color: Colors.orange, size: 14),
                        SizedBox(width: 6),
                        Text('Gagal ambil harga, cek koneksi',
                            style: TextStyle(fontSize: 12, color: Colors.orange)),
                      ]),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          _sectionLabel('Rekening${_type == TransactionType.transfer ? ' Asal' : ''}'),
          _accountSelector(fp, isTo: false),
          const SizedBox(height: 12),

          if (_type == TransactionType.transfer) ...[
            _sectionLabel('Rekening Tujuan'),
            _accountSelector(fp, isTo: true),
            const SizedBox(height: 12),
          ],

          if (_type != TransactionType.transfer) ...[
            _sectionLabel('Kategori'),
            _categorySelector(fp),
            const SizedBox(height: 12),
          ],

          _sectionLabel('Tag (opsional)'),
          _tagSelector(fp),
          const SizedBox(height: 12),

          _sectionLabel('Tanggal'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today_rounded),
              title: Text(DateFormat('dd MMMM yyyy', 'id_ID').format(_date)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context, initialDate: _date,
                  firstDate: DateTime(2020), lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
          ),
          const SizedBox(height: 12),

          _sectionLabel('Transaksi Berulang'),
          _recurringSelector(),
          const SizedBox(height: 12),

          _sectionLabel('Catatan (opsional)'),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Tambahkan catatan...', prefixIcon: Icon(Icons.note_rounded)),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: currentColor, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Transaksi',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                fontSize: 12, fontWeight: FontWeight.w500)),
      );

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
      spacing: 8, runSpacing: 8,
      children: accounts.map((a) {
        final isSelected = selected == a.id;
        if (isTo && a.id == _accountId) return const SizedBox.shrink();
        return ChoiceChip(
          label: Text(a.name),
          selected: isSelected,
          onSelected: (v) {
            setState(() {
              if (isTo) {
                _toAccountId = v ? a.id : null;
                if (v) {
                  final acc = fp.accountById(a.id);
                  if (acc?.type == 'crypto') {
                    _fetchCryptoPrice(acc!.currency);
                  } else {
                    _cryptoPrice = null;
                    _convertedCoinAmount = null;
                    _manualCoinInput = false;
                    _coinAmountCtrl.clear();
                  }
                } else {
                  _cryptoPrice = null;
                  _convertedCoinAmount = null;
                  _manualCoinInput = false;
                  _coinAmountCtrl.clear();
                }
              } else {
                _accountId = v ? a.id : null;
                if (_toAccountId == a.id) _toAccountId = null;
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _categorySelector(FinanceProvider fp) {
    // _type sudah di-set dengan benar via _tabToType mapping
    final cats = _type == TransactionType.income
        ? fp.incomeCategories
        : fp.expenseCategories;

    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        ...cats.map<Widget>((c) {
          final isSelected = _categoryId == c.id;
          return ChoiceChip(
            label: Text(c.name),
            selected: isSelected,
            onSelected: (v) => setState(() => _categoryId = v ? c.id : null),
          );
        }),
        ActionChip(
          avatar: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Baru'),
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          labelStyle: const TextStyle(color: AppTheme.primaryColor),
          onPressed: () {
            showModalBottomSheet(
              context: context, isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => CategoryFormSheet(
                initialType: _type,
                onAdded: (newCat) => setState(() => _categoryId = newCat.id),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _tagSelector(FinanceProvider fp) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        ...fp.tags.map((t) {
          final isSelected = _tagIds.contains(t.id);
          return FilterChip(
            label: Text(t.name),
            selected: isSelected,
            onSelected: (v) {
              setState(() {
                if (v) { if (!_tagIds.contains(t.id)) _tagIds.add(t.id); }
                else { _tagIds.remove(t.id); }
              });
            },
          );
        }),
        ActionChip(
          avatar: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Baru'),
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          labelStyle: const TextStyle(color: AppTheme.primaryColor),
          onPressed: () {
            showModalBottomSheet(
              context: context, isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => TagFormSheet(
                onAdded: (newTag) => setState(() => _tagIds.add(newTag.id)),
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
              spacing: 8, runSpacing: 8,
              children: options.map((opt) {
                final isSelected = _recurring == opt.$1;
                return ChoiceChip(
                  avatar: Icon(opt.$3, size: 14, color: isSelected ? Colors.white : Colors.grey),
                  label: Text(opt.$2),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : null, fontSize: 12),
                  onSelected: (v) { if (v) setState(() => _recurring = opt.$1); },
                );
              }).toList(),
            ),
            if (_recurring != RecurringPeriod.none) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Akan otomatis dibuat ulang setiap ${_recurringLabel(_recurring)}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor),
                    ),
                  ),
                ]),
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
          context, MaterialPageRoute(builder: (_) => const ScanReceiptScreen()));
        if (result == true && mounted) Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppTheme.primaryColor.withOpacity(0.15),
            AppTheme.primaryColor.withOpacity(0.05),
          ]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
        ),
        child: Row(children: [
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Punya nota belanja?',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('Foto nota → otomatis jadi transaksi',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.primaryColor),
        ]),
      ),
    );
  }

  String _fmtIdr(double v) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

  String _fmtCoin(double v) => v >= 1 ? v.toStringAsFixed(6) : v.toStringAsFixed(8);
}