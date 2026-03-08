// screens/accounts/accounts_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/models.dart';
import '../../providers/finance_provider.dart';
import '../../services/database_service.dart';
import '../../services/crypto_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/color_picker_widget.dart';

String _fmt(double v) =>
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

String _fmtCrypto(double v) =>
    v >= 1 ? v.toStringAsFixed(4) : v.toStringAsFixed(8);

String _fmtCompact(double v) {
  if (v >= 1000000000) return 'Rp ${(v / 1000000000).toStringAsFixed(1)}M';
  if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}jt';
  if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}rb';
  return 'Rp ${v.toStringAsFixed(0)}';
}

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: const Text('Rekening'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _AddButton(onTap: () => _showAccountDialog(context)),
          ),
        ],
      ),
      body: fp.accounts.isEmpty
          ? _buildEmptyState(context, isDark)
          : _buildContent(context, fp, isDark),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 38,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada rekening',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tambahkan rekening pertamamu',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: isDark ? const Color(0xFF5A5A7A) : const Color(0xFFD1D5DB),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAccountDialog(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah Rekening'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, FinanceProvider fp, bool isDark) {
    final nonCryptoAccounts =
        fp.accounts.where((a) => a.type != 'crypto').toList();
    final cryptoAccounts =
        fp.accounts.where((a) => a.type == 'crypto').toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        // ── Hero Balance Card ──────────────────────────────────
        _buildHeroBalanceCard(context, fp, isDark),
        const SizedBox(height: 24),

        // ── Donut Distribution Chart ───────────────────────────
        if (nonCryptoAccounts.length > 1) ...[
          _buildDistributionChart(context, nonCryptoAccounts, isDark),
          const SizedBox(height: 24),
        ],

        // ── Rekening Biasa ─────────────────────────────────────
        if (nonCryptoAccounts.isNotEmpty) ...[
          _sectionHeader(context, '🏦 Rekening', isDark),
          const SizedBox(height: 12),
          ...nonCryptoAccounts.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AccountCard(
                account: a,
                onTap: () => _showAccountDialog(context, account: a),
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // ── Crypto Accounts ────────────────────────────────────
        if (cryptoAccounts.isNotEmpty) ...[
          _sectionHeader(context, '₿ Crypto', isDark),
          const SizedBox(height: 12),
          ...cryptoAccounts.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CryptoAccountCard(
                account: a,
                onTap: () => _showAccountDialog(context, account: a),
                isDark: isDark,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Hero Balance ─────────────────────────────────────────────
  Widget _buildHeroBalanceCard(
      BuildContext context, FinanceProvider fp, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1A0A3E), Color(0xFF0F0F28)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppTheme.heroGradientLight,
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative glow
          Positioned(
            top: -30, right: -20,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -20, left: 10,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.goldColor.withOpacity(0.07),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.goldColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.goldColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance_wallet_rounded,
                            color: AppTheme.goldColor, size: 11),
                        const SizedBox(width: 5),
                        Text(
                          'TOTAL SALDO',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppTheme.goldColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${fp.accounts.length} rekening',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _fmt(fp.totalBalance),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Non-Crypto · IDR',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Distribution Chart ───────────────────────────────────────
  Widget _buildDistributionChart(
      BuildContext context,
      List<Account> accounts,
      bool isDark) {
    final total =
        accounts.fold(0.0, (s, a) => s + a.balance.clamp(0, double.infinity));
    if (total == 0) return const SizedBox.shrink();

    final colors = [
      AppTheme.primaryColor,
      AppTheme.incomeColor,
      AppTheme.goldColor,
      AppTheme.transferColor,
      AppTheme.expenseColor,
      const Color(0xFFB47AF7),
      const Color(0xFF60E8D0),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppTheme.darkBorder.withOpacity(0.5)
              : AppTheme.lightBorder,
          width: 1,
        ),
        boxShadow:
            isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribusi Saldo',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF1A1040),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Donut Chart
              SizedBox(
                width: 130, height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: accounts.asMap().entries.map((e) {
                          final i = e.key;
                          final a = e.value;
                          final val = a.balance.clamp(0, double.infinity).toDouble();
                          return PieChartSectionData(
                            value: val,
                            color: colors[i % colors.length],
                            radius: 32,
                            showTitle: false,
                            borderSide: BorderSide(
                              color: isDark ? AppTheme.darkCard : Colors.white,
                              width: 2.5,
                            ),
                          );
                        }).toList(),
                        centerSpaceRadius: 38,
                        sectionsSpace: 3,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${accounts.length}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1040),
                          ),
                        ),
                        Text(
                          'rekening',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            color: isDark
                                ? const Color(0xFF7878A0)
                                : const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: accounts.asMap().entries.map((e) {
                    final i = e.key;
                    final a = e.value;
                    final pct = total > 0
                        ? (a.balance.clamp(0, double.infinity) / total * 100)
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  color: colors[i % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  a.name,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? const Color(0xFFD0D0E8)
                                        : const Color(0xFF374151),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${pct.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: colors[i % colors.length],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (pct / 100).clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor: isDark
                                  ? AppTheme.darkBorder
                                  : AppTheme.lightBorder,
                              valueColor: AlwaysStoppedAnimation(
                                  colors[i % colors.length]),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: isDark ? Colors.white : const Color(0xFF1A1040),
      ),
    );
  }

  void _showAccountDialog(BuildContext context, {Account? account}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AccountFormSheet(account: account),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.primaryShadow,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'Tambah',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACCOUNT CARD (Non-Crypto)
// ─────────────────────────────────────────────────────────────────────────────
class _AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;
  final bool isDark;

  const _AccountCard({
    required this.account,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(account.color);
    final isNeg = account.balance < 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? AppTheme.darkBorder.withOpacity(0.5)
                : AppTheme.lightBorder,
            width: 1,
          ),
          boxShadow: isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.2), width: 1),
              ),
              child: Icon(_accountIcon(account.type), color: color, size: 22),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1A1040),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _accountTypeLabel(account.type),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        account.currency,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: isDark
                              ? const Color(0xFF7878A0)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmt(account.balance),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isNeg ? AppTheme.expenseColor : AppTheme.incomeColor,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: isDark
                      ? const Color(0xFF5A5A7A)
                      : const Color(0xFFD1D5DB),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _accountTypeLabel(String type) => switch (type) {
        'cash' => 'Tunai',
        'bank' => 'Bank',
        'credit' => 'Kredit',
        'ewallet' => 'E-Wallet',
        'investment' => 'Investasi',
        _ => type,
      };

  IconData _accountIcon(String type) => switch (type) {
        'cash' => Icons.account_balance_wallet_rounded,
        'bank' => Icons.account_balance_rounded,
        'credit' => Icons.credit_card_rounded,
        'ewallet' => Icons.phone_android_rounded,
        'investment' => Icons.trending_up_rounded,
        _ => Icons.wallet_rounded,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// CRYPTO ACCOUNT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _CryptoAccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;
  final bool isDark;

  const _CryptoAccountCard({
    required this.account,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(account.color);
    final coin = CryptoService.coinBySymbol(account.currency);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? AppTheme.darkBorder.withOpacity(0.5)
                : AppTheme.lightBorder,
            width: 1,
          ),
          boxShadow: isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Coin Icon
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.2), width: 1),
                  ),
                  child: Center(
                    child: Text(
                      coin?.icon ?? '₿',
                      style: TextStyle(fontSize: 22, color: color),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF1A1040),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              coin?.name ?? account.currency,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.goldColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Crypto',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.goldColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Coin amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_fmtCrypto(account.balance)} ${account.currency}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<CryptoPrice?>(
                      future: CryptoService.instance.getPrice(account.currency),
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: color.withOpacity(0.6),
                            ),
                          );
                        }
                        if (snap.data == null) {
                          return Text(
                            'N/A',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF7878A0)
                                  : const Color(0xFF9CA3AF),
                            ),
                          );
                        }
                        final price = snap.data!;
                        final idrValue = price.priceIdr * account.balance;
                        final isUp = price.change24h >= 0;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _fmtCompact(idrValue),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: isDark
                                    ? const Color(0xFF7878A0)
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUp
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                  color: isUp
                                      ? AppTheme.incomeColor
                                      : AppTheme.expenseColor,
                                  size: 14,
                                ),
                                Text(
                                  '${price.change24h.abs().toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isUp
                                        ? AppTheme.incomeColor
                                        : AppTheme.expenseColor,
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
                final isUp = price.change24h >= 0;
                return Column(
                  children: [
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkCardAlt
                            : AppTheme.lightCardAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkBorder.withOpacity(0.4)
                              : AppTheme.lightBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: isUp
                                  ? AppTheme.incomeColor
                                  : AppTheme.expenseColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '1 ${account.currency} = \$${price.priceUsd.toStringAsFixed(2)}  ≈  ${_fmt(price.priceIdr)}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: isDark
                                    ? const Color(0xFF9090B8)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isUp
                                      ? AppTheme.incomeColor
                                      : AppTheme.expenseColor)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Live',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isUp
                                    ? AppTheme.incomeColor
                                    : AppTheme.expenseColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
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
  String _color = '#7C6AF7';
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPrice(String symbol) async {
    setState(() => _isFetchingPrice = true);
    final price = await CryptoService.instance.getPrice(symbol);
    if (mounted) setState(() { _livePrice = price; _isFetchingPrice = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final isCrypto = _type == 'crypto';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: isDark
            ? Border.all(
                color: AppTheme.darkBorder.withOpacity(0.5), width: 1)
            : null,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.account == null ? 'Tambah Rekening' : 'Edit Rekening',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1040),
                  ),
                ),
                if (widget.account != null)
                  GestureDetector(
                    onTap: _delete,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.expenseColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: AppTheme.expenseColor, size: 18),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Nama
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Rekening',
                prefixIcon: Icon(Icons.label_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Jenis rekening
            _label('Jenis Rekening', isDark),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((t) {
                final isSelected = _type == t;
                return GestureDetector(
                  onTap: () => setState(() {
                    _type = t;
                    _selectedCoin = null;
                    _livePrice = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? AppTheme.primaryGradient
                          : null,
                      color: isSelected
                          ? null
                          : isDark
                              ? AppTheme.darkCardAlt
                              : AppTheme.lightCardAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : isDark
                                ? AppTheme.darkBorder
                                : AppTheme.lightBorder,
                        width: 1.2,
                      ),
                      boxShadow: isSelected ? AppTheme.primaryShadow : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _typeIcon(t),
                          size: 14,
                          color: isSelected
                              ? Colors.white
                              : isDark
                                  ? const Color(0xFF9090B8)
                                  : const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _typeLabel(t),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : isDark
                                    ? const Color(0xFFB0B0D0)
                                    : const Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Crypto coin selector
            if (isCrypto) ...[
              _label('Pilih Coin', isDark),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CryptoService.supportedCoins.map((coin) {
                  final isSelected = _selectedCoin == coin.symbol;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCoin = coin.symbol);
                      _fetchPrice(coin.symbol);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.goldColor.withOpacity(0.15)
                            : isDark
                                ? AppTheme.darkCardAlt
                                : AppTheme.lightCardAlt,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.goldColor
                              : isDark
                                  ? AppTheme.darkBorder
                                  : AppTheme.lightBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        '${coin.icon} ${coin.symbol}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppTheme.goldColor
                              : isDark
                                  ? const Color(0xFFB0B0D0)
                                  : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Live Price Card
              if (_selectedCoin != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkBorder.withOpacity(0.5)
                          : AppTheme.lightBorder,
                    ),
                  ),
                  child: _isFetchingPrice
                      ? Row(
                          children: [
                            SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Mengambil harga dari Binance...',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF9090B8)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        )
                      : _livePrice != null
                          ? _buildLivePriceContent(isDark)
                          : Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: AppTheme.goldColor, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Gagal mengambil harga, cek koneksi',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: AppTheme.goldColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                ),
              const SizedBox(height: 16),
            ],

            // Saldo / Jumlah coin
            TextField(
              controller: _balanceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: isCrypto
                    ? 'Jumlah ${_selectedCoin ?? 'Coin'}'
                    : 'Saldo Awal',
                prefixIcon: Icon(
                  isCrypto
                      ? Icons.currency_bitcoin_rounded
                      : Icons.money_rounded,
                ),
                suffixText: isCrypto ? (_selectedCoin ?? '') : 'IDR',
              ),
            ),
            const SizedBox(height: 20),

            // Warna
            _label('Warna', isDark),
            const SizedBox(height: 12),
            ColorPickerWidget(
              selectedColor: _color,
              onColorChanged: (c) => setState(() => _color = c),
            ),
            const SizedBox(height: 28),

            // Simpan button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        widget.account == null ? 'Tambah Rekening' : 'Simpan Perubahan',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePriceContent(bool isDark) {
    final isUp = _livePrice!.change24h >= 0;
    final hasBalance = _balanceCtrl.text.isNotEmpty &&
        double.tryParse(_balanceCtrl.text) != null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1 $_selectedCoin',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF7878A0)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${_livePrice!.priceUsd.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: isDark ? Colors.white : const Color(0xFF1A1040),
                    ),
                  ),
                  Text(
                    '≈ ${_fmt(_livePrice!.priceIdr)}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF9090B8)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (isUp ? AppTheme.incomeColor : AppTheme.expenseColor)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isUp ? AppTheme.incomeColor : AppTheme.expenseColor)
                      .withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    color: isUp ? AppTheme.incomeColor : AppTheme.expenseColor,
                    size: 18,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${isUp ? '+' : ''}${_livePrice!.change24h.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isUp ? AppTheme.incomeColor : AppTheme.expenseColor,
                    ),
                  ),
                  Text(
                    '24j',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      color: isDark
                          ? const Color(0xFF7878A0)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (hasBalance) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.incomeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.incomeColor.withOpacity(0.2), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_balanceCtrl.text} $_selectedCoin =',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF9090B8)
                        : const Color(0xFF6B7280),
                  ),
                ),
                Text(
                  _fmt(_livePrice!.priceIdr *
                      (double.tryParse(_balanceCtrl.text) ?? 0)),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: AppTheme.incomeColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _label(String text, bool isDark) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: isDark ? const Color(0xFFB0B0D0) : const Color(0xFF374151),
        ),
      );

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
        SnackBar(
          content: const Text('Pilih coin terlebih dahulu'),
          backgroundColor: AppTheme.expenseColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
        content: const Text('Saldo dan data rekening ini akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expenseColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
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