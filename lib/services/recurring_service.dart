// lib/services/recurring_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class RecurringService {
  static final RecurringService instance = RecurringService._internal();
  RecurringService._internal();

  static const _prefsLastCheck = 'recurring_last_check';

  // ─── CEK & GENERATE SAAT APP DIBUKA ──────────────────────────
  Future<List<AppTransaction>> checkAndGenerate() async {
    final db = DatabaseService.instance;
    final allTransactions = await db.getTransactions();
    final generated = <AppTransaction>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Ambil semua transaksi yang recurring
    final recurringTxns = allTransactions
        .where((t) => t.recurring != RecurringPeriod.none)
        .toList();

    if (recurringTxns.isEmpty) return [];

    // Kelompokkan per "recurring group" — ambil yang terbaru per originalId
    // Kita pakai note sebagai identifier grup (atau bisa pakai categoryId+accountId)
    final processed = <String>{};

    for (final t in recurringTxns) {
      // Key unik per recurring: accountId + categoryId + amount + recurring
      final key = '${t.accountId}_${t.categoryId}_${t.amount}_${t.recurring.name}';
      if (processed.contains(key)) continue;
      processed.add(key);

      // Cari transaksi terbaru dari grup ini
      final groupTxns = recurringTxns
          .where((x) =>
              x.accountId == t.accountId &&
              x.categoryId == t.categoryId &&
              x.amount == t.amount &&
              x.recurring == t.recurring)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      final latest = groupTxns.first;
      final nextDate = _nextOccurrence(latest.date, latest.recurring);

      if (nextDate == null) continue;
      final nextDay = DateTime(nextDate.year, nextDate.month, nextDate.day);

      // Generate kalau sudah jatuh tempo atau lewat
      if (!nextDay.isAfter(today)) {
        final newTxn = AppTransaction(
          id: db.newId,
          type: latest.type,
          amount: latest.amount,
          accountId: latest.accountId,
          toAccountId: latest.toAccountId,
          categoryId: latest.categoryId,
          tagIds: latest.tagIds,
          note: latest.note,
          date: nextDate,
          recurring: latest.recurring,
          createdAt: DateTime.now(),
        );

        await db.insertTransaction(newTxn);
        generated.add(newTxn);

        debugPrint('✅ Recurring generated: ${newTxn.id} for ${newTxn.date}');
      }
    }

    // Simpan waktu terakhir cek
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsLastCheck, now.toIso8601String());

    return generated;
  }

  // ─── NEXT OCCURRENCE ─────────────────────────────────────────
  DateTime? _nextOccurrence(DateTime lastDate, RecurringPeriod period) {
    switch (period) {
      case RecurringPeriod.daily:
        return lastDate.add(const Duration(days: 1));
      case RecurringPeriod.weekly:
        return lastDate.add(const Duration(days: 7));
      case RecurringPeriod.monthly:
        int month = lastDate.month + 1;
        int year = lastDate.year;
        if (month > 12) { month = 1; year++; }
        final maxDay = DateTime(year, month + 1, 0).day;
        final day = lastDate.day > maxDay ? maxDay : lastDate.day;
        return DateTime(year, month, day, lastDate.hour, lastDate.minute);
      case RecurringPeriod.yearly:
        return DateTime(lastDate.year + 1, lastDate.month, lastDate.day,
            lastDate.hour, lastDate.minute);
      case RecurringPeriod.none:
        return null;
    }
  }

  // ─── SCHEDULE NOTIFIKASI RECURRING ───────────────────────────
  Future<void> scheduleRecurringNotifications(
      List<AppTransaction> transactions, Map<String, String> categoryNames) async {
    final processed = <String>{};

    for (final t in transactions) {
      if (t.recurring == RecurringPeriod.none) continue;
      final key = '${t.accountId}_${t.categoryId}_${t.amount}_${t.recurring.name}';
      if (processed.contains(key)) continue;
      processed.add(key);

      final catName = categoryNames[t.categoryId] ?? 'Transaksi';
      final notifId = key.hashCode.abs() % 100000;

      await NotificationService.instance.scheduleRecurringReminder(
        id: notifId,
        transactionName: catName,
        amount: t.amount,
        period: t.recurring.name,
      );
    }
  }

  // ─── GET UPCOMING RECURRING ───────────────────────────────────
  /// Untuk ditampilkan di UI — daftar transaksi recurring berikutnya
  Future<List<UpcomingRecurring>> getUpcoming(
      List<AppTransaction> allTransactions,
      Map<String, String> categoryNames,
      Map<String, String> accountNames) async {
    final now = DateTime.now();
    final result = <UpcomingRecurring>[];
    final processed = <String>{};

    final recurringTxns = allTransactions
        .where((t) => t.recurring != RecurringPeriod.none)
        .toList();

    for (final t in recurringTxns) {
      final key = '${t.accountId}_${t.categoryId}_${t.amount}_${t.recurring.name}';
      if (processed.contains(key)) continue;
      processed.add(key);

      final groupTxns = recurringTxns
          .where((x) =>
              x.accountId == t.accountId &&
              x.categoryId == t.categoryId &&
              x.amount == t.amount &&
              x.recurring == t.recurring)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      final latest = groupTxns.first;
      final nextDate = _nextOccurrence(latest.date, latest.recurring);
      if (nextDate == null) continue;

      result.add(UpcomingRecurring(
        transaction: latest,
        nextDate: nextDate,
        categoryName: categoryNames[latest.categoryId] ?? 'Lainnya',
        accountName: accountNames[latest.accountId] ?? 'Rekening',
        daysUntil: nextDate.difference(now).inDays,
      ));
    }

    result.sort((a, b) => a.nextDate.compareTo(b.nextDate));
    return result;
  }

  // ─── STOP RECURRING ───────────────────────────────────────────
  /// Hentikan recurring dengan set period ke none
  Future<void> stopRecurring(AppTransaction t) async {
    final db = DatabaseService.instance;
    final updated = AppTransaction(
      id: t.id, type: t.type, amount: t.amount,
      accountId: t.accountId, toAccountId: t.toAccountId,
      categoryId: t.categoryId, tagIds: t.tagIds,
      note: t.note, date: t.date,
      recurring: RecurringPeriod.none,
      attachmentPath: t.attachmentPath,
      createdAt: t.createdAt,
    );
    await db.updateTransaction(t, updated);
  }

  Future<DateTime?> getLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_prefsLastCheck);
    return str != null ? DateTime.tryParse(str) : null;
  }
}

class UpcomingRecurring {
  final AppTransaction transaction;
  final DateTime nextDate;
  final String categoryName;
  final String accountName;
  final int daysUntil;

  const UpcomingRecurring({
    required this.transaction,
    required this.nextDate,
    required this.categoryName,
    required this.accountName,
    required this.daysUntil,
  });
}