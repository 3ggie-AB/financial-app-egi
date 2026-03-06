// ============================================================
// MODELS - models/models.dart
// ============================================================

enum TransactionType { income, expense, transfer }

enum RecurringPeriod { none, daily, weekly, monthly, yearly }

// ─── Account ─────────────────────────────────────────────────
class Account {
  final String id;
  String name;
  String type; // cash, bank, credit, ewallet, investment
  double balance;
  String currency;
  String color;
  String icon;
  bool isActive;
  DateTime createdAt;

  Account({
    required this.id,
    required this.name,
    this.type = 'cash',
    this.balance = 0,
    this.currency = 'IDR',
    this.color = '#4CAF50',
    this.icon = 'wallet',
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'balance': balance,
        'currency': currency,
        'color': color,
        'icon': icon,
        'isActive': isActive ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Account.fromMap(Map<String, dynamic> map) => Account(
        id: map['id'],
        name: map['name'],
        type: map['type'] ?? 'cash',
        balance: (map['balance'] ?? 0).toDouble(),
        currency: map['currency'] ?? 'IDR',
        color: map['color'] ?? '#4CAF50',
        icon: map['icon'] ?? 'wallet',
        isActive: (map['isActive'] ?? 1) == 1,
        createdAt: DateTime.parse(map['createdAt']),
      );

  Account copyWith({
    String? name,
    String? type,
    double? balance,
    String? currency,
    String? color,
    String? icon,
    bool? isActive,
  }) =>
      Account(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        balance: balance ?? this.balance,
        currency: currency ?? this.currency,
        color: color ?? this.color,
        icon: icon ?? this.icon,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}

// ─── Category ─────────────────────────────────────────────────
class Category {
  final String id;
  String name;
  TransactionType type;
  String color;
  String icon;
  String? parentId;

  Category({
    required this.id,
    required this.name,
    required this.type,
    this.color = '#2196F3',
    this.icon = 'category',
    this.parentId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'color': color,
        'icon': icon,
        'parentId': parentId,
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'],
        name: map['name'],
        type: TransactionType.values.firstWhere((e) => e.name == map['type'],
            orElse: () => TransactionType.expense),
        color: map['color'] ?? '#2196F3',
        icon: map['icon'] ?? 'category',
        parentId: map['parentId'],
      );
}

// ─── Tag ─────────────────────────────────────────────────────
class Tag {
  final String id;
  String name;
  String color;

  Tag({required this.id, required this.name, this.color = '#9C27B0'});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'color': color};

  factory Tag.fromMap(Map<String, dynamic> map) =>
      Tag(id: map['id'], name: map['name'], color: map['color'] ?? '#9C27B0');
}

// ─── Transaction ─────────────────────────────────────────────
class Transaction {
  final String id;
  TransactionType type;
  double amount;
  String accountId;
  String? toAccountId; // for transfer
  String categoryId;
  List<String> tagIds;
  String? note;
  DateTime date;
  RecurringPeriod recurring;
  String? attachmentPath;
  DateTime createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.accountId,
    this.toAccountId,
    required this.categoryId,
    this.tagIds = const [],
    this.note,
    required this.date,
    this.recurring = RecurringPeriod.none,
    this.attachmentPath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'accountId': accountId,
        'toAccountId': toAccountId,
        'categoryId': categoryId,
        'tagIds': tagIds.join(','),
        'note': note,
        'date': date.toIso8601String(),
        'recurring': recurring.name,
        'attachmentPath': attachmentPath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'],
        type: TransactionType.values.firstWhere((e) => e.name == map['type'],
            orElse: () => TransactionType.expense),
        amount: (map['amount'] ?? 0).toDouble(),
        accountId: map['accountId'],
        toAccountId: map['toAccountId'],
        categoryId: map['categoryId'],
        tagIds: map['tagIds'] != null && map['tagIds'].toString().isNotEmpty
            ? map['tagIds'].toString().split(',')
            : [],
        note: map['note'],
        date: DateTime.parse(map['date']),
        recurring: RecurringPeriod.values.firstWhere(
            (e) => e.name == map['recurring'],
            orElse: () => RecurringPeriod.none),
        attachmentPath: map['attachmentPath'],
        createdAt: DateTime.parse(map['createdAt']),
      );
}

// ─── Budget ───────────────────────────────────────────────────
class Budget {
  final String id;
  String categoryId;
  double limitAmount;
  double spentAmount;
  DateTime startDate;
  DateTime endDate;
  bool isActive;

  Budget({
    required this.id,
    required this.categoryId,
    required this.limitAmount,
    this.spentAmount = 0,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });

  double get percentage =>
      limitAmount > 0 ? (spentAmount / limitAmount).clamp(0, 1) : 0;
  double get remaining => limitAmount - spentAmount;
  bool get isOverBudget => spentAmount > limitAmount;

  Map<String, dynamic> toMap() => {
        'id': id,
        'categoryId': categoryId,
        'limitAmount': limitAmount,
        'spentAmount': spentAmount,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'isActive': isActive ? 1 : 0,
      };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
        id: map['id'],
        categoryId: map['categoryId'],
        limitAmount: (map['limitAmount'] ?? 0).toDouble(),
        spentAmount: (map['spentAmount'] ?? 0).toDouble(),
        startDate: DateTime.parse(map['startDate']),
        endDate: DateTime.parse(map['endDate']),
        isActive: (map['isActive'] ?? 1) == 1,
      );
}
