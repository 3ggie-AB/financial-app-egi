// models/goal_debt_models.dart

// ─── FINANCIAL GOAL ───────────────────────────────────────────────────────────

enum GoalCategory {
  emergency,   // Dana darurat
  vehicle,     // Kendaraan
  property,    // Properti / Rumah
  vacation,    // Liburan
  education,   // Pendidikan
  gadget,      // Gadget / Elektronik
  wedding,     // Pernikahan
  health,      // Kesehatan
  investment,  // Investasi
  other,       // Lainnya
}

enum GoalStatus { active, completed, cancelled }

class FinancialGoal {
  final String id;
  String name;
  String? description;
  GoalCategory category;
  double targetAmount;
  double savedAmount;
  DateTime? targetDate;
  GoalStatus status;
  String color;
  String? linkedAccountId; // rekening yang digunakan untuk nabung
  DateTime createdAt;

  FinancialGoal({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.targetAmount,
    this.savedAmount = 0,
    this.targetDate,
    this.status = GoalStatus.active,
    this.color = '#7C6AF7',
    this.linkedAccountId,
    required this.createdAt,
  });

  double get percentage =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remaining => (targetAmount - savedAmount).clamp(0, double.infinity);
  bool get isCompleted => savedAmount >= targetAmount;

  int? get daysRemaining {
    if (targetDate == null) return null;
    return targetDate!.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category.name,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        'targetDate': targetDate?.toIso8601String(),
        'status': status.name,
        'color': color,
        'linkedAccountId': linkedAccountId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FinancialGoal.fromMap(Map<String, dynamic> map) => FinancialGoal(
        id: map['id'],
        name: map['name'],
        description: map['description'],
        category: GoalCategory.values.firstWhere(
          (e) => e.name == map['category'],
          orElse: () => GoalCategory.other,
        ),
        targetAmount: (map['targetAmount'] ?? 0).toDouble(),
        savedAmount: (map['savedAmount'] ?? 0).toDouble(),
        targetDate: map['targetDate'] != null
            ? DateTime.tryParse(map['targetDate'])
            : null,
        status: GoalStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => GoalStatus.active,
        ),
        color: map['color'] ?? '#7C6AF7',
        linkedAccountId: map['linkedAccountId'],
        createdAt: DateTime.parse(map['createdAt']),
      );

  FinancialGoal copyWith({
    String? name,
    String? description,
    GoalCategory? category,
    double? targetAmount,
    double? savedAmount,
    DateTime? targetDate,
    GoalStatus? status,
    String? color,
    String? linkedAccountId,
  }) =>
      FinancialGoal(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        category: category ?? this.category,
        targetAmount: targetAmount ?? this.targetAmount,
        savedAmount: savedAmount ?? this.savedAmount,
        targetDate: targetDate ?? this.targetDate,
        status: status ?? this.status,
        color: color ?? this.color,
        linkedAccountId: linkedAccountId ?? this.linkedAccountId,
        createdAt: createdAt,
      );
}

// ─── GOAL CONTRIBUTION (riwayat setoran ke goal) ─────────────────────────────

class GoalContribution {
  final String id;
  final String goalId;
  final double amount;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  GoalContribution({
    required this.id,
    required this.goalId,
    required this.amount,
    this.note,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'goalId': goalId,
        'amount': amount,
        'note': note,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory GoalContribution.fromMap(Map<String, dynamic> map) =>
      GoalContribution(
        id: map['id'],
        goalId: map['goalId'],
        amount: (map['amount'] ?? 0).toDouble(),
        note: map['note'],
        date: DateTime.parse(map['date']),
        createdAt: DateTime.parse(map['createdAt']),
      );
}

// ─── DEBT / PIUTANG ───────────────────────────────────────────────────────────

enum DebtType {
  debt,      // Hutang — kita yang berhutang (debitur)
  receivable, // Piutang — orang lain yang berhutang ke kita (kreditur)
}

enum DebtStatus { active, partiallyPaid, paid, overdue, cancelled }

class Debt {
  final String id;
  String personName;    // nama orang / lembaga
  String? personPhone;
  DebtType type;
  double totalAmount;
  double paidAmount;
  String? description;
  DateTime? dueDate;
  DebtStatus status;
  String color;
  String? linkedAccountId;
  bool reminderEnabled;
  DateTime createdAt;

  Debt({
    required this.id,
    required this.personName,
    this.personPhone,
    required this.type,
    required this.totalAmount,
    this.paidAmount = 0,
    this.description,
    this.dueDate,
    this.status = DebtStatus.active,
    this.color = '#FC7070',
    this.linkedAccountId,
    this.reminderEnabled = true,
    required this.createdAt,
  });

  double get remaining => (totalAmount - paidAmount).clamp(0, double.infinity);
  double get percentage =>
      totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;
  bool get isPaid => paidAmount >= totalAmount;

  int? get daysUntilDue {
    if (dueDate == null) return null;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && !isPaid;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'personName': personName,
        'personPhone': personPhone,
        'type': type.name,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'description': description,
        'dueDate': dueDate?.toIso8601String(),
        'status': status.name,
        'color': color,
        'linkedAccountId': linkedAccountId,
        'reminderEnabled': reminderEnabled ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Debt.fromMap(Map<String, dynamic> map) => Debt(
        id: map['id'],
        personName: map['personName'],
        personPhone: map['personPhone'],
        type: DebtType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => DebtType.debt,
        ),
        totalAmount: (map['totalAmount'] ?? 0).toDouble(),
        paidAmount: (map['paidAmount'] ?? 0).toDouble(),
        description: map['description'],
        dueDate: map['dueDate'] != null
            ? DateTime.tryParse(map['dueDate'])
            : null,
        status: DebtStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => DebtStatus.active,
        ),
        color: map['color'] ?? '#FC7070',
        linkedAccountId: map['linkedAccountId'],
        reminderEnabled: (map['reminderEnabled'] ?? 1) == 1,
        createdAt: DateTime.parse(map['createdAt']),
      );

  Debt copyWith({
    String? personName,
    String? personPhone,
    DebtType? type,
    double? totalAmount,
    double? paidAmount,
    String? description,
    DateTime? dueDate,
    DebtStatus? status,
    String? color,
    String? linkedAccountId,
    bool? reminderEnabled,
  }) =>
      Debt(
        id: id,
        personName: personName ?? this.personName,
        personPhone: personPhone ?? this.personPhone,
        type: type ?? this.type,
        totalAmount: totalAmount ?? this.totalAmount,
        paidAmount: paidAmount ?? this.paidAmount,
        description: description ?? this.description,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        color: color ?? this.color,
        linkedAccountId: linkedAccountId ?? this.linkedAccountId,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        createdAt: createdAt,
      );
}

// ─── DEBT PAYMENT (riwayat pembayaran hutang/piutang) ────────────────────────

class DebtPayment {
  final String id;
  final String debtId;
  final double amount;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  DebtPayment({
    required this.id,
    required this.debtId,
    required this.amount,
    this.note,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'debtId': debtId,
        'amount': amount,
        'note': note,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory DebtPayment.fromMap(Map<String, dynamic> map) => DebtPayment(
        id: map['id'],
        debtId: map['debtId'],
        amount: (map['amount'] ?? 0).toDouble(),
        note: map['note'],
        date: DateTime.parse(map['date']),
        createdAt: DateTime.parse(map['createdAt']),
      );
}