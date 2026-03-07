import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';

class FinanceProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;
  final _backup = BackupService.instance;
  final _notif = NotificationService.instance;

  List<Account> _accounts = [];
  List<AppCategory> _categories = [];
  List<Tag> _tags = [];
  List<AppTransaction> _transactions = [];
  List<Budget> _budgets = [];
  bool _isLoading = false;

  List<Account> get accounts => _accounts.where((a) => a.isActive).toList();
  List<Account> get allAccounts => _accounts;
  List<AppCategory> get categories => _categories;
  List<AppCategory> get expenseCategories =>
      _categories.where((c) => c.type == TransactionType.expense).toList();
  List<AppCategory> get incomeCategories =>
      _categories.where((c) => c.type == TransactionType.income).toList();
  List<Tag> get tags => _tags;
  List<AppTransaction> get transactions => _transactions;
  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;

  double get totalBalance => _accounts
      .where((a) => a.isActive && a.type != 'credit')
      .fold(0, (sum, a) => sum + a.balance);

  double monthlyIncome(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return _transactions
        .where((t) => t.type == TransactionType.income &&
            t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(end.add(const Duration(seconds: 1))))
        .fold(0, (sum, t) => sum + t.amount);
  }

  double monthlyExpense(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return _transactions
        .where((t) => t.type == TransactionType.expense &&
            t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(end.add(const Duration(seconds: 1))))
        .fold(0, (sum, t) => sum + t.amount);
  }

  List<AppTransaction> transactionsForMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return _transactions
        .where((t) =>
            t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(end.add(const Duration(seconds: 1))))
        .toList();
  }

  Map<String, double> expensesByCategory(DateTime month) {
    final txns = transactionsForMonth(month)
        .where((t) => t.type == TransactionType.expense);
    final Map<String, double> result = {};
    for (final t in txns) {
      result[t.categoryId] = (result[t.categoryId] ?? 0) + t.amount;
    }
    return result;
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    _accounts = await _db.getAccounts();
    _categories = await _db.getCategories();
    _tags = await _db.getTags();
    _transactions = await _db.getTransactions();
    _budgets = await _db.getBudgets();
    await _recalcBudgets();
    _isLoading = false;
    notifyListeners();
  }

  void _autoSync() => _backup.triggerAutoSync();

  // ─── NOTIFIKASI ───────────────────────────────────────────────
  Future<void> _checkBudgetNotifications() async {
    final budgetData = _budgets.where((b) => b.isActive).map((b) {
      final cat = categoryById(b.categoryId);
      return {
        'name': cat?.name ?? 'Budget',
        'spent': b.spentAmount,
        'limit': b.limitAmount,
        'percentage': b.percentage,
      };
    }).toList();
    if (budgetData.isNotEmpty) {
      await _notif.checkAndNotifyBudgets(budgets: budgetData);
    }
  }

  Future<void> checkTodayTransactionReminder() async {
    final now = DateTime.now();
    final todayExpenses = _transactions.where((t) =>
        t.type == TransactionType.expense &&
        t.date.year == now.year &&
        t.date.month == now.month &&
        t.date.day == now.day).toList();
    if (todayExpenses.isNotEmpty) {
      await _notif.cancelTodayReminderIfHasTransaction();
    }
  }

  Future<void> sendDailySummary() async {
    final now = DateTime.now();
    final todayTxns = _transactions.where((t) =>
        t.date.year == now.year &&
        t.date.month == now.month &&
        t.date.day == now.day).toList();
    final expense = todayTxns
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final income = todayTxns
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    await _notif.sendDailySummaryNow(
      todayExpense: expense,
      todayIncome: income,
      txnCount: todayTxns.length,
    );
  }

  Future<void> sendWeeklySummary() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekTxns = _transactions.where((t) =>
        t.date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
        t.date.isBefore(now.add(const Duration(seconds: 1)))).toList();
    final expense = weekTxns
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final income = weekTxns
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final catMap = <String, double>{};
    for (final t in weekTxns.where((t) => t.type == TransactionType.expense)) {
      catMap[t.categoryId] = (catMap[t.categoryId] ?? 0) + t.amount;
    }
    String topCat = 'N/A';
    if (catMap.isNotEmpty) {
      final topId = catMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      topCat = categoryById(topId)?.name ?? 'Lainnya';
    }
    await _notif.sendWeeklySummaryNow(
      weekExpense: expense,
      weekIncome: income,
      txnCount: weekTxns.length,
      topCategory: topCat,
    );
  }

  Future<void> sendMonthlySummary() async {
    final now = DateTime.now();
    final expense = monthlyExpense(now);
    final income = monthlyIncome(now);
    final txnCount = transactionsForMonth(now).length;
    final monthName = DateFormat('MMMM yyyy', 'id_ID').format(now);
    await _notif.sendMonthlySummaryNow(
      monthExpense: expense,
      monthIncome: income,
      monthName: monthName,
      txnCount: txnCount,
    );
  }

  // ─── ACCOUNTS ─────────────────────────────────────────────────
  Future<void> addAccount(Account a) async {
    await _db.insertAccount(a);
    _accounts = await _db.getAccounts();
    notifyListeners();
    _autoSync();
  }

  Future<void> updateAccount(Account a) async {
    await _db.updateAccount(a);
    _accounts = await _db.getAccounts();
    notifyListeners();
    _autoSync();
  }

  Future<void> deleteAccount(String id) async {
    await _db.deleteAccount(id);
    _accounts = await _db.getAccounts();
    notifyListeners();
    _autoSync();
  }

  // ─── CATEGORIES ───────────────────────────────────────────────
  Future<void> addCategory(AppCategory c) async {
    await _db.insertCategory(c);
    _categories = await _db.getCategories();
    notifyListeners();
    _autoSync();
  }

  Future<void> updateCategory(AppCategory c) async {
    await _db.updateCategory(c);
    _categories = await _db.getCategories();
    notifyListeners();
    _autoSync();
  }

  Future<void> deleteCategory(String id) async {
    await _db.deleteCategory(id);
    _categories = await _db.getCategories();
    notifyListeners();
    _autoSync();
  }

  // ─── TAGS ─────────────────────────────────────────────────────
  Future<void> addTag(Tag t) async {
    await _db.insertTag(t);
    _tags = await _db.getTags();
    notifyListeners();
    _autoSync();
  }

  Future<void> updateTag(Tag t) async {
    await _db.updateTag(t);
    _tags = await _db.getTags();
    notifyListeners();
    _autoSync();
  }

  Future<void> deleteTag(String id) async {
    await _db.deleteTag(id);
    _tags = await _db.getTags();
    notifyListeners();
    _autoSync();
  }

  // ─── TRANSACTIONS ─────────────────────────────────────────────
  Future<void> addTransaction(AppTransaction t) async {
    await _db.insertTransaction(t);
    _transactions = await _db.getTransactions();
    _accounts = await _db.getAccounts();
    await _recalcBudgets();
    notifyListeners();
    _autoSync();
    if (t.type == TransactionType.expense) {
      await _checkBudgetNotifications();
      await checkTodayTransactionReminder();
    }
  }

  Future<void> updateTransaction(AppTransaction oldT, AppTransaction newT) async {
    await _db.updateTransaction(oldT, newT);
    _transactions = await _db.getTransactions();
    _accounts = await _db.getAccounts();
    await _recalcBudgets();
    notifyListeners();
    _autoSync();
    await _checkBudgetNotifications();
  }

  Future<void> deleteTransaction(AppTransaction t) async {
    await _db.deleteTransaction(t);
    _transactions = await _db.getTransactions();
    _accounts = await _db.getAccounts();
    await _recalcBudgets();
    notifyListeners();
    _autoSync();
  }

  // ─── BUDGETS ──────────────────────────────────────────────────
  Future<void> addBudget(Budget b) async {
    await _db.insertBudget(b);
    _budgets = await _db.getBudgets();
    await _recalcBudgets();
    notifyListeners();
    _autoSync();
    await _checkBudgetNotifications();
  }

  Future<void> deleteBudget(String id) async {
    await _db.deleteBudget(id);
    _budgets = await _db.getBudgets();
    notifyListeners();
    _autoSync();
  }

  // ─── DELETE ALL ───────────────────────────────────────────────
  Future<void> deleteAllData() async {
    _isLoading = true;
    notifyListeners();
    await _db.deleteAllData();
    await loadAll();
    _autoSync();
  }

  // ─── RECALC BUDGETS ───────────────────────────────────────────
  Future<void> _recalcBudgets() async {
    for (int i = 0; i < _budgets.length; i++) {
      final b = _budgets[i];
      if (!b.isActive) continue;
      final spent = _transactions
          .where((t) => t.type == TransactionType.expense &&
              t.categoryId == b.categoryId &&
              t.date.isAfter(b.startDate) &&
              t.date.isBefore(b.endDate))
          .fold(0.0, (sum, t) => sum + t.amount);
      final updated = Budget(
        id: b.id, categoryId: b.categoryId, limitAmount: b.limitAmount,
        spentAmount: spent, startDate: b.startDate, endDate: b.endDate,
        isActive: b.isActive,
      );
      _budgets[i] = updated;
      await _db.updateBudget(updated);
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────
  Account? accountById(String id) {
    try { return _accounts.firstWhere((a) => a.id == id); } catch (_) { return null; }
  }

  AppCategory? categoryById(String id) {
    try { return _categories.firstWhere((c) => c.id == id); } catch (_) { return null; }
  }

  Tag? tagById(String id) {
    try { return _tags.firstWhere((t) => t.id == id); } catch (_) { return null; }
  }
}