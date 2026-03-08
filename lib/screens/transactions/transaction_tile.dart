// screens/transactions/transaction_tile.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/finance_provider.dart';
import '../../utils/app_theme.dart';
import 'add_transaction_screen.dart';

String _fmt(double amount) =>
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(amount);

class TransactionTile extends StatelessWidget {
  final AppTransaction transaction;
  final bool showDate;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final fp = context.read<FinanceProvider>();
    final category = fp.categoryById(transaction.categoryId);
    final account = fp.accountById(transaction.accountId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color typeColor;
    IconData typeIcon;
    String sign;
    List<Color> gradColors;

    switch (transaction.type) {
      case TransactionType.income:
        typeColor = AppTheme.incomeColor;
        typeIcon = Icons.arrow_downward_rounded;
        sign = '+';
        gradColors = [AppTheme.incomeColor, const Color(0xFF059669)];
        break;
      case TransactionType.expense:
        typeColor = AppTheme.expenseColor;
        typeIcon = Icons.arrow_upward_rounded;
        sign = '-';
        gradColors = [AppTheme.expenseColor, const Color(0xFFDC2626)];
        break;
      case TransactionType.transfer:
        typeColor = AppTheme.transferColor;
        typeIcon = Icons.swap_horiz_rounded;
        sign = '';
        gradColors = [AppTheme.transferColor, const Color(0xFF1D6FAE)];
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTransactionScreen(transaction: transaction),
          ),
        ),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? AppTheme.darkBorder.withOpacity(0.5)
                  : AppTheme.lightBorder,
              width: 1,
            ),
            boxShadow:
                isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight,
          ),
          child: Row(
            children: [
              // Icon container with gradient
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: gradColors.first.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(typeIcon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ??
                          (transaction.type == TransactionType.transfer
                              ? 'Transfer'
                              : 'Transaksi'),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF1A1040),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (account != null) ...[
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 10,
                            color: isDark
                                ? const Color(0xFF5A5A7A)
                                : const Color(0xFFD1D5DB),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            account.name,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF7878A0)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                        if (showDate) ...[
                          Text(
                            account != null ? ' · ' : '',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF5A5A7A)
                                  : const Color(0xFFD1D5DB),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM', 'id_ID')
                                .format(transaction.date),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF7878A0)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (transaction.note != null &&
                        transaction.note!.isNotEmpty &&
                        !transaction.note!.contains('__crypto')) ...[
                      const SizedBox(height: 3),
                      Text(
                        transaction.note!,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF6060A0)
                              : const Color(0xFFB0B8CC),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sign${_fmt(transaction.amount)}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: typeColor,
                      fontSize: 13,
                    ),
                  ),
                  if (transaction.recurring != RecurringPeriod.none)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.repeat_rounded,
                            size: 9,
                            color: AppTheme.primaryColor.withOpacity(0.8),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Rutin',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}