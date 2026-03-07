import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _db;
  final _uuid = const Uuid();

  String get newId => _uuid.v4();

  Future<void> initialize() async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    if (kIsWeb) {
      databaseFactory = databaseFactoryFfi;
      _db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: 1, onCreate: _onCreate),
      );
    } else {
      final dbPath = await getDatabasesPath();
      _db = await openDatabase(
        join(dbPath, 'finance.db'),
        version: 1,
        onCreate: _onCreate,
      );
    }

    await _seedDefaultData();
  }

  Database get db => _db!;

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY, name TEXT, type TEXT, balance REAL,
        currency TEXT, color TEXT, icon TEXT, isActive INTEGER, createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY, name TEXT, type TEXT,
        color TEXT, icon TEXT, parentId TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY, name TEXT, color TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY, type TEXT, amount REAL, accountId TEXT,
        toAccountId TEXT, categoryId TEXT, tagIds TEXT, note TEXT,
        date TEXT, recurring TEXT, attachmentPath TEXT, createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY, categoryId TEXT, limitAmount REAL,
        spentAmount REAL, startDate TEXT, endDate TEXT, isActive INTEGER
      )
    ''');
  }

  Future<void> _seedDefaultData() async {
    final categories = await getCategories();
    if (categories.isNotEmpty) return;

    final expenseCategories = [
      {'name': 'Makanan & Minuman', 'color': '#F44336', 'icon': 'food'},
      {'name': 'Transportasi', 'color': '#FF9800', 'icon': 'car'},
      {'name': 'Belanja', 'color': '#E91E63', 'icon': 'shopping'},
      {'name': 'Tagihan & Utilitas', 'color': '#9C27B0', 'icon': 'bill'},
      {'name': 'Hiburan', 'color': '#3F51B5', 'icon': 'entertainment'},
      {'name': 'Kesehatan', 'color': '#009688', 'icon': 'health'},
      {'name': 'Pendidikan', 'color': '#607D8B', 'icon': 'education'},
      {'name': 'Lainnya', 'color': '#795548', 'icon': 'other'},
    ];
    for (final c in expenseCategories) {
      await insertCategory(AppCategory(
        id: newId, name: c['name']!, type: TransactionType.expense,
        color: c['color']!, icon: c['icon']!,
      ));
    }

    final incomeCategories = [
      {'name': 'Gaji', 'color': '#4CAF50', 'icon': 'salary'},
      {'name': 'Freelance', 'color': '#8BC34A', 'icon': 'freelance'},
      {'name': 'Investasi', 'color': '#CDDC39', 'icon': 'investment'},
      {'name': 'Bonus', 'color': '#FFEB3B', 'icon': 'bonus'},
      {'name': 'Lainnya', 'color': '#795548', 'icon': 'other'},
    ];
    for (final c in incomeCategories) {
      await insertCategory(AppCategory(
        id: newId, name: c['name']!, type: TransactionType.income,
        color: c['color']!, icon: c['icon']!,
      ));
    }

    final tags = ['Penting', 'Bulanan', 'Darurat', 'Tabungan', 'Investasi'];
    final tagColors = ['#F44336', '#2196F3', '#FF9800', '#4CAF50', '#9C27B0'];
    for (int i = 0; i < tags.length; i++) {
      await insertTag(Tag(id: newId, name: tags[i], color: tagColors[i]));
    }
  }

  // ─── ACCOUNTS ────────────────────────────────────────────────
  Future<List<Account>> getAccounts() async {
    final maps = await db.query('accounts', orderBy: 'createdAt ASC');
    return maps.map(Account.fromMap).toList();
  }

  Future<void> insertAccount(Account a) async =>
      await db.insert('accounts', a.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> updateAccount(Account a) async =>
      await db.update('accounts', a.toMap(), where: 'id = ?', whereArgs: [a.id]);

  Future<void> deleteAccount(String id) async =>
      await db.delete('accounts', where: 'id = ?', whereArgs: [id]);

  // ─── CATEGORIES ──────────────────────────────────────────────
  Future<List<AppCategory>> getCategories() async {
    final maps = await db.query('categories');
    return maps.map(AppCategory.fromMap).toList();
  }

  Future<void> insertCategory(AppCategory c) async =>
      await db.insert('categories', c.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> updateCategory(AppCategory c) async =>
      await db.update('categories', c.toMap(), where: 'id = ?', whereArgs: [c.id]);

  Future<void> deleteCategory(String id) async =>
      await db.delete('categories', where: 'id = ?', whereArgs: [id]);

  // ─── TAGS ─────────────────────────────────────────────────────
  Future<List<Tag>> getTags() async {
    final maps = await db.query('tags');
    return maps.map(Tag.fromMap).toList();
  }

  Future<void> insertTag(Tag t) async =>
      await db.insert('tags', t.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> updateTag(Tag t) async =>
      await db.update('tags', t.toMap(), where: 'id = ?', whereArgs: [t.id]);

  Future<void> deleteTag(String id) async =>
      await db.delete('tags', where: 'id = ?', whereArgs: [id]);

  // ─── TRANSACTIONS ─────────────────────────────────────────────
  Future<List<AppTransaction>> getTransactions({
    DateTime? from, DateTime? to,
    String? accountId, String? categoryId, TransactionType? type,
  }) async {
    String where = '1=1';
    List<dynamic> args = [];
    if (from != null) { where += ' AND date >= ?'; args.add(from.toIso8601String()); }
    if (to != null) { where += ' AND date <= ?'; args.add(to.toIso8601String()); }
    if (accountId != null) { where += ' AND (accountId = ? OR toAccountId = ?)'; args.addAll([accountId, accountId]); }
    if (categoryId != null) { where += ' AND categoryId = ?'; args.add(categoryId); }
    if (type != null) { where += ' AND type = ?'; args.add(type.name); }

    final maps = await db.query('transactions', where: where, whereArgs: args, orderBy: 'date DESC');
    return maps.map(AppTransaction.fromMap).toList();
  }

  Future<void> insertTransaction(AppTransaction t) async {
    await db.insert('transactions', t.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    await _updateAccountBalance(t, isDelete: false);
  }

  Future<void> updateTransaction(AppTransaction oldT, AppTransaction newT) async {
    await _updateAccountBalance(oldT, isDelete: true);
    await db.update('transactions', newT.toMap(), where: 'id = ?', whereArgs: [newT.id]);
    await _updateAccountBalance(newT, isDelete: false);
  }

  Future<void> deleteTransaction(AppTransaction t) async {
    await db.delete('transactions', where: 'id = ?', whereArgs: [t.id]);
    await _updateAccountBalance(t, isDelete: true);
  }

  /// Ekstrak jumlah coin dari metadata di field note.
  /// Format yang disimpan: __crypto_coin_amount:0.00012345__
  double? _extractCoinAmount(String? note) {
    if (note == null) return null;
    final match = RegExp(r'__crypto_coin_amount:([0-9.]+)__').firstMatch(note);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  Future<void> _updateAccountBalance(AppTransaction t, {required bool isDelete}) async {
    final multiplier = isDelete ? -1 : 1;
    final accounts = await getAccounts();
    final accountMap = {for (var a in accounts) a.id: a};

    if (t.type == TransactionType.income) {
      final acc = accountMap[t.accountId];
      if (acc != null) {
        await updateAccount(acc.copyWith(balance: acc.balance + (t.amount * multiplier)));
      }
    } else if (t.type == TransactionType.expense) {
      final acc = accountMap[t.accountId];
      if (acc != null) {
        await updateAccount(acc.copyWith(balance: acc.balance - (t.amount * multiplier)));
      }
    } else if (t.type == TransactionType.transfer) {
      final from = accountMap[t.accountId];
      final to = accountMap[t.toAccountId ?? ''];

      // Rekening asal selalu berkurang sebesar IDR
      if (from != null) {
        await updateAccount(from.copyWith(balance: from.balance - (t.amount * multiplier)));
      }

      if (to != null) {
        if (to.type == 'crypto') {
          // Rekening crypto: pakai coin amount dari metadata note
          final coinAmount = _extractCoinAmount(t.note);
          if (coinAmount != null) {
            await updateAccount(to.copyWith(balance: to.balance + (coinAmount * multiplier)));
          } else {
            debugPrint('⚠️ Transfer ke crypto tanpa metadata coin amount — saldo tidak diubah');
          }
        } else {
          // Rekening biasa: tambah IDR normal
          await updateAccount(to.copyWith(balance: to.balance + (t.amount * multiplier)));
        }
      }
    }
  }

  // ─── BUDGETS ──────────────────────────────────────────────────
  Future<List<Budget>> getBudgets() async {
    final maps = await db.query('budgets');
    return maps.map(Budget.fromMap).toList();
  }

  Future<void> insertBudget(Budget b) async =>
      await db.insert('budgets', b.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> updateBudget(Budget b) async =>
      await db.update('budgets', b.toMap(), where: 'id = ?', whereArgs: [b.id]);

  Future<void> deleteBudget(String id) async =>
      await db.delete('budgets', where: 'id = ?', whereArgs: [id]);

  // ─── EXPORT/IMPORT ────────────────────────────────────────────
  Future<Map<String, dynamic>> exportAll() async {
    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'version': 1,
      'accounts': (await getAccounts()).map((e) => e.toMap()).toList(),
      'categories': (await getCategories()).map((e) => e.toMap()).toList(),
      'tags': (await getTags()).map((e) => e.toMap()).toList(),
      'transactions': (await getTransactions()).map((e) => e.toMap()).toList(),
      'budgets': (await getBudgets()).map((e) => e.toMap()).toList(),
    };
  }

  Future<void> importAll(Map<String, dynamic> data) async {
    await db.transaction((txn) async {
      for (final table in ['accounts', 'categories', 'tags', 'transactions', 'budgets']) {
        await txn.delete(table);
      }
      for (final map in (data['accounts'] as List? ?? [])) {
        await txn.insert('accounts', Map<String, dynamic>.from(map));
      }
      for (final map in (data['categories'] as List? ?? [])) {
        await txn.insert('categories', Map<String, dynamic>.from(map));
      }
      for (final map in (data['tags'] as List? ?? [])) {
        await txn.insert('tags', Map<String, dynamic>.from(map));
      }
      for (final map in (data['transactions'] as List? ?? [])) {
        await txn.insert('transactions', Map<String, dynamic>.from(map));
      }
      for (final map in (data['budgets'] as List? ?? [])) {
        await txn.insert('budgets', Map<String, dynamic>.from(map));
      }
    });
  }

  Future<void> deleteAllData() async {
    await db.transaction((txn) async {
      for (final table in ['transactions', 'budgets', 'accounts', 'categories', 'tags']) {
        await txn.delete(table);
      }
    });
  }
}