// screens/accounts/accounts_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/finance_provider.dart';
import '../../services/database_service.dart';
import '../../services/crypto_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/color_picker_widget.dart';

String _fmt(double v) =>
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

String _fmtCrypto(double v) {
  if (v >= 1) return v.toStringAsFixed(4);
  return v.toStringAsFixed(8);
}

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Rekening')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'accounts_fab',
        onPressed: () => _showAccountDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: fp.accounts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_rounded,
                      size: 64, color: scheme.onSurfaceVariant.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  const Text('Belum ada rekening'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                // Total Balance Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.primary.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Saldo (Non-Crypto)',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(_fmt(fp.totalBalance),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...fp.accounts.map((a) => a.type == 'crypto'
                    ? _cryptoAccountCard(context, a, fp)
                    : _accountCard(context, a, fp)),
              ],
            ),
    );
  }

  Widget _accountCard(BuildContext context, Account account, FinanceProvider fp) {
    final color = colorFromHex(account.color);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_accountIcon(account.type), color: color),
        ),
        title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(_accountTypeLabel(account.type), style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_fmt(account.balance),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: account.balance >= 0 ? Colors.green : Colors.red,
                    fontSize: 15)),
            Text(account.currency, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        onTap: () => _showAccountDialog(context, account: account),
      ),
    );
  }

  Widget _cryptoAccountCard(BuildContext context, Account account, FinanceProvider fp) {
    final color = colorFromHex(account.color);
    final coin = CryptoService.coinBySymbol(account.currency);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAccountDialog(context, account: account),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Coin icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        coin?.icon ?? '₿',
                        style: TextStyle(fontSize: 22, color: color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        Text('${coin?.name ?? account.currency} · Crypto',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  // Jumlah coin
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_fmtCrypto(account.balance)} ${account.currency}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Live IDR value
                      FutureBuilder<CryptoPrice?>(
                        future: CryptoService.instance.getPrice(account.currency),
                        builder: (ctx, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 1.5),
                            );
                          }
                          if (snap.data == null) {
                            return const Text('Harga N/A',
                                style: TextStyle(fontSize: 11, color: Colors.grey));
                          }
                          final price = snap.data!;
                          final idrValue = price.priceIdr * account.balance;
                          final isUp = price.change24h >= 0;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_fmt(idrValue),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                    color: isUp ? Colors.green : Colors.red,
                                    size: 16,
                                  ),
                                  Text(
                                    '${price.change24h.abs().toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isUp ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              // Live price bar
              FutureBuilder<CryptoPrice?>(
                future: CryptoService.instance.getPrice(account.currency),
                builder: (ctx, snap) {
                  if (snap.data == null) return const SizedBox.shrink();
                  final price = snap.data!;
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: color),
                        const SizedBox(width: 6),
                        Text(
                          '1 ${account.currency} = \$${price.priceUsd.toStringAsFixed(2)} ≈ ${_fmt(price.priceIdr)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const Spacer(),
                        Text(
                          'Live · Binance',
                          style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _accountTypeLabel(String type) => switch (type) {
        'cash' => 'Tunai',
        'bank' => 'Bank',
        'credit' => 'Kartu Kredit',
        'ewallet' => 'E-Wallet',
        'investment' => 'Investasi',
        'crypto' => 'Crypto',
        _ => type,
      };

  IconData _accountIcon(String type) => switch (type) {
        'cash' => Icons.account_balance_wallet_rounded,
        'bank' => Icons.account_balance_rounded,
        'credit' => Icons.credit_card_rounded,
        'ewallet' => Icons.phone_android_rounded,
        'investment' => Icons.trending_up_rounded,
        'crypto' => Icons.currency_bitcoin_rounded,
        _ => Icons.wallet_rounded,
      };

  void _showAccountDialog(BuildContext context, {Account? account}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AccountFormSheet(account: account),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACCOUNT FORM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class AccountFormSheet extends StatefulWidget {
  final Account? account;
  const AccountFormSheet({super.key, this.account});

  @override
  State<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<AccountFormSheet> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  String _type = 'cash';
  String _color = '#4CAF50';
  String? _selectedCoin;
  CryptoPrice? _livePrice;
  bool _isLoading = false;
  bool _isFetchingPrice = false;

  final _types = ['cash', 'bank', 'credit', 'ewallet', 'investment', 'crypto'];

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameCtrl.text = widget.account!.name;
      _balanceCtrl.text = widget.account!.balance.toStringAsFixed(
        widget.account!.type == 'crypto' ? 8 : 0,
      );
      _type = widget.account!.type;
      _color = widget.account!.color;
      if (_type == 'crypto') {
        _selectedCoin = widget.account!.currency;
        _fetchPrice(_selectedCoin!);
      }
    }
  }

  Future<void> _fetchPrice(String symbol) async {
    setState(() => _isFetchingPrice = true);
    final price = await CryptoService.instance.getPrice(symbol);
    if (mounted) setState(() { _livePrice = price; _isFetchingPrice = false; });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCrypto = _type == 'crypto';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.account == null ? 'Tambah Rekening' : 'Edit Rekening',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (widget.account != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: _delete,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Nama
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nama Rekening',
              prefixIcon: Icon(Icons.label_rounded),
            ),
          ),
          const SizedBox(height: 12),

          // Jenis rekening
          const Text('Jenis', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types.map((t) => ChoiceChip(
              label: Text(_typeLabel(t)),
              selected: _type == t,
              avatar: _type == t ? null : Icon(_typeIcon(t), size: 14),
              onSelected: (v) {
                if (v) {
                  setState(() {
                    _type = t;
                    _selectedCoin = null;
                    _livePrice = null;
                  });
                }
              },
            )).toList(),
          ),
          const SizedBox(height: 16),

          // Crypto coin selector
          if (isCrypto) ...[
            const Text('Pilih Coin', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CryptoService.supportedCoins.map((coin) {
                final isSelected = _selectedCoin == coin.symbol;
                return ChoiceChip(
                  label: Text('${coin.icon} ${coin.symbol}'),
                  selected: isSelected,
                  tooltip: coin.name,
                  onSelected: (v) {
                    if (v) {
                      setState(() => _selectedCoin = coin.symbol);
                      _fetchPrice(coin.symbol);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Live price display
            if (_selectedCoin != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isFetchingPrice
                    ? const Row(
                        children: [
                          SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Mengambil harga dari Binance...'),
                        ],
                      )
                    : _livePrice != null
                        ? Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Harga ${_selectedCoin}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  Row(
                                    children: [
                                      Icon(
                                        _livePrice!.change24h >= 0
                                            ? Icons.arrow_drop_up
                                            : Icons.arrow_drop_down,
                                        color: _livePrice!.change24h >= 0
                                            ? Colors.green
                                            : Colors.red,
                                        size: 18,
                                      ),
                                      Text(
                                        '${_livePrice!.change24h.abs().toStringAsFixed(2)}% 24j',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _livePrice!.change24h >= 0
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '\$${_livePrice!.priceUsd.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '≈ ${_fmt(_livePrice!.priceIdr)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500, fontSize: 14),
                                  ),
                                ],
                              ),
                              // Kalkulasi otomatis nilai jika ada saldo
                              if (_balanceCtrl.text.isNotEmpty &&
                                  double.tryParse(_balanceCtrl.text) != null) ...[
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Nilai ${_balanceCtrl.text} ${_selectedCoin}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text(
                                      _fmt(_livePrice!.priceIdr *
                                          (double.tryParse(_balanceCtrl.text) ?? 0)),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          )
                        : const Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.orange, size: 16),
                              SizedBox(width: 8),
                              Text('Gagal mengambil harga, cek koneksi',
                                  style: TextStyle(color: Colors.orange, fontSize: 12)),
                            ],
                          ),
              ),
            const SizedBox(height: 12),
          ],

          // Saldo / Jumlah coin
          TextField(
            controller: _balanceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}), // trigger rebuild untuk kalkulasi
            decoration: InputDecoration(
              labelText: isCrypto
                  ? 'Jumlah ${_selectedCoin ?? 'Coin'}'
                  : 'Saldo Awal',
              prefixIcon: Icon(
                isCrypto ? Icons.currency_bitcoin_rounded : Icons.money_rounded,
              ),
              suffixText: isCrypto ? (_selectedCoin ?? '') : 'IDR',
            ),
          ),
          const SizedBox(height: 16),

          // Warna custom
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
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text(
                      widget.account == null ? 'Tambah' : 'Simpan',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _typeLabel(String t) => switch (t) {
        'cash' => 'Tunai',
        'bank' => 'Bank',
        'credit' => 'Kredit',
        'ewallet' => 'E-Wallet',
        'investment' => 'Investasi',
        'crypto' => '₿ Crypto',
        _ => t,
      };

  IconData _typeIcon(String t) => switch (t) {
        'cash' => Icons.account_balance_wallet_rounded,
        'bank' => Icons.account_balance_rounded,
        'credit' => Icons.credit_card_rounded,
        'ewallet' => Icons.phone_android_rounded,
        'investment' => Icons.trending_up_rounded,
        'crypto' => Icons.currency_bitcoin_rounded,
        _ => Icons.wallet_rounded,
      };

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    if (_type == 'crypto' && _selectedCoin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih coin terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final fp = context.read<FinanceProvider>();
    final balance = double.tryParse(_balanceCtrl.text) ?? 0;
    final currency = _type == 'crypto' ? _selectedCoin! : 'IDR';

    if (widget.account == null) {
      await fp.addAccount(Account(
        id: DatabaseService.instance.newId,
        name: _nameCtrl.text,
        type: _type,
        balance: balance,
        currency: currency,
        color: _color,
        createdAt: DateTime.now(),
      ));
    } else {
      await fp.updateAccount(widget.account!.copyWith(
        name: _nameCtrl.text,
        type: _type,
        balance: balance,
        currency: currency,
        color: _color,
      ));
    }

    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Rekening?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<FinanceProvider>().deleteAccount(widget.account!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}