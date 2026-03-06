import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/database_service.dart';

class FinanceProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;

  List<Account> _accounts = [];
  List<Category> _categories = [];
  List<Tag> _tags = [];
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];

  bool _isLoading = false;

  List<Account> get accounts => _accounts.where((a) => a.isActive).toList();
  List<Account> get allAccounts => _accounts;
  List<Category> get categories => _categories;
  List<Category> get expenseCategories =>
      _categories.where((c) => c.type == TransactionType.expense).toList();
  List<Category> get incomeCategories =>
      _categories.where((c) => c.type == TransactionType.income).toList();
  List<Tag> get tags => _tags;
  List<Transaction> get transactions => _transactions;
  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;

  // ─── TOTALS ──────────────────────────────────────────────────
  double get totalBalance => _accounts
      .where((a) => a.isActive && a.type != 'credit')
      .fold(0, (sum, a) => sum + a.balance);

  double get totalAssets => _accounts
      .where((a) => a.isActive && a.type != 'credit')
      .fold(0, (sum, a) => sum + a.balance);

  double monthlyIncome(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(end.add(const Duration(seconds: 1))))
        .fold(0, (sum, t) => sum + t.amount);
  }

  double monthlyExpense(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(end.add(const Duration(seconds: 1))))
        .fold(0, (sum, t) => sum + t.amount);
  }

  List<Transaction> transactionsForMonth(DateTime month) {
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

  // ─── LOAD ─────────────────────────────────────────────────────
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

  // ─── ACCOUNT CRUD ────────────────────────────────────────────
  Future<void> addAccount(Account a) async {
    await _db.insertAccount(a);
    _accounts = await _db.getAccounts();
    notifyListeners();
  }

  Future<void> updateAccount(Account a) async {
    await _db.updateAccount(a);
    _accounts = await _db.getAccounts();
    notifyListeners();
  }

  Future<void> deleteAccount(String id) async {
    await _db.deleteAccount(id);
    _accounts = await _db.getAccounts();
    notifyListeners();
  }

  // ─── CATEGORY CRUD ───────────────────────────────────────────
  Future<void> addCategory(Category c) async {
    await _db.insertCategory(c);
    _categories = await _db.getCategories();
    notifyListeners();
  }

  Future<void> updateCategory(Category c) async {
    await _db.updateCategory(c);
    _categories = await _db.getCategories();
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    await _db.deleteCategory(id);
    _categories = await _db.getCategories();
    notifyListeners();
  }

  // ─── TAG CRUD ─────────────────────────────────────────────────
  Future<void> addTag(Tag t) async {
    await _db.insertTag(t);
    _tags = await _db.getTags();
    notifyListeners();
  }

  Future<void> updateTag(Tag t) async {
    await _db.updateTag(t);
    _tags = await _db.getTags();
    notifyListeners();
  }

  Future<void> deleteTag(String id) async {
    await _db.deleteTag(id);
    _tags = await _db.getTags();
    notifyListeners();
  }

  // ─── TRANSACTION CRUD ────────────────────────────────────────
  Future<void> addTransaction(Transaction t) async {
    await _db.insertTransaction(t);
    _transactions = await _db.getTransactions();
    _accounts = await _db.getAccounts();
    await _recalcBudgets();
    notifyListeners();
  }

  Future<void> updateTransaction(Transaction oldT, Transaction newT) async {
    await _db.updateTransaction(oldT, newT);
    _transactions = await _db.getTransactions();
    _accounts = await _db.getAccounts();
    await _recalcBudgets();
    notifyListeners();
  }

  Future<void> deleteTransaction(Transaction t) async {
    await _db.deleteTransaction(t);
    _transactions = await _db.getTransactions();
    _accounts = await _db.getAccounts();
    await _recalcBudgets();
    notifyListeners();
  }

  // ─── BUDGET CRUD ──────────────────────────────────────────────
  Future<void> addBudget(Budget b) async {
    await _db.insertBudget(b);
    _budgets = await _db.getBudgets();
    await _recalcBudgets();
    notifyListeners();
  }

  Future<void> deleteBudget(String id) async {
    await _db.deleteBudget(id);
    _budgets = await _db.getBudgets();
    notifyListeners();
  }

  Future<void> _recalcBudgets() async {
    final now = DateTime.now();
    for (int i = 0; i < _budgets.length; i++) {
      final b = _budgets[i];
      if (!b.isActive) continue;
      final spent = _transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.categoryId == b.categoryId &&
              t.date.isAfter(b.startDate) &&
              t.date.isBefore(b.endDate))
          .fold(0.0, (sum, t) => sum + t.amount);
      final updated = Budget(
        id: b.id,
        categoryId: b.categoryId,
        limitAmount: b.limitAmount,
        spentAmount: spent,
        startDate: b.startDate,
        endDate: b.endDate,
        isActive: b.isActive,
      );
      _budgets[i] = updated;
      await _db.updateBudget(updated);
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────
  Account? accountById(String id) {
    try { return _accounts.firstWhere((a) => a.id == id); }
    catch (_) { return null; }
  }

  Category? categoryById(String id) {
    try { return _categories.firstWhere((c) => c.id == id); }
    catch (_) { return null; }
  }

  Tag? tagById(String id) {
    try { return _tags.firstWhere((t) => t.id == id); }
    catch (_) { return null; }
  }
}
