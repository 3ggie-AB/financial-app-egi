// screens/dashboard/dashboard_screen.dart
// FinanceKu — Beautiful Luxury Dark Finance Dashboard

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/finance_provider.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../transactions/transaction_tile.dart';
import '../../widgets/sync_status_widget.dart';
import 'package:intl/intl.dart';

String _fmt(double amount) =>
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
String _fmtMonth(DateTime d) =>
    DateFormat('MMMM yyyy', 'id_ID').format(d);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  DateTime _selectedMonth = DateTime.now();
  late AnimationController _heroCtrl;
  late AnimationController _cardsCtrl;
  late Animation<double> _heroAnim;
  late Animation<double> _cardsAnim;

  void _prevMonth() =>
      setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
  void _nextMonth() =>
      setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _cardsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _heroAnim = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutCubic);
    _cardsAnim = CurvedAnimation(parent: _cardsCtrl, curve: Curves.easeOutCubic);
    _heroCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () => _cardsCtrl.forward());
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _cardsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final income = fp.monthlyIncome(_selectedMonth);
    final expense = fp.monthlyExpense(_selectedMonth);
    final balance = income - expense;
    final recentTxns = fp.transactionsForMonth(_selectedMonth).take(5).toList();
    final expByCategory = fp.expensesByCategory(_selectedMonth);

    return Scaffold(
      backgroundColor: scheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── HERO HEADER ────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _heroAnim,
              child: _buildHeroHeader(context, fp, isDark, scheme),
            ),
          ),

          // ── CONTENT ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _cardsAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month Selector
                    _buildMonthSelector(context, isDark),
                    const SizedBox(height: 20),

                    // Income / Expense Cards
                    _buildSummaryRow(income, expense, isDark),
                    const SizedBox(height: 14),

                    // Balance Card
                    _buildBalanceCard(balance, isDark),
                    const SizedBox(height: 28),

                    // Pie Chart
                    if (expByCategory.isNotEmpty) ...[
                      _sectionTitle(context, '📊 Pengeluaran per Kategori'),
                      const SizedBox(height: 12),
                      _buildPieChart(expByCategory, fp, isDark),
                      const SizedBox(height: 28),
                    ],

                    // Budgets
                    if (fp.budgets.isNotEmpty) ...[
                      _sectionTitle(context, '💰 Budget'),
                      const SizedBox(height: 12),
                      ...fp.budgets.take(3).map((b) => _buildBudgetCard(b, fp, isDark)),
                      const SizedBox(height: 28),
                    ],

                    // Recent Transactions
                    _sectionTitle(context, '⏱ Transaksi Terbaru'),
                    const SizedBox(height: 12),
                    if (recentTxns.isEmpty)
                      _buildEmptyState(context, isDark)
                    else
                      ...recentTxns.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TransactionTile(transaction: t),
                      )),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  Widget _buildHeroHeader(
      BuildContext context, FinanceProvider fp, bool isDark, ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppTheme.heroGradientDark : AppTheme.heroGradientLight,
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40, right: -30,
            child: _decorCircle(160, AppTheme.primaryColor.withOpacity(0.08)),
          ),
          Positioned(
            top: 30, right: 60,
            child: _decorCircle(80, AppTheme.goldColor.withOpacity(0.06)),
          ),
          Positioned(
            bottom: -20, left: -20,
            child: _decorCircle(120, AppTheme.primaryColor.withOpacity(0.05)),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FinanceKu',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.white.withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _greeting(),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const SyncStatusWidget(),
                          const SizedBox(width: 8),
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Balance Display
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
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
                                  color: AppTheme.goldColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: AppTheme.goldColor,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'TOTAL SALDO',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: AppTheme.goldColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _fmt(fp.totalBalance),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${fp.accounts.length} rekening aktif',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi ☀️';
    if (h < 15) return 'Selamat Siang 🌤️';
    if (h < 18) return 'Selamat Sore 🌅';
    return 'Selamat Malam 🌙';
  }

  // ─────────────────────────────────────────────────────────────
  Widget _buildMonthSelector(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardAlt : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _prevMonth,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: AppTheme.primaryColor,
            ),
            splashRadius: 20,
          ),
          Expanded(
            child: Center(
              child: Text(
                _fmtMonth(_selectedMonth),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF1A1040),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.primaryColor,
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  Widget _buildSummaryRow(double income, double expense, bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(
          label: 'Pemasukan',
          value: income,
          icon: Icons.arrow_downward_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF34D399), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          isDark: isDark,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          label: 'Pengeluaran',
          value: expense,
          icon: Icons.arrow_upward_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFFC7070), Color(0xFFDC2626)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          isDark: isDark,
        )),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required double value,
    required IconData icon,
    required LinearGradient gradient,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder.withOpacity(0.5) : AppTheme.lightBorder,
          width: 1,
        ),
        boxShadow: isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _fmt(value),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF1A1040),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  Widget _buildBalanceCard(double balance, bool isDark) {
    final isPos = balance >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPos
              ? [
                  const Color(0xFF34D399).withOpacity(isDark ? 0.12 : 0.08),
                  const Color(0xFF059669).withOpacity(isDark ? 0.05 : 0.04),
                ]
              : [
                  const Color(0xFFFC7070).withOpacity(isDark ? 0.12 : 0.08),
                  const Color(0xFFDC2626).withOpacity(isDark ? 0.05 : 0.04),
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPos
              ? AppTheme.incomeColor.withOpacity(0.25)
              : AppTheme.expenseColor.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: (isPos ? AppTheme.incomeColor : AppTheme.expenseColor).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPos ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: isPos ? AppTheme.incomeColor : AppTheme.expenseColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Selisih Bulan Ini',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: isDark ? const Color(0xFFB0B0D0) : const Color(0xFF6B7280),
            ),
          ),
          const Spacer(),
          Text(
            '${isPos ? '+' : ''}${_fmt(balance)}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: isPos ? AppTheme.incomeColor : AppTheme.expenseColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  Widget _buildPieChart(
      Map<String, double> data, FinanceProvider fp, bool isDark) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();
    final total = top.fold(0.0, (s, e) => s + e.value);
    final colors = [
      AppTheme.primaryColor,
      AppTheme.expenseColor,
      AppTheme.incomeColor,
      AppTheme.goldColor,
      AppTheme.transferColor,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder.withOpacity(0.5) : AppTheme.lightBorder,
          width: 1,
        ),
        boxShadow: isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight,
      ),
      child: Row(
        children: [
          SizedBox(
            height: 160,
            width: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: List.generate(top.length, (i) {
                      final pct = (top[i].value / total) * 100;
                      return PieChartSectionData(
                        value: top[i].value,
                        color: colors[i % colors.length],
                        radius: 38,
                        showTitle: false,
                        borderSide: BorderSide(
                          color: isDark ? AppTheme.darkCard : Colors.white,
                          width: 2,
                        ),
                      );
                    }),
                    centerSpaceRadius: 44,
                    sectionsSpace: 3,
                  ),
                ),
                // Center label
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${top.length}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1040),
                      ),
                    ),
                    Text(
                      'kategori',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(top.length, (i) {
                final cat = fp.categoryById(top[i].key);
                final pct = (top[i].value / total * 100);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
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
                              cat?.name ?? 'Lainnya',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFFD0D0E8) : const Color(0xFF374151),
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
                          value: pct / 100,
                          minHeight: 4,
                          backgroundColor: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                          valueColor: AlwaysStoppedAnimation(colors[i % colors.length]),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  Widget _buildBudgetCard(Budget b, FinanceProvider fp, bool isDark) {
    final cat = fp.categoryById(b.categoryId);
    final isOver = b.isOverBudget;
    final color = isOver ? AppTheme.expenseColor : AppTheme.incomeColor;
    final pct = b.percentage;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOver
              ? AppTheme.expenseColor.withOpacity(0.3)
              : isDark ? AppTheme.darkBorder.withOpacity(0.5) : AppTheme.lightBorder,
          width: 1,
        ),
        boxShadow: isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cat?.name ?? 'Budget',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1A1040),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                _fmt(b.spentAmount),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                ' / ${_fmt(b.limitAmount)}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder.withOpacity(0.5) : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 30,
              color: AppTheme.primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada transaksi',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Transaksi bulan ini akan\nmuncul di sini',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: isDark ? const Color(0xFF5A5A7A) : const Color(0xFFD1D5DB),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  Widget _sectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: isDark ? Colors.white : const Color(0xFF1A1040),
        letterSpacing: 0.1,
      ),
    );
  }
}