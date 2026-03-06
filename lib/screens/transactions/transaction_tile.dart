import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/finance_provider.dart';
import '../../utils/app_theme.dart';
import 'add_transaction_screen.dart';

String _formatCurrency(double amount) =>
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);

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
    final scheme = Theme.of(context).colorScheme;

    Color typeColor;
    IconData typeIcon;
    String sign;

    switch (transaction.type) {
      case TransactionType.income:
        typeColor = AppTheme.incomeColor;
        typeIcon = Icons.arrow_downward_rounded;
        sign = '+';
        break;
      case TransactionType.expense:
        typeColor = AppTheme.expenseColor;
        typeIcon = Icons.arrow_upward_rounded;
        sign = '-';
        break;
      case TransactionType.transfer:
        typeColor = AppTheme.transferColor;
        typeIcon = Icons.swap_horiz_rounded;
        sign = '';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTransactionScreen(transaction: transaction),
          ),
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(typeIcon, color: typeColor, size: 20),
        ),
        title: Text(
          category?.name ?? (transaction.type == TransactionType.transfer ? 'Transfer' : 'Transaksi'),
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.note != null && transaction.note!.isNotEmpty)
              Text(transaction.note!, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            Row(
              children: [
                Text(account?.name ?? '',
                    style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                if (showDate) ...[
                  Text(' · ', style: TextStyle(color: scheme.onSurfaceVariant)),
                  Text(DateFormat('dd MMM', 'id_ID').format(transaction.date),
                      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                ],
              ],
            ),
          ],
        ),
        trailing: Text(
          '$sign${_formatCurrency(transaction.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: typeColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
