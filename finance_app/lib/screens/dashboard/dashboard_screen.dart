import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/finance_provider.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../transactions/transaction_tile.dart';

// Import formatters
import 'package:intl/intl.dart';
String formatCurrency(double amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
String formatMonth(DateTime d) => DateFormat('MMMM yyyy', 'id_ID').format(d);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedMonth = DateTime.now();

  void _prevMonth() => setState(() =>
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
  void _nextMonth() => setState(() =>
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;
    final income = fp.monthlyIncome(_selectedMonth);
    final expense = fp.monthlyExpense(_selectedMonth);
    final balance = income - expense;
    final recentTxns = fp.transactionsForMonth(_selectedMonth).take(5).toList();
    final expByCategory = fp.expensesByCategory(_selectedMonth);

    return Scaffold(
      backgroundColor: scheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.primary.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('FinanceKu',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            Icon(Icons.notifications_rounded,
                                color: Colors.white.withOpacity(0.8)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Total Saldo',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13)),
                        Text(
                          formatCurrency(fp.totalBalance),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                          onPressed: _prevMonth,
                          icon: const Icon(Icons.chevron_left_rounded)),
                      Text(formatMonth(_selectedMonth),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      IconButton(
                          onPressed: _nextMonth,
                          icon: const Icon(Icons.chevron_right_rounded)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Income / Expense / Balance Cards
                  Row(
                    children: [
                      _summaryCard('Pemasukan', income, AppTheme.incomeColor,
                          Icons.arrow_downward_rounded),
                      const SizedBox(width: 10),
                      _summaryCard('Pengeluaran', expense, AppTheme.expenseColor,
                          Icons.arrow_upward_rounded),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _balanceCard(balance, scheme),
                  const SizedBox(height: 20),

                  // Expense by Category Pie Chart
                  if (expByCategory.isNotEmpty) ...[
                    Text('Pengeluaran per Kategori',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _expensePieChart(expByCategory, fp, scheme),
                    const SizedBox(height: 20),
                  ],

                  // Budget Overview
                  if (fp.budgets.isNotEmpty) ...[
                    Text('Budget',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...fp.budgets.take(3).map((b) => _budgetItem(b, fp)),
                    const SizedBox(height: 20),
                  ],

                  // Recent Transactions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Transaksi Terbaru',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (recentTxns.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_rounded,
                                size: 48, color: scheme.onSurfaceVariant.withOpacity(0.4)),
                            const SizedBox(height: 8),
                            Text('Belum ada transaksi bulan ini',
                                style: TextStyle(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...recentTxns.map((t) => TransactionTile(transaction: t)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
      String label, double amount, Color color, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(formatCurrency(amount),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: color),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balanceCard(double balance, ColorScheme scheme) {
    final isPositive = balance >= 0;
    return Card(
      color: isPositive
          ? AppTheme.incomeColor.withOpacity(0.1)
          : AppTheme.expenseColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Selisih Bulan Ini',
                style: TextStyle(fontWeight: FontWeight.w500)),
            Text(
              '${isPositive ? '+' : ''}${formatCurrency(balance)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isPositive ? AppTheme.incomeColor : AppTheme.expenseColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expensePieChart(
      Map<String, double> data, FinanceProvider fp, ColorScheme scheme) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();
    final colors = [
      const Color(0xFFF44336),
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              height: 140,
              width: 140,
              child: PieChart(
                PieChartData(
                  sections: List.generate(top.length, (i) {
                    final total = top.fold(0.0, (s, e) => s + e.value);
                    return PieChartSectionData(
                      value: top[i].value,
                      color: colors[i % colors.length],
                      radius: 45,
                      showTitle: false,
                    );
                  }),
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(top.length, (i) {
                  final cat = fp.categoryById(top[i].key);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: colors[i % colors.length],
                                shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(cat?.name ?? 'Lainnya',
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _budgetItem(Budget b, FinanceProvider fp) {
    final cat = fp.categoryById(b.categoryId);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(cat?.name ?? 'Budget',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '${formatCurrency(b.spentAmount)} / ${formatCurrency(b.limitAmount)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: b.isOverBudget ? Colors.red : Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: b.percentage,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(
                    b.isOverBudget ? Colors.red : Colors.green),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
