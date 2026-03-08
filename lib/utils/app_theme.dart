// utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AppTheme {
  // ─── BRAND COLORS ────────────────────────────────────────────────
  static const primaryColor     = Color(0xFF7C6AF7); // Soft violet
  static const primaryLight     = Color(0xFF9B8FF9); // Lighter violet
  static const primaryDark      = Color(0xFF5A50D4); // Deeper violet

  static const goldColor        = Color(0xFFE8C44A); // Premium gold
  static const goldLight        = Color(0xFFF5D97A); // Light gold
  static const goldDark         = Color(0xFFB8962A); // Deep gold

  static const incomeColor      = Color(0xFF34D399); // Emerald green
  static const incomeLight      = Color(0xFF6EE7B7); // Light emerald
  static const expenseColor     = Color(0xFFFC7070); // Soft coral red
  static const expenseLight     = Color(0xFFFCA5A5); // Light coral
  static const transferColor    = Color(0xFF60B8FF); // Sky blue

  // ─── DARK PALETTE ──────────────────────────────────────────────
  static const darkBg           = Color(0xFF0A0A12); // Near black
  static const darkSurface      = Color(0xFF12121E); // Dark navy
  static const darkCard         = Color(0xFF1A1A2E); // Card bg
  static const darkCardAlt      = Color(0xFF1F1F35); // Slightly lighter
  static const darkBorder       = Color(0xFF2A2A45); // Subtle border
  static const darkOverlay      = Color(0xFF252540); // Overlay

  // ─── LIGHT PALETTE ─────────────────────────────────────────────
  static const lightBg          = Color(0xFFF0F0FF); // Very light lavender
  static const lightSurface     = Color(0xFFFFFFFF);
  static const lightCard        = Color(0xFFFFFFFF);
  static const lightCardAlt     = Color(0xFFF8F8FF);
  static const lightBorder      = Color(0xFFE8E8F5);

  // ─── GRADIENTS ─────────────────────────────────────────────────
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF7C6AF7), Color(0xFF9B6BF5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const goldGradient = LinearGradient(
    colors: [Color(0xFFE8C44A), Color(0xFFF5D97A), Color(0xFFB8962A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradientDark = LinearGradient(
    colors: [Color(0xFF1A0A3E), Color(0xFF0A0A25), Color(0xFF0A1228)],
    begin: Alignment.topLeft,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );

  static const heroGradientLight = LinearGradient(
    colors: [Color(0xFF7C6AF7), Color(0xFF6055E5), Color(0xFF4C42D0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const incomeGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const expenseGradient = LinearGradient(
    colors: [Color(0xFFFC7070), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── SHADOWS ─────────────────────────────────────────────────
  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primaryColor.withOpacity(0.35),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get goldShadow => [
    BoxShadow(
      color: goldColor.withOpacity(0.3),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get cardShadowDark => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: primaryColor.withOpacity(0.05),
      blurRadius: 30,
      offset: const Offset(0, 0),
    ),
  ];

  static List<BoxShadow> get cardShadowLight => [
    BoxShadow(
      color: const Color(0xFF7C6AF7).withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ─── THEMES ───────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: goldColor,
      surface: lightCard,
      background: lightBg,
      outline: lightBorder,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: lightBg,
      fontFamily: 'Poppins',

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1A1040),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1040),
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1040)),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: lightCard,
        shadowColor: primaryColor.withOpacity(0.15),
        margin: EdgeInsets.zero,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCardAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: lightBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: lightBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: const Color(0xFF6B7280), fontSize: 13),
        hintStyle: TextStyle(color: const Color(0xFF9CA3AF), fontSize: 14),
        prefixIconColor: primaryColor.withOpacity(0.7),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: lightCardAlt,
        selectedColor: primaryColor.withOpacity(0.15),
        side: BorderSide(color: lightBorder, width: 1.2),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // Bottom App Bar
      bottomAppBarTheme: const BottomAppBarThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const CircleBorder(),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.white;
          return Colors.grey[400];
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primaryColor;
          return Colors.grey[300];
        }),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.15),
        inactiveTrackColor: lightBorder,
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: const Color(0xFF9CA3AF),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
        indicator: BoxDecoration(
          color: primaryColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: lightBorder,
        thickness: 1,
        space: 1,
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        iconColor: primaryColor.withOpacity(0.8),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, letterSpacing: -1.0),
        displayMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, letterSpacing: -0.5),
        displaySmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, letterSpacing: -0.5),
        headlineLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, letterSpacing: -0.3),
        headlineMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, letterSpacing: -0.2),
        headlineSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, letterSpacing: 0.1),
        titleMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, letterSpacing: 0.1),
        titleSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, letterSpacing: 0.1),
        bodyMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ColorScheme(
      brightness: Brightness.dark,
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: darkCard,
      onPrimaryContainer: primaryLight,
      secondary: goldColor,
      onSecondary: darkBg,
      secondaryContainer: darkCardAlt,
      onSecondaryContainer: goldLight,
      tertiary: incomeColor,
      onTertiary: darkBg,
      error: expenseColor,
      onError: Colors.white,
      errorContainer: expenseColor.withOpacity(0.15),
      onErrorContainer: expenseLight,
      background: darkBg,
      onBackground: Colors.white,
      surface: darkCard,
      onSurface: Colors.white,
      surfaceVariant: darkCardAlt,
      onSurfaceVariant: const Color(0xFFB0B0D0),
      outline: darkBorder,
      outlineVariant: const Color(0xFF1E1E38),
      shadow: Colors.black,
      scrim: Colors.black87,
      inverseSurface: Colors.white,
      onInverseSurface: darkBg,
      inversePrimary: primaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: darkBg,
      fontFamily: 'Poppins',

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: darkBorder.withOpacity(0.6), width: 1),
        ),
        color: darkCard,
        margin: EdgeInsets.zero,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCardAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: const Color(0xFF8888AA), fontSize: 13),
        hintStyle: TextStyle(color: const Color(0xFF5A5A7A), fontSize: 14),
        prefixIconColor: primaryColor.withOpacity(0.7),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: BorderSide(color: darkBorder, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: darkCardAlt,
        selectedColor: primaryColor.withOpacity(0.25),
        side: BorderSide(color: darkBorder, width: 1.2),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // Bottom App Bar
      bottomAppBarTheme: BottomAppBarThemeData(
        elevation: 0,
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const CircleBorder(),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.white;
          return const Color(0xFF5A5A7A);
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primaryColor;
          return darkCardAlt;
        }),
        trackOutlineColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.transparent;
          return darkBorder;
        }),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.15),
        inactiveTrackColor: darkBorder,
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF6B6B8A),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor.withOpacity(0.3), primaryColor.withOpacity(0.15)],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: darkBorder.withOpacity(0.6),
        thickness: 1,
        space: 1,
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        iconColor: primaryColor.withOpacity(0.8),
        tileColor: Colors.transparent,
      ),

      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: darkBorder,
        circularTrackColor: darkBorder,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Color(0xFFB0B0D0),
          height: 1.6,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        modalBackgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
      ),

      // Snack Bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCardAlt,
        contentTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, letterSpacing: -1.0, color: Colors.white),
        displayMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Colors.white),
        displaySmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, letterSpacing: -0.5, color: Colors.white),
        headlineLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, letterSpacing: -0.3, color: Colors.white),
        headlineMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, letterSpacing: -0.2, color: Colors.white),
        headlineSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, letterSpacing: 0.1, color: Colors.white),
        titleMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, letterSpacing: 0.1, color: Colors.white),
        titleSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: Colors.white),
        bodyLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, letterSpacing: 0.1, color: Color(0xFFD0D0E8)),
        bodyMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, color: Color(0xFFB8B8D8)),
        bodySmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, color: Color(0xFF9090B8)),
        labelLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white),
        labelMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: Color(0xFFD0D0E8)),
        labelSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: Color(0xFF9090B8)),
      ),
    );
  }
}

// ─── UTILITY FUNCTIONS ────────────────────────────────────────────────────────

String formatCurrency(double amount, {String currency = 'IDR'}) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: currency == 'IDR' ? 'Rp ' : '$currency ',
    decimalDigits: currency == 'IDR' ? 0 : 2,
  );
  return formatter.format(amount);
}

String formatDate(DateTime date) => DateFormat('dd MMM yyyy', 'id_ID').format(date);
String formatDateTime(DateTime date) => DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
String formatMonth(DateTime date) => DateFormat('MMMM yyyy', 'id_ID').format(date);
String formatShortDate(DateTime date) => DateFormat('dd MMM', 'id_ID').format(date);

Color colorFromHex(String hex) {
  try {
    final h = hex.replaceAll('#', '').trim();
    if (h.length != 6) return AppTheme.primaryColor;
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return AppTheme.primaryColor;
  }
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

// ─── BEAUTIFUL CARD DECORATION HELPERS ───────────────────────────────────────

BoxDecoration glassCard({bool isDark = true}) {
  return BoxDecoration(
    color: isDark
        ? AppTheme.darkCard.withOpacity(0.8)
        : Colors.white.withOpacity(0.9),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: isDark
          ? AppTheme.darkBorder.withOpacity(0.5)
          : AppTheme.lightBorder,
      width: 1,
    ),
    boxShadow: isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight,
  );
}

BoxDecoration gradientCard(List<Color> colors, {double radius = 20}) {
  return BoxDecoration(
    gradient: LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: colors.first.withOpacity(0.3),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

BoxDecoration primaryCard({bool isDark = true}) {
  return gradientCard([AppTheme.primaryColor, AppTheme.primaryDark]);
}

BoxDecoration goldCard() {
  return gradientCard([
    const Color(0xFFE8C44A),
    const Color(0xFFD4A017),
  ]);
}

BoxDecoration incomeCard() {
  return gradientCard([AppTheme.incomeColor, const Color(0xFF059669)]);
}

BoxDecoration expenseCard() {
  return gradientCard([AppTheme.expenseColor, const Color(0xFFDC2626)]);
}