import 'package:flutter/material.dart';
import 'models/models.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'providers/finance_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/theme_provider.dart';
import 'screens/main_screen.dart';
import 'screens/security/lock_screen.dart';
import 'screens/transactions/add_transaction_screen.dart';
import 'services/database_service.dart';
import 'services/backup_service.dart';
import 'services/notification_service.dart';
import 'services/security_service.dart';
import 'services/recurring_service.dart';
import 'services/widget_service.dart';
import 'services/ai_service.dart';
import 'utils/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/currency_service.dart';
import 'services/onboarding_service.dart';
import 'screens/onboarding/onboarding_screen.dart';

// HomeWidget hanya import di platform yang support
import 'package:home_widget/home_widget.dart'
    if (dart.library.io) 'package:home_widget/home_widget.dart';

bool get _isDesktopPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (e) {
    debugPrint('Warning: assets/.env tidak ditemukan: $e');
  }
  await initializeDateFormatting('id', null);
  await DatabaseService.instance.initialize();
  await CurrencyService.instance.loadSavedCurrency();
  await BackupService.instance.init();

  // Notifikasi tidak support di Windows/Linux/macOS desktop
  if (!_isDesktopPlatform) {
    await NotificationService.instance.init();
    await NotificationService.instance.rescheduleAll();
  }

  await SecurityService.instance.init();
  await AiService.instance.init();
  await OnboardingService.instance.init();

  // Widget service tidak support di Windows/Linux
  if (!_isDesktopPlatform) {
    await WidgetService.instance.init();
  }

  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: BackupService.instance),
        ChangeNotifierProvider.value(value: SecurityService.instance),
        ChangeNotifierProvider.value(value: AiService.instance),
        ChangeNotifierProvider(create: (_) => FinanceProvider()..loadAll()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'FinanceKu',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AppWrapper(),
          );
        },
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});
  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  bool _initialized = false;
  bool _navigateToAddTransaction = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onAppStart());

    // HomeWidget hanya di mobile
    if (!_isDesktopPlatform) {
      HomeWidget.widgetClicked.listen(_handleWidgetClick);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Jangan lock di desktop — hanya di mobile
      if (!_isDesktopPlatform) {
        SecurityService.instance.lock();
      }
      _runBackgroundTasks();
    }
  }

  void _handleWidgetClick(Uri? uri) {
    if (uri?.host == 'add_transaction') {
      setState(() => _navigateToAddTransaction = true);
    }
  }

  Future<void> _onAppStart() async {
    // Deep link dari widget hanya di mobile
    if (!_isDesktopPlatform) {
      final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initialUri?.host == 'add_transaction') {
        setState(() => _navigateToAddTransaction = true);
      }
    }

    await _runBackgroundTasks();
    if (mounted) setState(() => _initialized = true);
  }

  Future<void> _runBackgroundTasks() async {
    if (!mounted) return;

    // Generate recurring transactions
    final generated = await RecurringService.instance.checkAndGenerate();
    if (generated.isNotEmpty && mounted) {
      context.read<FinanceProvider>().loadAll();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${generated.length} transaksi berulang otomatis dibuat'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF6C63FF),
      ));
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Reminder hanya di mobile
    if (!_isDesktopPlatform) {
      await context.read<FinanceProvider>().checkTodayTransactionReminder();
    }

    // Update widget data hanya di mobile
    if (!_isDesktopPlatform) {
      final fp = context.read<FinanceProvider>();
      final now = DateTime.now();
      final todayExpense = fp.transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day)
          .fold(0.0, (s, t) => s + t.amount);

      await WidgetService.instance.updateWidget(
        totalBalance: fp.totalBalance,
        monthlyIncome: fp.monthlyIncome(now),
        monthlyExpense: fp.monthlyExpense(now),
        todayExpense: todayExpense,
      );
    }

    // Cek sync Drive
    if (!mounted) return;
    final backup = BackupService.instance;
    if (backup.isSignedIn && backup.autoSyncEnabled && mounted) {
      final remoteNewer = await backup.checkRemoteNewer();
      if (remoteNewer && mounted) await _showSyncDialog();
    }
  }

  Future<void> _showSyncDialog() async {
    if (!mounted) return;
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.sync_rounded,
            color: Color(0xFF6C63FF), size: 44),
        title: const Text('Data Lebih Baru Tersedia',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Ditemukan data yang lebih baru di Google Drive.\n\n'
          'Mau ambil data terbaru dari Drive, atau tetap pakai data lokal?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.phone_android_rounded, size: 16),
            label: const Text('Pakai Lokal'),
            onPressed: () => Navigator.pop(ctx, 'local'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.cloud_download_rounded, size: 16),
            label: const Text('Ambil dari Drive'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, 'drive'),
          ),
        ],
      ),
    );
    if (action == 'drive' && mounted) {
      final err = await BackupService.instance.restoreFromDrive();
      if (mounted) {
        context.read<FinanceProvider>().loadAll();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err ?? '✓ Data berhasil disinkronkan dari Drive'),
          backgroundColor: err != null ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityService>();

    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Cek onboarding dulu
    if (!OnboardingService.instance.completed) {
      return const OnboardingScreen();
    }

    // Lock screen hanya di mobile
    if (!_isDesktopPlatform &&
        security.lockEnabled &&
        !security.isUnlocked) {
      return LockScreen(onUnlocked: () => setState(() {}));
    }

    // Navigate dari widget (mobile only)
    if (!_isDesktopPlatform && _navigateToAddTransaction) {
      _navigateToAddTransaction = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        );
      });
    }

    return const MainScreen();
  }
}