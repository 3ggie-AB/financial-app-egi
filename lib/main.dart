import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/finance_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_screen.dart';
import 'services/database_service.dart';
import 'services/backup_service.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/currency_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  await DatabaseService.instance.initialize();
  await CurrencyService.instance.loadSavedCurrency();
  await BackupService.instance.init();
  await NotificationService.instance.init();
  await NotificationService.instance.rescheduleAll();
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
            home: const SyncCheckWrapper(),
          );
        },
      ),
    );
  }
}

class SyncCheckWrapper extends StatefulWidget {
  const SyncCheckWrapper({super.key});

  @override
  State<SyncCheckWrapper> createState() => _SyncCheckWrapperState();
}

class _SyncCheckWrapperState extends State<SyncCheckWrapper>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkOnOpen();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        await context.read<FinanceProvider>().checkTodayTransactionReminder();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkOnOpen();
      context.read<FinanceProvider>().checkTodayTransactionReminder();
    }
  }

  Future<void> _checkOnOpen() async {
    if (!mounted) return;
    final backup = BackupService.instance;
    if (!backup.isSignedIn || !backup.autoSyncEnabled) return;

    final remoteNewer = await backup.checkRemoteNewer();
    if (!remoteNewer || !mounted) return;

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.sync_rounded, color: Color(0xFF6C63FF), size: 44),
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
      final err = await backup.restoreFromDrive();
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
  Widget build(BuildContext context) => const MainScreen();
}