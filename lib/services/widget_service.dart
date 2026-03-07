// lib/services/widget_service.dart
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

class WidgetService {
  static final WidgetService instance = WidgetService._internal();
  WidgetService._internal();

  static const _appGroupId = 'com.financeku.app';
  static const _iOSWidgetName = 'FinanceKuWidget';
  static const _androidWidgetName = 'FinanceKuWidgetProvider';

  // ─── INIT ──────────────────────────────────────────────────────
  Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (e) {
      debugPrint('Widget init error: $e');
    }
  }

  // ─── UPDATE DATA KE WIDGET ─────────────────────────────────────
  Future<void> updateWidget({
    required double totalBalance,
    required double monthlyIncome,
    required double monthlyExpense,
    required double todayExpense,
  }) async {
    try {
      final now = DateTime.now();
      final monthName = DateFormat('MMM yyyy', 'id_ID').format(now);
      final todayStr = DateFormat('dd MMM', 'id_ID').format(now);

      // Simpan data ke shared storage yang bisa dibaca widget
      await HomeWidget.saveWidgetData('total_balance', _fmt(totalBalance));
      await HomeWidget.saveWidgetData('monthly_income', _fmt(monthlyIncome));
      await HomeWidget.saveWidgetData('monthly_expense', _fmt(monthlyExpense));
      await HomeWidget.saveWidgetData('today_expense', _fmt(todayExpense));
      await HomeWidget.saveWidgetData('month_name', monthName);
      await HomeWidget.saveWidgetData('today_str', todayStr);
      await HomeWidget.saveWidgetData('last_update',
          DateFormat('HH:mm').format(now));

      // Balance status (positif/negatif)
      final balance = monthlyIncome - monthlyExpense;
      await HomeWidget.saveWidgetData(
          'balance_status', balance >= 0 ? 'surplus' : 'defisit');
      await HomeWidget.saveWidgetData('monthly_balance', _fmt(balance.abs()));

      // Trigger update ke semua widget yang terpasang
      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _iOSWidgetName,
      );

      debugPrint('✅ Widget updated successfully');
    } catch (e) {
      debugPrint('Widget update error: $e');
    }
  }

  // ─── HANDLE TAP DARI WIDGET ───────────────────────────────────
  /// Dipanggil saat user tap tombol di widget
  static Future<void> handleWidgetTap(Uri? uri) async {
    if (uri == null) return;
    debugPrint('Widget tapped: $uri');
    // Handling dilakukan di main.dart via HomeWidget.widgetClicked
  }

  // ─── REGISTER CALLBACK ───────────────────────────────────────
  Future<void> registerInteractiveCallback() async {
    try {
      HomeWidget.registerInteractivityCallback(backgroundCallback);
    } catch (e) {
      debugPrint('Widget callback error: $e');
    }
  }

  // ─── FORMAT ──────────────────────────────────────────────────
  String _fmt(double v) {
    final abs = v.abs();
    if (abs >= 1000000000) {
      return 'Rp ${(abs / 1000000000).toStringAsFixed(1)}M';
    }
    if (abs >= 1000000) {
      return 'Rp ${(abs / 1000000).toStringAsFixed(1)}jt';
    }
    if (abs >= 1000) {
      return 'Rp ${(abs / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp ${abs.toStringAsFixed(0)}';
  }
}

// Background callback untuk interactive widget
// Harus top-level function
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  debugPrint('Background widget callback: $uri');
}