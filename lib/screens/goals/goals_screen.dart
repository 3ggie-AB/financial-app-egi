// screens/goals/goals_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/goal_debt_models.dart';
import '../../providers/goal_debt_provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/color_picker_widget.dart';

String _fmt(double v) =>
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);
String _fmtCompact(double v) {
  if (v >= 1000000000) return 'Rp ${(v / 1000000000).toStringAsFixed(1)}M';
  if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}jt';
  if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}rb';
  return 'Rp ${v.toStringAsFixed(0)}';
}

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});
  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoalDebtProvider>().loadAll();
    });
  }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final gd = context.watch<GoalDebtProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: const Text('Target Keuangan'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _GradientButton(
              label: 'Tambah',
              icon: Icons.add_rounded,
              onTap: () => _showGoalForm(context),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: 'Aktif (${gd.activeGoals.length})'),
            Tab(text: 'Selesai (${gd.completedGoals.length})'),
          ],
        ),
      ),
      body: gd.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _GoalList(goals: gd.activeGoals, isDark: isDark, isCompleted: false),
                _GoalList(goals: gd.completedGoals, isDark: isDark, isCompleted: true),
              ],
            ),
    );
  }

  void _showGoalForm(BuildContext context, {FinancialGoal? goal}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GoalFormSheet(goal: goal),
    );
  }
}

// ─── GOAL LIST ────────────────────────────────────────────────────────────────
class _GoalList extends StatelessWidget {
  final List<FinancialGoal> goals;
  final bool isDark;
  final bool isCompleted;
  const _GoalList({required this.goals, required this.isDark, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return _EmptyState(
        icon: isCompleted ? Icons.emoji_events_rounded : Icons.flag_rounded,
        title: isCompleted ? 'Belum ada target selesai' : 'Belum ada target',
        subtitle: isCompleted
            ? 'Target yang tercapai akan muncul di sini'
            : 'Buat target keuangan pertamamu!',
        isDark: isDark,
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        if (!isCompleted && goals.isNotEmpty) ...[
          _buildSummaryCard(context, goals, isDark),
          const SizedBox(height: 20),
        ],
        ...goals.map((g) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _GoalCard(goal: g, isDark: isDark),
        )),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<FinancialGoal> goals, bool isDark) {
    final totalSaved = goals.fold(0.0, (s, g) => s + g.savedAmount);
    final totalTarget = goals.fold(0.0, (s, g) => s + g.targetAmount);
    final overallPct = totalTarget > 0 ? totalSaved / totalTarget : 0.0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(colors: [Color(0xFF1A0A3E), Color(0xFF0F0F28)],
                begin: Alignment.topLeft, end: Alignment.bottomRight)
            : AppTheme.heroGradientLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.25),
            blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.goldColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_rounded, color: AppTheme.goldColor, size: 11),
                    const SizedBox(width: 5),
                    Text('${goals.length} TARGET AKTIF',
                        style: TextStyle(fontFamily: 'Poppins', color: AppTheme.goldColor,
                            fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Total Tabungan', style: TextStyle(fontFamily: 'Poppins',
              color: Colors.white.withOpacity(0.6), fontSize: 12)),
          const SizedBox(height: 4),
          Text(_fmtCompact(totalSaved),
              style: const TextStyle(fontFamily: 'Poppins', color: Colors.white,
                  fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1)),
          Text('dari ${_fmtCompact(totalTarget)}',
              style: TextStyle(fontFamily: 'Poppins',
                  color: Colors.white.withOpacity(0.5), fontSize: 12)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: overallPct.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(AppTheme.goldColor),
            ),
          ),
          const SizedBox(height: 6),
          Text('${(overallPct * 100).toStringAsFixed(1)}% keseluruhan tercapai',
              style: TextStyle(fontFamily: 'Poppins',
                  color: AppTheme.goldColor, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── GOAL CARD ────────────────────────────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final FinancialGoal goal;
  final bool isDark;
  const _GoalCard({required this.goal, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(goal.color);
    final isOver = goal.isCompleted;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isOver
                ? AppTheme.goldColor.withOpacity(0.4)
                : isDark ? AppTheme.darkBorder.withOpacity(0.5) : AppTheme.lightBorder,
            width: isOver ? 1.5 : 1,
          ),
          boxShadow: isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Category icon
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.25), width: 1),
                  ),
                  child: Center(child: Text(_categoryEmoji(goal.category),
                      style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(goal.name,
                                style: TextStyle(fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700, fontSize: 14,
                                    color: isDark ? Colors.white : const Color(0xFF1A1040)),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (isOver)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.goldColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.goldColor.withOpacity(0.3)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Text('🏆', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 4),
                                Text('Selesai!', style: TextStyle(fontFamily: 'Poppins',
                                    color: AppTheme.goldColor, fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                              ]),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _categoryBadge(goal.category, isDark),
                          if (goal.daysRemaining != null) ...[
                            const SizedBox(width: 6),
                            _daysBadge(goal.daysRemaining!, isDark),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmtCompact(goal.savedAmount),
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                        fontSize: 16, color: color)),
                Text('/ ${_fmtCompact(goal.targetAmount)}',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                        color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF))),
              ],
            ),
            const SizedBox(height: 10),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.percentage,
                minHeight: 10,
                backgroundColor: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                valueColor: AlwaysStoppedAnimation(isOver ? AppTheme.goldColor : color),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(goal.percentage * 100).toStringAsFixed(1)}% tercapai',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                        fontWeight: FontWeight.w600, color: isOver ? AppTheme.goldColor : color)),
                if (!isOver)
                  Text('Sisa ${_fmtCompact(goal.remaining)}',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                          color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)));
  }

  Widget _categoryBadge(GoalCategory cat, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(_categoryLabel(cat),
          style: TextStyle(fontFamily: 'Poppins', fontSize: 10,
              color: isDark ? const Color(0xFF9090B8) : const Color(0xFF6B7280))),
    );
  }

  Widget _daysBadge(int days, bool isDark) {
    final isUrgent = days <= 30 && days >= 0;
    final isOverdue = days < 0;
    Color badgeColor = isOverdue
        ? AppTheme.expenseColor
        : isUrgent ? AppTheme.goldColor : AppTheme.transferColor;
    String label = isOverdue
        ? '${days.abs()}h terlambat'
        : days == 0 ? 'Hari ini!'
        : '$days hari lagi';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 10,
              fontWeight: FontWeight.w600, color: badgeColor)),
    );
  }

  String _categoryEmoji(GoalCategory c) => switch (c) {
        GoalCategory.emergency => '🛡️',
        GoalCategory.vehicle => '🚗',
        GoalCategory.property => '🏠',
        GoalCategory.vacation => '✈️',
        GoalCategory.education => '📚',
        GoalCategory.gadget => '📱',
        GoalCategory.wedding => '💍',
        GoalCategory.health => '🏥',
        GoalCategory.investment => '📈',
        GoalCategory.other => '🎯',
      };

  String _categoryLabel(GoalCategory c) => switch (c) {
        GoalCategory.emergency => 'Dana Darurat',
        GoalCategory.vehicle => 'Kendaraan',
        GoalCategory.property => 'Properti',
        GoalCategory.vacation => 'Liburan',
        GoalCategory.education => 'Pendidikan',
        GoalCategory.gadget => 'Gadget',
        GoalCategory.wedding => 'Pernikahan',
        GoalCategory.health => 'Kesehatan',
        GoalCategory.investment => 'Investasi',
        GoalCategory.other => 'Lainnya',
      };
}

// ─── GOAL DETAIL SCREEN ───────────────────────────────────────────────────────
class GoalDetailScreen extends StatefulWidget {
  final FinancialGoal goal;
  const GoalDetailScreen({super.key, required this.goal});
  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  List<GoalContribution> _contributions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final gd = context.read<GoalDebtProvider>();
    final contributions = await gd.getContributions(widget.goal.id);
    if (mounted) setState(() { _contributions = contributions; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final gd = context.watch<GoalDebtProvider>();
    final goal = gd.goals.firstWhere((g) => g.id == widget.goal.id,
        orElse: () => widget.goal);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = colorFromHex(goal.color);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => GoalFormSheet(goal: goal),
            ).then((_) => _load()),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: AppTheme.expenseColor),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      floatingActionButton: goal.status == GoalStatus.active
          ? Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.primaryShadow,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showAddContribution(context, goal),
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Tambah Tabungan',
                          style: TextStyle(fontFamily: 'Poppins', color: Colors.white,
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ]),
                  ),
                ),
              ),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                // Hero card
                _buildHeroCard(goal, color, isDark),
                const SizedBox(height: 24),

                // Chart
                if (_contributions.length > 1) ...[
                  _buildProgressChart(goal, _contributions, isDark),
                  const SizedBox(height: 24),
                ],

                // Riwayat setoran
                _sectionTitle('Riwayat Setoran', isDark),
                const SizedBox(height: 12),
                if (_contributions.isEmpty)
                  _EmptyState(
                    icon: Icons.savings_rounded,
                    title: 'Belum ada setoran',
                    subtitle: 'Mulai tabung sekarang!',
                    isDark: isDark,
                    compact: true,
                  )
                else
                  ..._contributions.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ContributionTile(c: c, color: color, isDark: isDark,
                        onDelete: () async {
                          await context.read<GoalDebtProvider>().deleteContribution(c);
                          _load();
                        }),
                  )),
              ],
            ),
    );
  }

  Widget _buildHeroCard(FinancialGoal goal, Color color, bool isDark) {
    final isCompleted = goal.isCompleted;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [const Color(0xFFE8C44A), const Color(0xFFB8962A)]
              : [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
            color: (isCompleted ? AppTheme.goldColor : color).withOpacity(0.35),
            blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_categoryEmoji(goal.category), style: const TextStyle(fontSize: 32)),
              const Spacer(),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('🏆 Selesai!',
                      style: TextStyle(fontFamily: 'Poppins', color: Colors.white,
                          fontWeight: FontWeight.w700, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(goal.name, style: const TextStyle(fontFamily: 'Poppins', color: Colors.white,
              fontSize: 20, fontWeight: FontWeight.w700)),
          if (goal.description != null && goal.description!.isNotEmpty)
            Text(goal.description!, style: TextStyle(fontFamily: 'Poppins',
                color: Colors.white.withOpacity(0.7), fontSize: 12)),
          const SizedBox(height: 18),

          // Progress
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Terkumpul', style: TextStyle(fontFamily: 'Poppins',
                  color: Colors.white.withOpacity(0.7), fontSize: 11)),
              Text(_fmt(goal.savedAmount), style: const TextStyle(fontFamily: 'Poppins',
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Target', style: TextStyle(fontFamily: 'Poppins',
                  color: Colors.white.withOpacity(0.7), fontSize: 11)),
              Text(_fmt(goal.targetAmount), style: const TextStyle(fontFamily: 'Poppins',
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            ]),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goal.percentage,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${(goal.percentage * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontFamily: 'Poppins', color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 13)),
            if (!isCompleted && goal.targetDate != null)
              Text(_deadlineText(goal),
                  style: TextStyle(fontFamily: 'Poppins',
                      color: Colors.white.withOpacity(0.8), fontSize: 11)),
          ]),
        ],
      ),
    );
  }

  Widget _buildProgressChart(FinancialGoal goal, List<GoalContribution> contribs, bool isDark) {
    // Sort by date ascending
    final sorted = [...contribs]..sort((a, b) => a.date.compareTo(b.date));
    double running = 0;
    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      running += sorted[i].amount;
      spots.add(FlSpot(i.toDouble(), running));
    }

    final color = colorFromHex(goal.color);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder.withOpacity(0.5) : AppTheme.lightBorder),
        boxShadow: isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Grafik Tabungan', style: TextStyle(fontFamily: 'Poppins',
              fontWeight: FontWeight.w700, fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF1A1040))),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: goal.targetAmount / 4,
                getDrawingHorizontalLine: (v) => FlLine(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 56,
                  getTitlesWidget: (v, _) => Text(_fmtCompact(v),
                      style: TextStyle(fontSize: 9,
                          color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF))),
                )),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: color,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3, color: color, strokeWidth: 1.5,
                        strokeColor: isDark ? AppTheme.darkCard : Colors.white),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.25), color.withOpacity(0.02)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Target line
                LineChartBarData(
                  spots: [FlSpot(0, goal.targetAmount),
                      FlSpot(spots.length - 1.0, goal.targetAmount)],
                  isCurved: false,
                  color: AppTheme.goldColor.withOpacity(0.6),
                  barWidth: 1.5,
                  dotData: const FlDotData(show: false),
                  dashArray: [6, 3],
                ),
              ],
              minY: 0,
              maxY: goal.targetAmount * 1.05,
            )),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legend(color, 'Tabungan'),
            const SizedBox(width: 16),
            _legend(AppTheme.goldColor.withOpacity(0.6), 'Target'),
          ]),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 3, decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 10,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF9090B8) : const Color(0xFF6B7280))),
      ]);

  String _deadlineText(FinancialGoal goal) {
    if (goal.targetDate == null) return '';
    final days = goal.daysRemaining!;
    if (days < 0) return '${days.abs()} hari terlambat';
    if (days == 0) return 'Deadline hari ini';
    return '$days hari lagi';
  }

  String _categoryEmoji(GoalCategory c) => switch (c) {
        GoalCategory.emergency => '🛡️', GoalCategory.vehicle => '🚗',
        GoalCategory.property => '🏠', GoalCategory.vacation => '✈️',
        GoalCategory.education => '📚', GoalCategory.gadget => '📱',
        GoalCategory.wedding => '💍', GoalCategory.health => '🏥',
        GoalCategory.investment => '📈', GoalCategory.other => '🎯',
      };

  Widget _sectionTitle(String t, bool isDark) => Text(t,
      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
          fontSize: 15, color: isDark ? Colors.white : const Color(0xFF1A1040)));

  void _showAddContribution(BuildContext context, FinancialGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContributionForm(goal: goal),
    ).then((_) => _load());
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Target?'),
        content: const Text('Semua riwayat setoran juga akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseColor,
                  foregroundColor: Colors.white),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<GoalDebtProvider>().deleteGoal(widget.goal.id);
      if (mounted) Navigator.pop(context);
    }
  }
}

// ─── CONTRIBUTION TILE ───────────────────────────────────────────────────────
class _ContributionTile extends StatelessWidget {
  final GoalContribution c;
  final Color color;
  final bool isDark;
  final VoidCallback onDelete;
  const _ContributionTile({required this.c, required this.color,
      required this.isDark, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder.withOpacity(0.5) : AppTheme.lightBorder),
        boxShadow: isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight,
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.incomeGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppTheme.incomeColor.withOpacity(0.3),
                  blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.savings_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.note?.isNotEmpty == true ? c.note! : 'Setoran',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                        fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1A1040))),
                Text(DateFormat('dd MMM yyyy', 'id_ID').format(c.date),
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                        color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF))),
              ],
            ),
          ),
          Text('+${_fmt(c.amount)}', style: TextStyle(fontFamily: 'Poppins',
              fontWeight: FontWeight.w700, color: AppTheme.incomeColor, fontSize: 14)),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: AppTheme.expenseColor, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─── CONTRIBUTION FORM ───────────────────────────────────────────────────────
class _ContributionForm extends StatefulWidget {
  final FinancialGoal goal;
  const _ContributionForm({required this.goal});
  @override
  State<_ContributionForm> createState() => _ContributionFormState();
}

class _ContributionFormState extends State<_ContributionForm> {
  final _amtCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() { _amtCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
          left: 20, right: 20, top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.darkBorder,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Tambah Setoran', style: TextStyle(fontFamily: 'Poppins',
              fontSize: 18, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1040))),
          const SizedBox(height: 4),
          Text('Target: ${widget.goal.name}',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                  color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF))),
          const SizedBox(height: 20),
          TextField(controller: _amtCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah Setoran (Rp)',
                  prefixIcon: Icon(Icons.savings_rounded))),
          const SizedBox(height: 12),
          TextField(controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)',
                  prefixIcon: Icon(Icons.note_rounded))),
          const SizedBox(height: 12),
          // Date
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(context: context,
                  initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2030));
              if (d != null) setState(() => _date = d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 10),
                  Text(DateFormat('dd MMMM yyyy', 'id_ID').format(_date),
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF1A1040))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan Setoran'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amtCtrl.text) ?? 0;
    if (amount <= 0) return;
    setState(() => _saving = true);
    await context.read<GoalDebtProvider>().addContribution(GoalContribution(
      id: DatabaseService.instance.newId,
      goalId: widget.goal.id,
      amount: amount,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      date: _date,
      createdAt: DateTime.now(),
    ));
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }
}

// ─── GOAL FORM SHEET ─────────────────────────────────────────────────────────
class GoalFormSheet extends StatefulWidget {
  final FinancialGoal? goal;
  const GoalFormSheet({super.key, this.goal});
  @override
  State<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<GoalFormSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  GoalCategory _category = GoalCategory.other;
  DateTime? _targetDate;
  String _color = '#7C6AF7';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameCtrl.text = widget.goal!.name;
      _descCtrl.text = widget.goal!.description ?? '';
      _targetCtrl.text = widget.goal!.targetAmount.toStringAsFixed(0);
      _category = widget.goal!.category;
      _targetDate = widget.goal!.targetDate;
      _color = widget.goal!.color;
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); _targetCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: EdgeInsets.only(left: 20, right: 20, top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: AppTheme.darkBorder,
                    borderRadius: BorderRadius.circular(2)))),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(widget.goal == null ? 'Buat Target Baru' : 'Edit Target',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1040))),
              if (widget.goal != null)
                GestureDetector(onTap: _delete,
                    child: Container(width: 36, height: 36,
                        decoration: BoxDecoration(
                            color: AppTheme.expenseColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: AppTheme.expenseColor, size: 18))),
            ]),
            const SizedBox(height: 20),
            TextField(controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Target',
                    prefixIcon: Icon(Icons.flag_rounded))),
            const SizedBox(height: 12),
            TextField(controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Deskripsi (opsional)',
                    prefixIcon: Icon(Icons.notes_rounded))),
            const SizedBox(height: 12),
            TextField(controller: _targetCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target Jumlah (Rp)',
                    prefixIcon: Icon(Icons.money_rounded))),
            const SizedBox(height: 16),
            _formLabel('Kategori', isDark),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8,
                children: GoalCategory.values.map((c) {
                  final isSelected = _category == c;
                  return GestureDetector(
                    onTap: () => setState(() => _category = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withOpacity(0.15)
                            : isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isSelected ? AppTheme.primaryColor
                                : isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                            width: isSelected ? 1.5 : 1),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(_catEmoji(c), style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(_catLabel(c), style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 12, fontWeight: FontWeight.w500,
                            color: isSelected ? AppTheme.primaryColor
                                : isDark ? const Color(0xFFB0B0D0) : const Color(0xFF374151))),
                      ]),
                    ),
                  );
                }).toList()),
            const SizedBox(height: 16),
            // Target date
            _formLabel('Target Tanggal (opsional)', isDark),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(context: context,
                    initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035));
                if (d != null) setState(() => _targetDate = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _targetDate != null
                      ? AppTheme.primaryColor : isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_rounded, size: 18,
                        color: _targetDate != null ? AppTheme.primaryColor : Colors.grey),
                    const SizedBox(width: 10),
                    Text(_targetDate != null
                        ? DateFormat('dd MMMM yyyy', 'id_ID').format(_targetDate!)
                        : 'Pilih tanggal target...',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                            color: _targetDate != null
                                ? (isDark ? Colors.white : const Color(0xFF1A1040))
                                : (isDark ? const Color(0xFF5A5A7A) : const Color(0xFFD1D5DB)))),
                    if (_targetDate != null) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _targetDate = null),
                        child: Icon(Icons.clear_rounded, size: 16, color: AppTheme.expenseColor),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _formLabel('Warna', isDark),
            const SizedBox(height: 10),
            ColorPickerWidget(selectedColor: _color,
                onColorChanged: (c) => setState(() => _color = c)),
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(widget.goal == null ? 'Buat Target' : 'Simpan Perubahan'),
                )),
          ],
        ),
      ),
    );
  }

  Widget _formLabel(String text, bool isDark) => Text(text,
      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13,
          color: isDark ? const Color(0xFFB0B0D0) : const Color(0xFF374151)));

  String _catEmoji(GoalCategory c) => switch (c) {
        GoalCategory.emergency => '🛡️', GoalCategory.vehicle => '🚗',
        GoalCategory.property => '🏠', GoalCategory.vacation => '✈️',
        GoalCategory.education => '📚', GoalCategory.gadget => '📱',
        GoalCategory.wedding => '💍', GoalCategory.health => '🏥',
        GoalCategory.investment => '📈', GoalCategory.other => '🎯',
      };
  String _catLabel(GoalCategory c) => switch (c) {
        GoalCategory.emergency => 'Dana Darurat', GoalCategory.vehicle => 'Kendaraan',
        GoalCategory.property => 'Properti', GoalCategory.vacation => 'Liburan',
        GoalCategory.education => 'Pendidikan', GoalCategory.gadget => 'Gadget',
        GoalCategory.wedding => 'Pernikahan', GoalCategory.health => 'Kesehatan',
        GoalCategory.investment => 'Investasi', GoalCategory.other => 'Lainnya',
      };

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final target = double.tryParse(_targetCtrl.text) ?? 0;
    if (target <= 0) return;
    setState(() => _saving = true);
    final gd = context.read<GoalDebtProvider>();
    if (widget.goal == null) {
      await gd.addGoal(FinancialGoal(
        id: DatabaseService.instance.newId,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        category: _category,
        targetAmount: target,
        targetDate: _targetDate,
        color: _color,
        createdAt: DateTime.now(),
      ));
    } else {
      await gd.updateGoal(widget.goal!.copyWith(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        category: _category,
        targetAmount: target,
        targetDate: _targetDate,
        color: _color,
      ));
    }
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Target?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseColor,
                  foregroundColor: Colors.white),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<GoalDebtProvider>().deleteGoal(widget.goal!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}

// ─── SHARED HELPERS ───────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final bool compact;
  const _EmptyState({required this.icon, required this.title,
      required this.subtitle, required this.isDark, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 20 : 40),
      decoration: compact ? BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder.withOpacity(0.5) : AppTheme.lightBorder),
      ) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 52 : 72, height: compact ? 52 : 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: compact ? 26 : 34,
                color: AppTheme.primaryColor.withOpacity(0.5)),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(title, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600,
              fontSize: compact ? 13 : 15,
              color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF))),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins', fontSize: compact ? 11 : 12,
                  color: isDark ? const Color(0xFF5A5A7A) : const Color(0xFFD1D5DB))),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.primaryShadow),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontFamily: 'Poppins',
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}