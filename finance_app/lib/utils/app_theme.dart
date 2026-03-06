// utils/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFF6C63FF);
  static const incomeColor = Color(0xFF4CAF50);
  static const expenseColor = Color(0xFFF44336);
  static const transferColor = Color(0xFF2196F3);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: const Color(0xFF1E1E2E),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A3E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
        ),
      );
}

// utils/formatters.dart
import 'package:intl/intl.dart';

String formatCurrency(double amount, {String currency = 'IDR'}) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: currency == 'IDR' ? 'Rp ' : '$currency ',
    decimalDigits: currency == 'IDR' ? 0 : 2,
  );
  return formatter.format(amount);
}

String formatDate(DateTime date) => DateFormat('dd MMM yyyy', 'id_ID').format(date);
String formatDateTime(DateTime date) =>
    DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
String formatMonth(DateTime date) => DateFormat('MMMM yyyy', 'id_ID').format(date);
String formatShortDate(DateTime date) => DateFormat('dd MMM', 'id_ID').format(date);

Color colorFromHex(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

IconData categoryIcon(String icon) {
  return switch (icon) {
    'food' => Icons.restaurant_rounded,
    'car' => Icons.directions_car_rounded,
    'shopping' => Icons.shopping_bag_rounded,
    'bill' => Icons.receipt_long_rounded,
    'entertainment' => Icons.movie_rounded,
    'health' => Icons.local_hospital_rounded,
    'education' => Icons.school_rounded,
    'salary' => Icons.account_balance_wallet_rounded,
    'freelance' => Icons.work_rounded,
    'investment' => Icons.trending_up_rounded,
    'bonus' => Icons.card_giftcard_rounded,
    'wallet' => Icons.account_balance_wallet_rounded,
    'bank' => Icons.account_balance_rounded,
    'phone' => Icons.phone_android_rounded,
    'credit' => Icons.credit_card_rounded,
    _ => Icons.category_rounded,
  };
}
