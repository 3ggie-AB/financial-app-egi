// lib/services/notification_service.dart
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  // Channel IDs
  static const String channelBudget = 'budget_warning';
  static const String channelSummary = 'summary';
  static const String channelRecurring = 'recurring';
  static const String channelReminder = 'reminder';

  // Notification IDs
  static const int idBudgetBase = 1000;     // +index per budget
  static const int idDailySummary = 2001;
  static const int idWeeklySummary = 2002;
  static const int idMonthlySummary = 2003;
  static const int idDailyReminder = 3001;

  // Prefs keys
  static const String _prefBudgetThreshold = 'notif_budget_threshold';
  static const String _prefDailySummary = 'notif_daily_summary';
  static const String _prefWeeklySummary = 'notif_weekly_summary';
  static const String _prefMonthlySummary = 'notif_monthly_summary';
  static const String _prefDailyReminder = 'notif_daily_reminder';
  static const String _prefReminderHour = 'notif_reminder_hour';
  static const String _prefReminderMinute = 'notif_reminder_minute';
  static const String _prefSummaryHour = 'notif_summary_hour';
  static const String _prefSummaryMinute = 'notif_summary_minute';
  static const String _prefEnabled = 'notif_enabled';

  // Settings cache
  bool _enabled = true;
  double _budgetThreshold = 80.0;
  bool _dailySummary = true;
  bool _weeklySummary = true;
  bool _monthlySummary = true;
  bool _dailyReminder = true;
  int _reminderHour = 20;    // jam 20:00
  int _reminderMinute = 0;
  int _summaryHour = 21;     // jam 21:00
  int _summaryMinute = 0;

  bool get enabled => _enabled;
  double get budgetThreshold => _budgetThreshold;
  bool get dailySummary => _dailySummary;
  bool get weeklySummary => _weeklySummary;
  bool get monthlySummary => _monthlySummary;
  bool get dailyReminder => _dailyReminder;
  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;
  int get summaryHour => _summaryHour;
  int get summaryMinute => _summaryMinute;

  // ─── INIT ─────────────────────────────────────────────────────
  Future<void> init() async {
    await _loadPrefs();

    await AwesomeNotifications().initialize(
      null, // null = pakai icon default app
      [
        NotificationChannel(
          channelKey: channelBudget,
          channelName: 'Peringatan Budget',
          channelDescription: 'Notifikasi saat budget hampir habis',
          defaultColor: const Color(0xFFFF9800),
          ledColor: const Color(0xFFFF9800),
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelKey: channelSummary,
          channelName: 'Ringkasan Keuangan',
          channelDescription: 'Ringkasan harian, mingguan, dan bulanan',
          defaultColor: const Color(0xFF6C63FF),
          ledColor: const Color(0xFF6C63FF),
          importance: NotificationImportance.Default,
          channelShowBadge: false,
        ),
        NotificationChannel(
          channelKey: channelRecurring,
          channelName: 'Transaksi Berulang',
          channelDescription: 'Pengingat transaksi rutin',
          defaultColor: const Color(0xFF2196F3),
          ledColor: const Color(0xFF2196F3),
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelKey: channelReminder,
          channelName: 'Pengingat Harian',
          channelDescription: 'Pengingat untuk mencatat transaksi hari ini',
          defaultColor: const Color(0xFF4CAF50),
          ledColor: const Color(0xFF4CAF50),
          importance: NotificationImportance.Default,
          channelShowBadge: false,
        ),
      ],
      debug: false,
    );

    await AwesomeNotifications().isNotificationAllowed().then((allowed) async {
      if (!allowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  // ─── LOAD/SAVE PREFS ──────────────────────────────────────────
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefEnabled) ?? true;
    _budgetThreshold = prefs.getDouble(_prefBudgetThreshold) ?? 80.0;
    _dailySummary = prefs.getBool(_prefDailySummary) ?? true;
    _weeklySummary = prefs.getBool(_prefWeeklySummary) ?? true;
    _monthlySummary = prefs.getBool(_prefMonthlySummary) ?? true;
    _dailyReminder = prefs.getBool(_prefDailyReminder) ?? true;
    _reminderHour = prefs.getInt(_prefReminderHour) ?? 20;
    _reminderMinute = prefs.getInt(_prefReminderMinute) ?? 0;
    _summaryHour = prefs.getInt(_prefSummaryHour) ?? 21;
    _summaryMinute = prefs.getInt(_prefSummaryMinute) ?? 0;
  }

  Future<void> saveSettings({
    bool? enabled,
    double? budgetThreshold,
    bool? dailySummary,
    bool? weeklySummary,
    bool? monthlySummary,
    bool? dailyReminder,
    int? reminderHour,
    int? reminderMinute,
    int? summaryHour,
    int? summaryMinute,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (enabled != null) { _enabled = enabled; await prefs.setBool(_prefEnabled, enabled); }
    if (budgetThreshold != null) { _budgetThreshold = budgetThreshold; await prefs.setDouble(_prefBudgetThreshold, budgetThreshold); }
    if (dailySummary != null) { _dailySummary = dailySummary; await prefs.setBool(_prefDailySummary, dailySummary); }
    if (weeklySummary != null) { _weeklySummary = weeklySummary; await prefs.setBool(_prefWeeklySummary, weeklySummary); }
    if (monthlySummary != null) { _monthlySummary = monthlySummary; await prefs.setBool(_prefMonthlySummary, monthlySummary); }
    if (dailyReminder != null) { _dailyReminder = dailyReminder; await prefs.setBool(_prefDailyReminder, dailyReminder); }
    if (reminderHour != null) { _reminderHour = reminderHour; await prefs.setInt(_prefReminderHour, reminderHour); }
    if (reminderMinute != null) { _reminderMinute = reminderMinute; await prefs.setInt(_prefReminderMinute, reminderMinute); }
    if (summaryHour != null) { _summaryHour = summaryHour; await prefs.setInt(_prefSummaryHour, summaryHour); }
    if (summaryMinute != null) { _summaryMinute = summaryMinute; await prefs.setInt(_prefSummaryMinute, summaryMinute); }

    // Reschedule semua notifikasi dengan setting baru
    await rescheduleAll();
  }

  // ─── BUDGET WARNING ───────────────────────────────────────────
  Future<void> checkAndNotifyBudgets({
    required List<Map<String, dynamic>> budgets, // [{name, spent, limit, percentage}]
  }) async {
    if (!_enabled) return;

    for (int i = 0; i < budgets.length; i++) {
      final b = budgets[i];
      final pct = (b['percentage'] as double) * 100;
      final name = b['name'] as String;
      final spent = b['spent'] as double;
      final limit = b['limit'] as double;

      if (pct >= 100) {
        // Over budget
        await _sendBudgetNotif(
          id: idBudgetBase + i,
          title: '🚨 Budget $name Melebihi Batas!',
          body: 'Sudah terpakai ${_fmt(spent)} dari limit ${_fmt(limit)}. Hati-hati pengeluaran!',
          isOverBudget: true,
        );
      } else if (pct >= _budgetThreshold) {
        // Near limit
        await _sendBudgetNotif(
          id: idBudgetBase + i,
          title: '⚠️ Budget $name Hampir Habis',
          body: '${pct.toStringAsFixed(0)}% terpakai — ${_fmt(spent)} dari ${_fmt(limit)}. Sisa ${_fmt(limit - spent)}.',
          isOverBudget: false,
        );
      }
    }
  }

  Future<void> _sendBudgetNotif({
    required int id,
    required String title,
    required String body,
    required bool isOverBudget,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channelBudget,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        color: isOverBudget ? const Color(0xFFF44336) : const Color(0xFFFF9800),
        category: NotificationCategory.Reminder,
      ),
    );
  }

  // ─── DAILY SUMMARY ────────────────────────────────────────────
  Future<void> scheduleDailySummary() async {
    await AwesomeNotifications().cancel(idDailySummary);
    if (!_enabled || !_dailySummary) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: idDailySummary,
        channelKey: channelSummary,
        title: '📊 Ringkasan Keuangan Harian',
        body: 'Ketuk untuk lihat ringkasan pengeluaran hari ini.',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: _summaryHour,
        minute: _summaryMinute,
        second: 0,
        repeats: true,
        allowWhileIdle: true,
      ),
    );
  }

  /// Kirim notifikasi summary dengan data nyata (dipanggil dari app)
  Future<void> sendDailySummaryNow({
    required double todayExpense,
    required double todayIncome,
    required int txnCount,
  }) async {
    if (!_enabled || !_dailySummary) return;

    final balance = todayIncome - todayExpense;
    final balanceText = balance >= 0
        ? '+${_fmt(balance)}'
        : '-${_fmt(balance.abs())}';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: idDailySummary,
        channelKey: channelSummary,
        title: '📊 Ringkasan Hari Ini',
        body: '$txnCount transaksi · Keluar ${_fmt(todayExpense)} · Masuk ${_fmt(todayIncome)} · Selisih $balanceText',
        notificationLayout: NotificationLayout.Default,
        color: balance >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
      ),
    );
  }

  // ─── WEEKLY SUMMARY ───────────────────────────────────────────
  Future<void> scheduleWeeklySummary() async {
    await AwesomeNotifications().cancel(idWeeklySummary);
    if (!_enabled || !_weeklySummary) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: idWeeklySummary,
        channelKey: channelSummary,
        title: '📈 Ringkasan Mingguan',
        body: 'Ketuk untuk lihat ringkasan keuangan minggu ini.',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        weekday: 7, // Minggu = 7
        hour: _summaryHour,
        minute: _summaryMinute,
        second: 0,
        repeats: true,
        allowWhileIdle: true,
      ),
    );
  }

  Future<void> sendWeeklySummaryNow({
    required double weekExpense,
    required double weekIncome,
    required int txnCount,
    required String topCategory,
  }) async {
    if (!_enabled || !_weeklySummary) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: idWeeklySummary,
        channelKey: channelSummary,
        title: '📈 Ringkasan Minggu Ini',
        body: '$txnCount transaksi · Keluar ${_fmt(weekExpense)} · Terbanyak: $topCategory',
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFF6C63FF),
      ),
    );
  }

  // ─── MONTHLY SUMMARY ──────────────────────────────────────────
  Future<void> scheduleMonthlyAt(int dayOfMonth) async {
    await AwesomeNotifications().cancel(idMonthlySummary);
    if (!_enabled || !_monthlySummary) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: idMonthlySummary,
        channelKey: channelSummary,
        title: '🗓️ Ringkasan Bulanan',
        body: 'Ketuk untuk lihat ringkasan keuangan bulan ini.',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        day: dayOfMonth,
        hour: _summaryHour,
        minute: _summaryMinute,
        second: 0,
        repeats: true,
        allowWhileIdle: true,
      ),
    );
  }

  Future<void> sendMonthlySummaryNow({
    required double monthExpense,
    required double monthIncome,
    required String monthName,
    required int txnCount,
  }) async {
    if (!_enabled || !_monthlySummary) return;

    final saved = monthIncome - monthExpense;
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: idMonthlySummary,
        channelKey: channelSummary,
        title: '🗓️ Ringkasan $monthName',
        body: '$txnCount transaksi · Pemasukan ${_fmt(monthIncome)} · Pengeluaran ${_fmt(monthExpense)} · ${saved >= 0 ? 'Hemat' : 'Defisit'} ${_fmt(saved.abs())}',
        notificationLayout: NotificationLayout.Default,
        color: saved >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
      ),
    );
  }

  // ─── DAILY REMINDER (belum input transaksi) ───────────────────
  Future<void> scheduleDailyReminder() async {
    await AwesomeNotifications().cancel(idDailyReminder);
    if (!_enabled || !_dailyReminder) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: idDailyReminder,
        channelKey: channelReminder,
        title: '💰 Jangan Lupa Catat Pengeluaran!',
        body: 'Kamu belum mencatat transaksi hari ini. Yuk catat sekarang!',
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFF4CAF50),
      ),
      schedule: NotificationCalendar(
        hour: _reminderHour,
        minute: _reminderMinute,
        second: 0,
        repeats: true,
        allowWhileIdle: true,
      ),
    );
  }

  /// Batalkan reminder hari ini kalau sudah ada transaksi
  Future<void> cancelTodayReminderIfHasTransaction() async {
    await AwesomeNotifications().cancel(idDailyReminder);
    // Re-schedule untuk besok tetap jalan
    await scheduleDailyReminder();
  }

  // ─── RECURRING TRANSACTION ────────────────────────────────────
  Future<void> scheduleRecurringReminder({
    required int id,
    required String transactionName,
    required double amount,
    required String period, // daily, weekly, monthly, yearly
  }) async {
    if (!_enabled) return;

    NotificationCalendar? schedule;
    final now = DateTime.now();

    switch (period) {
      case 'daily':
        schedule = NotificationCalendar(
          hour: 8, minute: 0, second: 0, repeats: true,
        );
        break;
      case 'weekly':
        schedule = NotificationCalendar(
          weekday: now.weekday, hour: 8, minute: 0, second: 0, repeats: true,
        );
        break;
      case 'monthly':
        schedule = NotificationCalendar(
          day: now.day, hour: 8, minute: 0, second: 0, repeats: true,
        );
        break;
      case 'yearly':
        schedule = NotificationCalendar(
          month: now.month, day: now.day, hour: 8, minute: 0, second: 0,
          repeats: true,
        );
        break;
      default:
        return;
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channelRecurring,
        title: '🔄 Transaksi Rutin: $transactionName',
        body: 'Saatnya mencatat transaksi rutin sebesar ${_fmt(amount)}.',
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFF2196F3),
      ),
      schedule: schedule,
    );
  }

  // ─── RESCHEDULE ALL ───────────────────────────────────────────
  Future<void> rescheduleAll() async {
    await scheduleDailySummary();
    await scheduleWeeklySummary();
    await scheduleMonthlyAt(DateTime.now().day == 1 ? 1 : 1); // tiap tanggal 1
    await scheduleDailyReminder();
  }

  Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
  }

  // ─── HELPER ───────────────────────────────────────────────────
  String _fmt(double v) {
    final abs = v.abs();
    if (abs >= 1000000) return 'Rp ${(abs / 1000000).toStringAsFixed(1)}jt';
    if (abs >= 1000) return 'Rp ${(abs / 1000).toStringAsFixed(0)}rb';
    return 'Rp ${abs.toStringAsFixed(0)}';
  }
}