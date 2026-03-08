// screens/debt/debt_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});
  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen>
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
        title: const Text('Hutang & Piutang'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _GradientButton(
              label: 'Tambah',
              icon: Icons.add_rounded,
              onTap: () => _showDebtForm(context),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: 'Hutangku (${gd.myDebts.length})'),
            Tab(text: 'Piutangku (${gd.myReceivables.length})'),
          ],
        ),
      ),
      body: gd.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary bar
                if (gd.debts.isNotEmpty)
                  _SummaryBar(gd: gd, isDark: isDark),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _DebtList(debts: gd.myDebts, type: DebtType.debt, isDark: isDark),
                      _DebtList(debts: gd.myReceivables, type: DebtType.receivable, isDark: isDark),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showDebtForm(BuildContext context, {Debt? debt}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DebtFormSheet(debt: debt),
    );
  }
}

// ─── SUMMARY BAR ─────────────────────────────────────────────────────────────
class _SummaryBar extends StatelessWidget {
  final GoalDebtProvider gd;
  final bool isDark;
  const _SummaryBar({required this.gd, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(child: _SummaryCard(
            label: 'Total Hutangku',
            amount: gd.totalDebtOwed,
            color: AppTheme.expenseColor,
            icon: Icons.arrow_upward_rounded,
            isDark: isDark,
          )),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard(
            label: 'Total Piutangku',
            amount: gd.totalReceivable,
            color: AppTheme.incomeColor,
            icon: Icons.arrow_downward_rounded,
            isDark: isDark,
          )),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isDark;
  const _SummaryCard({required this.label, required this.amount,
      required this.color, required this.icon, required this.isDark});

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
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF))),
              Text(_fmtCompact(amount), style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700, fontSize: 13, color: color),
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── DEBT LIST ────────────────────────────────────────────────────────────────
class _DebtList extends StatelessWidget {
  final List<Debt> debts;
  final DebtType type;
  final bool isDark;
  const _DebtList({required this.debts, required this.type, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isDebt = type == DebtType.debt;
    if (debts.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(isDebt ? Icons.money_off_rounded : Icons.handshake_rounded,
                  size: 34, color: AppTheme.primaryColor.withOpacity(0.5)),
            ),
            const SizedBox(height: 14),
            Text(isDebt ? 'Tidak ada hutang aktif' : 'Tidak ada piutang aktif',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF))),
            const SizedBox(height: 4),
            Text(isDebt ? 'Catatan hutangmu di sini' : 'Catatan piutangmu di sini',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                    color: isDark ? const Color(0xFF5A5A7A) : const Color(0xFFD1D5DB))),
          ],
        ),
      ));
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
      children: debts.map((d) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _DebtCard(debt: d, isDark: isDark),
      )).toList(),
    );
  }
}

// ─── DEBT CARD ────────────────────────────────────────────────────────────────
class _DebtCard extends StatelessWidget {
  final Debt debt;
  final bool isDark;
  const _DebtCard({required this.debt, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(debt.color);
    final isDebt = debt.type == DebtType.debt;
    final isPaid = debt.isPaid;
    final isOverdue = debt.isOverdue;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DebtDetailScreen(debt: debt))),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isOverdue ? AppTheme.expenseColor.withOpacity(0.4)
                : isPaid ? AppTheme.incomeColor.withOpacity(0.3)
                : isDark ? AppTheme.darkBorder.withOpacity(0.5) : AppTheme.lightBorder,
            width: isOverdue || isPaid ? 1.5 : 1,
          ),
          boxShadow: isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.3),
                        blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Center(child: Text(
                    debt.personName.isNotEmpty ? debt.personName[0].toUpperCase() : '?',
                    style: const TextStyle(fontFamily: 'Poppins', color: Colors.white,
                        fontSize: 18, fontWeight: FontWeight.w700),
                  )),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(debt.personName,
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF1A1040))),
                      const SizedBox(height: 3),
                      Row(children: [
                        _typeBadge(isDebt, isDark),
                        const SizedBox(width: 6),
                        if (isOverdue) _statusBadge('Jatuh Tempo', AppTheme.expenseColor)
                        else if (isPaid) _statusBadge('Lunas ✓', AppTheme.incomeColor)
                        else if (debt.status == DebtStatus.partiallyPaid)
                          _statusBadge('Sebagian', AppTheme.goldColor)
                        else if (debt.daysUntilDue != null && debt.daysUntilDue! <= 7)
                          _statusBadge('${debt.daysUntilDue} hari lagi', AppTheme.goldColor),
                      ]),
                    ],
                  ),
                ),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_fmtCompact(debt.remaining),
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800,
                            fontSize: 15, color: isDebt ? AppTheme.expenseColor : AppTheme.incomeColor)),
                    Text('sisa', style: TextStyle(fontFamily: 'Poppins', fontSize: 10,
                        color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: debt.percentage,
                minHeight: 7,
                backgroundColor: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                valueColor: AlwaysStoppedAnimation(isPaid ? AppTheme.incomeColor : color),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_fmtCompact(debt.paidAmount)} dibayar',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                        color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF))),
                Text('dari ${_fmtCompact(debt.totalAmount)}',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFB0B0D0) : const Color(0xFF374151))),
              ],
            ),

            if (debt.description != null && debt.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(Icons.notes_rounded, size: 12,
                      color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(debt.description!,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                          color: isDark ? const Color(0xFF9090B8) : const Color(0xFF6B7280)),
                      overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(bool isDebt, bool isDark) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: (isDebt ? AppTheme.expenseColor : AppTheme.incomeColor).withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(isDebt ? 'Hutang' : 'Piutang',
        style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700,
            color: isDebt ? AppTheme.expenseColor : AppTheme.incomeColor)),
  );

  Widget _statusBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(fontFamily: 'Poppins',
        fontSize: 10, fontWeight: FontWeight.w600, color: color)),
  );
}

// ─── DEBT DETAIL SCREEN ───────────────────────────────────────────────────────
class DebtDetailScreen extends StatefulWidget {
  final Debt debt;
  const DebtDetailScreen({super.key, required this.debt});
  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  List<DebtPayment> _payments = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final payments = await context.read<GoalDebtProvider>().getPayments(widget.debt.id);
    if (mounted) setState(() { _payments = payments; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final gd = context.watch<GoalDebtProvider>();
    final debt = gd.debts.firstWhere((d) => d.id == widget.debt.id,
        orElse: () => widget.debt);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = colorFromHex(debt.color);
    final isDebt = debt.type == DebtType.debt;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: Text(debt.personName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => showModalBottomSheet(context: context,
                isScrollControlled: true, backgroundColor: Colors.transparent,
                builder: (_) => DebtFormSheet(debt: debt)).then((_) => _load()),
          ),
          if (!debt.isPaid)
            PopupMenuButton(
              icon: const Icon(Icons.more_vert_rounded),
              itemBuilder: (_) => [
                PopupMenuItem(
                  onTap: () async {
                    await gd.markDebtCancelled(debt.id);
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Row(children: [
                    Icon(Icons.cancel_outlined, color: Colors.orange, size: 18),
                    SizedBox(width: 10),
                    Text('Batalkan'),
                  ]),
                ),
                PopupMenuItem(
                  onTap: () async {
                    await gd.deleteDebt(debt.id);
                    if (mounted) Navigator.pop(context);
                  },
                  child: Row(children: [
                    Icon(Icons.delete_outline_rounded, color: AppTheme.expenseColor, size: 18),
                    const SizedBox(width: 10),
                    Text('Hapus', style: TextStyle(color: AppTheme.expenseColor)),
                  ]),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: !debt.isPaid && debt.status != DebtStatus.cancelled
          ? Container(
              decoration: BoxDecoration(
                gradient: isDebt ? AppTheme.expenseGradient : AppTheme.incomeGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: (isDebt ? AppTheme.expenseColor : AppTheme.incomeColor).withOpacity(0.35),
                    blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Material(color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showAddPayment(context, debt),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.payments_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(isDebt ? 'Bayar Hutang' : 'Terima Bayaran',
                          style: const TextStyle(fontFamily: 'Poppins', color: Colors.white,
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
                _buildHeroCard(debt, color, isDebt, isDark),
                const SizedBox(height: 24),
                _sectionTitle('Riwayat Pembayaran', isDark),
                const SizedBox(height: 12),
                if (_payments.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark
                          ? AppTheme.darkBorder.withOpacity(0.5) : AppTheme.lightBorder),
                    ),
                    child: Column(children: [
                      Icon(Icons.receipt_long_rounded, size: 36,
                          color: (isDark ? const Color(0xFF5A5A7A) : const Color(0xFFD1D5DB))),
                      const SizedBox(height: 8),
                      Text('Belum ada pembayaran', style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 13, color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF))),
                    ]),
                  )
                else
                  ..._payments.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PaymentTile(p: p, isDebt: isDebt, isDark: isDark,
                        onDelete: () async {
                          await gd.deletePayment(p);
                          _load();
                        }),
                  )),
              ],
            ),
    );
  }

  Widget _buildHeroCard(Debt debt, Color color, bool isDebt, bool isDark) {
    final isPaid = debt.isPaid;
    final isOverdue = debt.isOverdue;
    final heroColor = isPaid ? AppTheme.incomeColor
        : isOverdue ? AppTheme.expenseColor : color;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [heroColor, heroColor.withOpacity(0.7)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: heroColor.withOpacity(0.35),
            blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text(
                  debt.personName.isNotEmpty ? debt.personName[0].toUpperCase() : '?',
                  style: const TextStyle(fontFamily: 'Poppins', color: Colors.white,
                      fontSize: 22, fontWeight: FontWeight.w700),
                )),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(debt.personName, style: const TextStyle(fontFamily: 'Poppins',
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  if (debt.personPhone != null)
                    Text(debt.personPhone!, style: TextStyle(fontFamily: 'Poppins',
                        color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(isDebt ? '💸 Hutangku' : '🤝 Piutangku',
                          style: const TextStyle(fontFamily: 'Poppins', color: Colors.white,
                              fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                    if (isPaid) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Text('✅ Lunas',
                            style: TextStyle(fontFamily: 'Poppins', color: Colors.white,
                                fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isDebt ? 'Sisa Hutang' : 'Sisa Piutang',
                  style: TextStyle(fontFamily: 'Poppins',
                      color: Colors.white.withOpacity(0.7), fontSize: 11)),
              Text(_fmt(debt.remaining), style: const TextStyle(fontFamily: 'Poppins',
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -1)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Total', style: TextStyle(fontFamily: 'Poppins',
                  color: Colors.white.withOpacity(0.7), fontSize: 11)),
              Text(_fmt(debt.totalAmount), style: const TextStyle(fontFamily: 'Poppins',
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
          ]),
          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: debt.percentage,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${(debt.percentage * 100).toStringAsFixed(1)}% terbayar',
                style: const TextStyle(fontFamily: 'Poppins', color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 12)),
            if (debt.dueDate != null)
              Text(_dueDateText(debt),
                  style: TextStyle(fontFamily: 'Poppins',
                      color: Colors.white.withOpacity(0.85), fontSize: 11)),
          ]),

          if (debt.description != null && debt.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.notes_rounded, color: Colors.white70, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(debt.description!,
                    style: const TextStyle(fontFamily: 'Poppins',
                        color: Colors.white70, fontSize: 12))),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  String _dueDateText(Debt d) {
    final days = d.daysUntilDue!;
    if (days < 0) return '${days.abs()} hari terlambat!';
    if (days == 0) return 'Jatuh tempo hari ini!';
    return 'Jatuh tempo $days hari lagi';
  }

  Widget _sectionTitle(String t, bool isDark) => Text(t,
      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15,
          color: isDark ? Colors.white : const Color(0xFF1A1040)));

  void _showAddPayment(BuildContext context, Debt debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentForm(debt: debt),
    ).then((_) => _load());
  }
}

// ─── PAYMENT TILE ─────────────────────────────────────────────────────────────
class _PaymentTile extends StatelessWidget {
  final DebtPayment p;
  final bool isDebt;
  final bool isDark;
  final VoidCallback onDelete;
  const _PaymentTile({required this.p, required this.isDebt,
      required this.isDark, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = isDebt ? AppTheme.expenseColor : AppTheme.incomeColor;
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
              color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(isDebt ? Icons.payments_rounded : Icons.account_balance_rounded,
                color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.note?.isNotEmpty == true ? p.note! : (isDebt ? 'Bayar hutang' : 'Terima bayaran'),
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                      fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1A1040))),
              Text(DateFormat('dd MMM yyyy', 'id_ID').format(p.date),
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                      color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF))),
            ]),
          ),
          Text('${isDebt ? '-' : '+'}${_fmt(p.amount)}',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                  color: color, fontSize: 14)),
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

// ─── PAYMENT FORM ─────────────────────────────────────────────────────────────
class _PaymentForm extends StatefulWidget {
  final Debt debt;
  const _PaymentForm({required this.debt});
  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
  final _amtCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amtCtrl.text = widget.debt.remaining.toStringAsFixed(0);
  }

  @override
  void dispose() { _amtCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDebt = widget.debt.type == DebtType.debt;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(left: 20, right: 20, top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.darkBorder,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(isDebt ? 'Bayar Hutang' : 'Terima Bayaran',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1040))),
          Text('kepada/dari: ${widget.debt.personName}',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                  color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF))),
          const SizedBox(height: 4),
          Text('Sisa: ${_fmt(widget.debt.remaining)}',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDebt ? AppTheme.expenseColor : AppTheme.incomeColor)),
          const SizedBox(height: 20),
          TextField(controller: _amtCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah Pembayaran (Rp)',
                  prefixIcon: Icon(Icons.payments_rounded))),
          const SizedBox(height: 12),
          TextField(controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)',
                  prefixIcon: Icon(Icons.note_rounded))),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _date,
                  firstDate: DateTime(2020), lastDate: DateTime(2030));
              if (d != null) setState(() => _date = d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ),
              child: Row(children: [
                Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 10),
                Text(DateFormat('dd MMMM yyyy', 'id_ID').format(_date),
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF1A1040))),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDebt ? AppTheme.expenseColor : AppTheme.incomeColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isDebt ? 'Catat Pembayaran' : 'Catat Penerimaan',
                      style: const TextStyle(fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600, fontSize: 15)),
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
    await context.read<GoalDebtProvider>().addPayment(DebtPayment(
      id: DatabaseService.instance.newId,
      debtId: widget.debt.id,
      amount: amount.clamp(0, widget.debt.remaining),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      date: _date,
      createdAt: DateTime.now(),
    ));
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }
}

// ─── DEBT FORM SHEET ──────────────────────────────────────────────────────────
class DebtFormSheet extends StatefulWidget {
  final Debt? debt;
  const DebtFormSheet({super.key, this.debt});
  @override
  State<DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends State<DebtFormSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DebtType _type = DebtType.debt;
  DateTime? _dueDate;
  String _color = '#FC7070';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.debt != null) {
      _nameCtrl.text = widget.debt!.personName;
      _phoneCtrl.text = widget.debt!.personPhone ?? '';
      _amtCtrl.text = widget.debt!.totalAmount.toStringAsFixed(0);
      _descCtrl.text = widget.debt!.description ?? '';
      _type = widget.debt!.type;
      _dueDate = widget.debt!.dueDate;
      _color = widget.debt!.color;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _amtCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: EdgeInsets.only(left: 20, right: 20, top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: AppTheme.darkBorder,
                    borderRadius: BorderRadius.circular(2)))),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(widget.debt == null ? 'Tambah Catatan' : 'Edit Catatan',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1040))),
              if (widget.debt != null)
                GestureDetector(onTap: _delete,
                    child: Container(width: 36, height: 36,
                        decoration: BoxDecoration(color: AppTheme.expenseColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: AppTheme.expenseColor, size: 18))),
            ]),
            const SizedBox(height: 20),

            // Type selector
            _formLabel('Jenis', isDark),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _TypeButton(
                label: '💸 Hutang', subtitle: 'Saya yang berhutang',
                selected: _type == DebtType.debt,
                activeColor: AppTheme.expenseColor,
                onTap: () => setState(() { _type = DebtType.debt; _color = '#FC7070'; }),
                isDark: isDark,
              )),
              const SizedBox(width: 12),
              Expanded(child: _TypeButton(
                label: '🤝 Piutang', subtitle: 'Orang lain berhutang ke saya',
                selected: _type == DebtType.receivable,
                activeColor: AppTheme.incomeColor,
                onTap: () => setState(() { _type = DebtType.receivable; _color = '#34D399'; }),
                isDark: isDark,
              )),
            ]),
            const SizedBox(height: 16),

            TextField(controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Orang / Lembaga',
                    prefixIcon: Icon(Icons.person_rounded))),
            const SizedBox(height: 12),
            TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'No. HP (opsional)',
                    prefixIcon: Icon(Icons.phone_rounded))),
            const SizedBox(height: 12),
            TextField(controller: _amtCtrl, keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: '${_type == DebtType.debt ? 'Jumlah Hutang' : 'Jumlah Piutang'} (Rp)',
                    prefixIcon: const Icon(Icons.money_rounded))),
            const SizedBox(height: 12),
            TextField(controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Keterangan (opsional)',
                    prefixIcon: Icon(Icons.notes_rounded))),
            const SizedBox(height: 16),

            // Due date
            _formLabel('Jatuh Tempo (opsional)', isDark),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(context: context,
                    initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime(2035));
                if (d != null) setState(() => _dueDate = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _dueDate != null ? AppTheme.primaryColor
                      : isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: Row(children: [
                  Icon(Icons.event_rounded, size: 18,
                      color: _dueDate != null ? AppTheme.primaryColor : Colors.grey),
                  const SizedBox(width: 10),
                  Text(_dueDate != null
                      ? DateFormat('dd MMMM yyyy', 'id_ID').format(_dueDate!)
                      : 'Pilih tanggal jatuh tempo...',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                          color: _dueDate != null
                              ? (isDark ? Colors.white : const Color(0xFF1A1040))
                              : (isDark ? const Color(0xFF5A5A7A) : const Color(0xFFD1D5DB)))),
                  if (_dueDate != null) ...[
                    const Spacer(),
                    GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: Icon(Icons.clear_rounded, size: 16, color: AppTheme.expenseColor)),
                  ],
                ]),
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
                      : Text(widget.debt == null ? 'Simpan Catatan' : 'Simpan Perubahan'),
                )),
          ],
        ),
      ),
    );
  }

  Widget _formLabel(String text, bool isDark) => Text(text,
      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13,
          color: isDark ? const Color(0xFFB0B0D0) : const Color(0xFF374151)));

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final amount = double.tryParse(_amtCtrl.text) ?? 0;
    if (amount <= 0) return;
    setState(() => _saving = true);
    final gd = context.read<GoalDebtProvider>();
    if (widget.debt == null) {
      await gd.addDebt(Debt(
        id: DatabaseService.instance.newId,
        personName: _nameCtrl.text.trim(),
        personPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        type: _type,
        totalAmount: amount,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        dueDate: _dueDate,
        color: _color,
        createdAt: DateTime.now(),
      ));
    } else {
      await gd.updateDebt(widget.debt!.copyWith(
        personName: _nameCtrl.text.trim(),
        personPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        type: _type,
        totalAmount: amount,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        dueDate: _dueDate,
        color: _color,
      ));
    }
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hapus Catatan?'),
          content: const Text('Semua riwayat pembayaran juga akan dihapus.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseColor,
                    foregroundColor: Colors.white),
                child: const Text('Hapus')),
          ],
        ));
    if (confirm == true && mounted) {
      await context.read<GoalDebtProvider>().deleteDebt(widget.debt!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}

// ─── TYPE BUTTON ──────────────────────────────────────────────────────────────
class _TypeButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;
  final bool isDark;
  const _TypeButton({required this.label, required this.subtitle,
      required this.selected, required this.activeColor,
      required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.12)
              : isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? activeColor
                  : isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontFamily: 'Poppins',
                fontWeight: FontWeight.w700, fontSize: 13,
                color: selected ? activeColor
                    : isDark ? Colors.white : const Color(0xFF1A1040))),
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(fontFamily: 'Poppins', fontSize: 10,
                color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF))),
          ],
        ),
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