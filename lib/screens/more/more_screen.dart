// screens/more/more_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../services/security_service.dart';
import '../../services/ai_service.dart';
import '../../services/onboarding_service.dart';
import '../categories/categories_screen.dart';
import '../tags/tags_screen.dart';
import '../backup/backup_screen.dart';
import '../budgets/budgets_screen.dart';
import '../notifications/notification_settings_screen.dart';
import '../security/security_settings_screen.dart';
import '../ai/ai_analysis_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../../utils/app_theme.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final security = context.watch<SecurityService>();
    final ai = context.watch<AiService>();
    final userName = OnboardingService.instance.userName;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(title: const Text('Lainnya')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [

          // ── User Profile Card ──────────────────────────────────
          if (userName.isNotEmpty) ...[
            _buildProfileCard(userName, isDark),
            const SizedBox(height: 24),
          ],

          // ── Kelola ────────────────────────────────────────────
          _sectionHeader('Kelola', isDark),
          const SizedBox(height: 10),
          _buildMenuGroup(isDark, [
            _MenuItemData(
              icon: Icons.category_rounded,
              label: 'Kategori',
              subtitle: 'Kelola kategori transaksi',
              color: AppTheme.transferColor,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CategoriesScreen())),
            ),
            _MenuItemData(
              icon: Icons.label_rounded,
              label: 'Tag',
              subtitle: 'Kelola tag transaksi',
              color: AppTheme.primaryColor,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TagsScreen())),
            ),
            _MenuItemData(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Budget',
              subtitle: 'Atur batas pengeluaran',
              color: AppTheme.goldColor,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const BudgetsScreen())),
            ),
          ]),
          const SizedBox(height: 24),

          // ── AI ────────────────────────────────────────────────
          _sectionHeader('🤖 AI Keuangan', isDark),
          const SizedBox(height: 10),
          _buildAiCard(context, ai, isDark),
          const SizedBox(height: 24),

          // ── Data & Backup ─────────────────────────────────────
          _sectionHeader('Data & Backup', isDark),
          const SizedBox(height: 10),
          _buildMenuGroup(isDark, [
            _MenuItemData(
              icon: Icons.backup_rounded,
              label: 'Backup & Sinkronisasi',
              subtitle: 'Google Drive · Auto Sync',
              color: AppTheme.incomeColor,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const BackupScreen())),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Notifikasi ────────────────────────────────────────
          _sectionHeader('Notifikasi', isDark),
          const SizedBox(height: 10),
          _buildMenuGroup(isDark, [
            _MenuItemData(
              icon: Icons.notifications_rounded,
              label: 'Pengaturan Notifikasi',
              subtitle: 'Budget warning · Ringkasan · Pengingat harian',
              color: const Color(0xFFB47AF7),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen())),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Keamanan ──────────────────────────────────────────
          _sectionHeader('Keamanan', isDark),
          const SizedBox(height: 10),
          _buildSecurityCard(context, security, isDark),
          const SizedBox(height: 24),

          // ── Tampilan ──────────────────────────────────────────
          _sectionHeader('Tampilan', isDark),
          const SizedBox(height: 10),
          _buildThemeCard(context, themeProvider, isDark),
          const SizedBox(height: 24),

          // ── Lainnya ───────────────────────────────────────────
          _sectionHeader('Lainnya', isDark),
          const SizedBox(height: 10),
          _buildMenuGroup(isDark, [
            _MenuItemData(
              icon: Icons.play_circle_outline_rounded,
              label: 'Ulangi Tutorial',
              subtitle: 'Lihat panduan fitur FinanceKu lagi',
              color: const Color(0xFF34D3C8),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const OnboardingScreen(isReplay: true))),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Zona Bahaya ───────────────────────────────────────
          _sectionHeader('Zona Bahaya', isDark),
          const SizedBox(height: 10),
          _buildDangerCard(context, isDark),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PROFILE CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildProfileCard(String userName, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1A0A3E), Color(0xFF0F0F28)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppTheme.heroGradientLight,
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(isDark ? 0.15 : 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            ),
            child: Center(
              child: Text(
                userName[0].toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $userName! 👋',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Semangat kelola keuanganmu!',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person_rounded,
              color: Colors.white.withOpacity(0.7),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MENU GROUP
  // ─────────────────────────────────────────────────────────────
  Widget _buildMenuGroup(bool isDark, List<_MenuItemData> items) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder.withOpacity(0.5) : AppTheme.lightBorder,
          width: 1,
        ),
        boxShadow: isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight,
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final isLast = i == items.length - 1;
          return Column(
            children: [
              _buildMenuItem(item, isDark),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 62,
                  endIndent: 16,
                  color: isDark
                      ? AppTheme.darkBorder.withOpacity(0.4)
                      : AppTheme.lightBorder,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItemData item, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF1A1040),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF7878A0)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? const Color(0xFF5A5A7A) : const Color(0xFFD1D5DB),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // AI CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildAiCard(BuildContext context, AiService ai, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AiAnalysisScreen())),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.15),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.08),
                    AppTheme.primaryColor.withOpacity(0.03),
                  ],
                ),
          color: isDark ? null : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(isDark ? 0.3 : 0.2),
            width: 1,
          ),
          boxShadow: isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight,
        ),
        child: Row(
          children: [
            // Animated-looking AI icon
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.primaryShadow,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'AI Keuangan',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF1A1040),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (ai.hasApiKey)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.incomeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.incomeColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5, height: 5,
                                decoration: BoxDecoration(
                                  color: AppTheme.incomeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ON',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: AppTheme.incomeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ai.hasApiKey
                        ? 'Aktif · ${ai.model.split('-').take(2).join('-')}'
                        : 'Analisis & saran keuangan personal · Gratis',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF9090B8)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppTheme.primaryColor.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SECURITY CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildSecurityCard(
      BuildContext context, SecurityService security, bool isDark) {
    final isActive = security.lockEnabled;
    final activeColor = AppTheme.incomeColor;
    final inactiveColor = isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF);

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SecuritySettingsScreen())),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? activeColor.withOpacity(0.25)
                : isDark ? AppTheme.darkBorder.withOpacity(0.5) : AppTheme.lightBorder,
            width: 1,
          ),
          boxShadow: isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight,
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: (isActive ? activeColor : inactiveColor).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isActive ? activeColor : inactiveColor).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                isActive ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: isActive ? activeColor : inactiveColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PIN & Biometrik',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1A1040),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActive
                        ? 'Aktif · ${security.bioEnabled ? "Fingerprint ON" : "PIN only"}'
                        : 'Tidak aktif · Ketuk untuk mengaktifkan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: isActive
                          ? activeColor
                          : isDark
                              ? const Color(0xFF7878A0)
                              : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: activeColor.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ON',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: activeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? const Color(0xFF5A5A7A) : const Color(0xFFD1D5DB),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // THEME CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildThemeCard(
      BuildContext context, ThemeProvider themeProvider, bool isDark) {
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder.withOpacity(0.5) : AppTheme.lightBorder,
          width: 1,
        ),
        boxShadow: isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight,
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF7878A0).withOpacity(0.12)
                  : AppTheme.goldColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? const Color(0xFF7878A0).withOpacity(0.2)
                    : AppTheme.goldColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: isDarkMode ? const Color(0xFFB0B0D0) : AppTheme.goldColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tema Tampilan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1A1040),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDarkMode ? 'Mode Gelap aktif' : 'Mode Terang aktif',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF7878A0)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          // Custom toggle
          GestureDetector(
            onTap: () => themeProvider
                .setTheme(isDarkMode ? ThemeMode.light : ThemeMode.dark),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 52, height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: isDarkMode ? AppTheme.primaryGradient : null,
                color: isDarkMode ? null : AppTheme.lightBorder,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: isDarkMode
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 22, height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    isDarkMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                    size: 12,
                    color: isDarkMode
                        ? AppTheme.primaryColor
                        : AppTheme.goldColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DANGER CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildDangerCard(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _showDeleteWarning1(context),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.expenseColor.withOpacity(0.06)
              : AppTheme.expenseColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.expenseColor.withOpacity(0.3),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppTheme.expenseColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.expenseColor.withOpacity(0.2), width: 1),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: AppTheme.expenseColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hapus Semua Data',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppTheme.expenseColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hapus seluruh transaksi, rekening, kategori & tag',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppTheme.expenseColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.expenseColor.withOpacity(0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SECTION HEADER
  // ─────────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? const Color(0xFF7878A0) : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE DIALOGS
  // ─────────────────────────────────────────────────────────────
  void _showDeleteWarning1(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        title: Column(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1.5),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              'Hapus Semua Data?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF1A1040),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tindakan ini akan menghapus SEMUA data termasuk:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: isDark ? const Color(0xFFB0B0D0) : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  'Seluruh transaksi',
                  'Semua rekening',
                  'Semua kategori & tag',
                  'Semua budget',
                ].map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle_outline_rounded,
                          size: 14,
                          color: AppTheme.expenseColor.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Text(
                        item,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFFD0D0E8)
                              : const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(
                      color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFB0B0D0) : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showDeleteWarning2(context);
                  },
                  child: const Text(
                    'Lanjutkan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteWarning2(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            title: Column(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.expenseColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.expenseColor.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.delete_forever_rounded,
                      color: AppTheme.expenseColor, size: 30),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Yakin Ingin Menghapus?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: AppTheme.expenseColor,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.expenseColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.expenseColor.withOpacity(0.2), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppTheme.expenseColor, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Konfirmasi terakhir.\nSemua data akan PERMANEN terhapus!',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppTheme.expenseColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pastikan sudah melakukan backup sebelum melanjutkan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF7878A0)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          isDeleting ? null : () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(
                          color: isDark
                              ? AppTheme.darkBorder
                              : AppTheme.lightBorder,
                        ),
                      ),
                      child: Text(
                        'Batalkan',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFB0B0D0)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.expenseColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isDeleting
                          ? null
                          : () async {
                              setState(() => isDeleting = true);
                              await context
                                  .read<FinanceProvider>()
                                  .deleteAllData();
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(children: [
                                      Icon(Icons.check_circle_outline,
                                          color: Colors.white, size: 18),
                                      SizedBox(width: 10),
                                      Text(
                                        'Semua data berhasil dihapus',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ]),
                                    backgroundColor: AppTheme.incomeColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            },
                      child: isDeleting
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text(
                              'Hapus Semua',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA CLASS
// ─────────────────────────────────────────────────────────────────────────────
class _MenuItemData {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuItemData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}