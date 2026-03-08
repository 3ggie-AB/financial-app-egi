// providers/goal_debt_provider.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import '../models/goal_debt_models.dart';
import '../services/database_service.dart';

class GoalDebtProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;

  List<FinancialGoal> _goals = [];
  List<Debt> _debts = [];
  bool _isLoading = false;

  List<FinancialGoal> get goals => _goals;
  List<FinancialGoal> get activeGoals =>
      _goals.where((g) => g.status == GoalStatus.active).toList();
  List<FinancialGoal> get completedGoals =>
      _goals.where((g) => g.status == GoalStatus.completed).toList();

  List<Debt> get debts => _debts;
  List<Debt> get myDebts =>
      _debts.where((d) => d.type == DebtType.debt && d.status != DebtStatus.paid && d.status != DebtStatus.cancelled).toList();
  List<Debt> get myReceivables =>
      _debts.where((d) => d.type == DebtType.receivable && d.status != DebtStatus.paid && d.status != DebtStatus.cancelled).toList();
  List<Debt> get overdueDebts =>
      _debts.where((d) => d.isOverdue).toList();

  bool get isLoading => _isLoading;

  double get totalDebtOwed =>
      myDebts.fold(0, (s, d) => s + d.remaining);
  double get totalReceivable =>
      myReceivables.fold(0, (s, d) => s + d.remaining);
  double get totalGoalSaved =>
      activeGoals.fold(0, (s, g) => s + g.savedAmount);
  double get totalGoalTarget =>
      activeGoals.fold(0, (s, g) => s + g.targetAmount);

  // ─── LOAD ──────────────────────────────────────────────────────
  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    await _ensureTables();
    _goals = await _getGoals();
    _debts = await _getDebts();
    _updateOverdueStatus();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _ensureTables() async {
    final db = _db.db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS financial_goals (
        id TEXT PRIMARY KEY, name TEXT, description TEXT,
        category TEXT, targetAmount REAL, savedAmount REAL,
        targetDate TEXT, status TEXT, color TEXT,
        linkedAccountId TEXT, createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goal_contributions (
        id TEXT PRIMARY KEY, goalId TEXT, amount REAL,
        note TEXT, date TEXT, createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS debts (
        id TEXT PRIMARY KEY, personName TEXT, personPhone TEXT,
        type TEXT, totalAmount REAL, paidAmount REAL, description TEXT,
        dueDate TEXT, status TEXT, color TEXT, linkedAccountId TEXT,
        reminderEnabled INTEGER, createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS debt_payments (
        id TEXT PRIMARY KEY, debtId TEXT, amount REAL,
        note TEXT, date TEXT, createdAt TEXT
      )
    ''');
  }

  void _updateOverdueStatus() {
    for (int i = 0; i < _debts.length; i++) {
      if (_debts[i].isOverdue && _debts[i].status == DebtStatus.active) {
        _debts[i] = _debts[i].copyWith(status: DebtStatus.overdue);
      }
    }
  }

  // ─── GOALS ────────────────────────────────────────────────────
  Future<List<FinancialGoal>> _getGoals() async {
    final maps = await _db.db.query('financial_goals', orderBy: 'createdAt DESC');
    return maps.map(FinancialGoal.fromMap).toList();
  }

  Future<void> addGoal(FinancialGoal g) async {
    await _db.db.insert('financial_goals', g.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    _goals = await _getGoals();
    notifyListeners();
  }

  Future<void> updateGoal(FinancialGoal g) async {
    await _db.db.update('financial_goals', g.toMap(),
        where: 'id = ?', whereArgs: [g.id]);
    _goals = await _getGoals();
    notifyListeners();
  }

  Future<void> deleteGoal(String id) async {
    await _db.db.delete('financial_goals', where: 'id = ?', whereArgs: [id]);
    await _db.db.delete('goal_contributions', where: 'goalId = ?', whereArgs: [id]);
    _goals = await _getGoals();
    notifyListeners();
  }

  Future<void> addContribution(GoalContribution c) async {
    await _db.db.insert('goal_contributions', c.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    // Update saved amount
    final idx = _goals.indexWhere((g) => g.id == c.goalId);
    if (idx >= 0) {
      final updated = _goals[idx].copyWith(
          savedAmount: _goals[idx].savedAmount + c.amount);
      await _db.db.update('financial_goals', updated.toMap(),
          where: 'id = ?', whereArgs: [updated.id]);
      // Auto complete
      if (updated.isCompleted && updated.status == GoalStatus.active) {
        final completed = updated.copyWith(status: GoalStatus.completed);
        await _db.db.update('financial_goals', completed.toMap(),
            where: 'id = ?', whereArgs: [completed.id]);
      }
    }
    _goals = await _getGoals();
    notifyListeners();
  }

  Future<void> deleteContribution(GoalContribution c) async {
    await _db.db.delete('goal_contributions', where: 'id = ?', whereArgs: [c.id]);
    final idx = _goals.indexWhere((g) => g.id == c.goalId);
    if (idx >= 0) {
      final newSaved = (_goals[idx].savedAmount - c.amount).clamp(0.0, double.infinity);
      final updated = _goals[idx].copyWith(savedAmount: newSaved);
      await _db.db.update('financial_goals', updated.toMap(),
          where: 'id = ?', whereArgs: [updated.id]);
    }
    _goals = await _getGoals();
    notifyListeners();
  }

  Future<List<GoalContribution>> getContributions(String goalId) async {
    final maps = await _db.db.query('goal_contributions',
        where: 'goalId = ?', whereArgs: [goalId], orderBy: 'date DESC');
    return maps.map(GoalContribution.fromMap).toList();
  }

  // ─── DEBTS ────────────────────────────────────────────────────
  Future<List<Debt>> _getDebts() async {
    final maps = await _db.db.query('debts', orderBy: 'createdAt DESC');
    return maps.map(Debt.fromMap).toList();
  }

  Future<void> addDebt(Debt d) async {
    await _db.db.insert('debts', d.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    _debts = await _getDebts();
    _updateOverdueStatus();
    notifyListeners();
  }

  Future<void> updateDebt(Debt d) async {
    await _db.db.update('debts', d.toMap(),
        where: 'id = ?', whereArgs: [d.id]);
    _debts = await _getDebts();
    _updateOverdueStatus();
    notifyListeners();
  }

  Future<void> deleteDebt(String id) async {
    await _db.db.delete('debts', where: 'id = ?', whereArgs: [id]);
    await _db.db.delete('debt_payments', where: 'debtId = ?', whereArgs: [id]);
    _debts = await _getDebts();
    notifyListeners();
  }

  Future<void> addPayment(DebtPayment p) async {
    await _db.db.insert('debt_payments', p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    final idx = _debts.indexWhere((d) => d.id == p.debtId);
    if (idx >= 0) {
      final newPaid = _debts[idx].paidAmount + p.amount;
      final newStatus = newPaid >= _debts[idx].totalAmount
          ? DebtStatus.paid
          : DebtStatus.partiallyPaid;
      final updated = _debts[idx].copyWith(
          paidAmount: newPaid, status: newStatus);
      await _db.db.update('debts', updated.toMap(),
          where: 'id = ?', whereArgs: [updated.id]);
    }
    _debts = await _getDebts();
    _updateOverdueStatus();
    notifyListeners();
  }

  Future<void> deletePayment(DebtPayment p) async {
    await _db.db.delete('debt_payments', where: 'id = ?', whereArgs: [p.id]);
    final idx = _debts.indexWhere((d) => d.id == p.debtId);
    if (idx >= 0) {
      final newPaid = (_debts[idx].paidAmount - p.amount).clamp(0.0, double.infinity);
      final newStatus = newPaid <= 0
          ? DebtStatus.active
          : newPaid >= _debts[idx].totalAmount
              ? DebtStatus.paid
              : DebtStatus.partiallyPaid;
      final updated = _debts[idx].copyWith(
          paidAmount: newPaid, status: newStatus);
      await _db.db.update('debts', updated.toMap(),
          where: 'id = ?', whereArgs: [updated.id]);
    }
    _debts = await _getDebts();
    _updateOverdueStatus();
    notifyListeners();
  }

  Future<List<DebtPayment>> getPayments(String debtId) async {
    final maps = await _db.db.query('debt_payments',
        where: 'debtId = ?', whereArgs: [debtId], orderBy: 'date DESC');
    return maps.map(DebtPayment.fromMap).toList();
  }

  Future<void> markDebtCancelled(String id) async {
    final idx = _debts.indexWhere((d) => d.id == id);
    if (idx < 0) return;
    final updated = _debts[idx].copyWith(status: DebtStatus.cancelled);
    await _db.db.update('debts', updated.toMap(),
        where: 'id = ?', whereArgs: [updated.id]);
    _debts = await _getDebts();
    notifyListeners();
  }
}