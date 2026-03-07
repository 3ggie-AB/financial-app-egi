// lib/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/onboarding_service.dart';
import '../../services/database_service.dart';
import '../../providers/finance_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isReplay;
  const OnboardingScreen({super.key, this.isReplay = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentStep = 0;
  static const _totalSteps = 5;

  // Step data
  final _nameCtrl = TextEditingController();
  String _selectedCurrency = 'IDR';
  String _accountName = '';
  String _accountType = 'cash';
  String _accountColor = '#4CAF50';
  double _initialBalance = 0;
  final _balanceCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  bool _isSaving = false;

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _currencies = [
    {'code': 'IDR', 'name': 'Rupiah', 'flag': '🇮🇩', 'symbol': 'Rp'},
    {'code': 'USD', 'name': 'US Dollar', 'flag': '🇺🇸', 'symbol': '\$'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'flag': '🇸🇬', 'symbol': 'S\$'},
    {'code': 'MYR', 'name': 'Ringgit', 'flag': '🇲🇾', 'symbol': 'RM'},
    {'code': 'EUR', 'name': 'Euro', 'flag': '🇪🇺', 'symbol': '€'},
    {'code': 'JPY', 'name': 'Yen', 'flag': '🇯🇵', 'symbol': '¥'},
    {'code': 'GBP', 'name': 'Pound', 'flag': '🇬🇧', 'symbol': '£'},
    {'code': 'AUD', 'name': 'AUD', 'flag': '🇦🇺', 'symbol': 'A\$'},
  ];

  final _accountTypes = [
    {'type': 'cash', 'label': 'Tunai', 'icon': Icons.account_balance_wallet_rounded, 'color': '#4CAF50'},
    {'type': 'bank', 'label': 'Bank', 'icon': Icons.account_balance_rounded, 'color': '#2196F3'},
    {'type': 'ewallet', 'label': 'E-Wallet', 'icon': Icons.phone_android_rounded, 'color': '#00BCD4'},
    {'type': 'credit', 'label': 'Kredit', 'icon': Icons.credit_card_rounded, 'color': '#FF5722'},
  ];

  final _features = [
    {
      'icon': Icons.receipt_long_rounded,
      'color': Color(0xFF6C63FF),
      'title': 'Catat Transaksi',
      'desc': 'Input pemasukan & pengeluaran dengan cepat. Scan nota otomatis jadi data!',
    },
    {
      'icon': Icons.pie_chart_rounded,
      'color': Color(0xFF4CAF50),
      'title': 'Analisis Keuangan',
      'desc': 'Lihat breakdown pengeluaran per kategori dengan grafik yang mudah dipahami.',
    },
    {
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFF2196F3),
      'title': 'Budget & Goals',
      'desc': 'Set batas pengeluaran per kategori dan target tabungan impian kamu.',
    },
    {
      'icon': Icons.auto_awesome_rounded,
      'color': Color(0xFFFF9800),
      'title': 'AI Keuangan',
      'desc': 'Asisten AI yang kasih insight dan saran hemat berdasarkan pola keuanganmu.',
    },
    {
      'icon': Icons.sync_rounded,
      'color': Color(0xFF9C27B0),
      'title': 'Sync Otomatis',
      'desc': 'Data tersinkron ke Google Drive — aman dan bisa diakses dari mana saja.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
    _slideCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.05, 0), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _accountNameCtrl.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    // Validasi per step
    if (_currentStep == 1 && _nameCtrl.text.trim().isEmpty) {
      _showError('Masukkan nama kamu dulu ya!');
      return;
    }
    if (_currentStep == 3) {
      if (_accountNameCtrl.text.trim().isEmpty) {
        _showError('Masukkan nama rekening');
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      _animateToNext();
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep++);
    } else {
      await _finish();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep--);
    }
  }

  void _animateToNext() {
    _fadeCtrl.reset();
    _slideCtrl.reset();
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  Future<void> _finish() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final onboarding = OnboardingService.instance;
    await onboarding.saveUserName(_nameCtrl.text.trim());
    await onboarding.saveCurrency(_selectedCurrency);

    // Buat rekening pertama
    final fp = context.read<FinanceProvider>();
    final accountName = _accountNameCtrl.text.trim().isEmpty
        ? 'Rekening Utama'
        : _accountNameCtrl.text.trim();
    final balance = double.tryParse(_balanceCtrl.text.replaceAll('.', '')) ?? 0;

    await fp.addAccount(Account(
      id: DatabaseService.instance.newId,
      name: accountName,
      type: _accountType,
      balance: balance,
      currency: _selectedCurrency,
      color: _accountColor,
      createdAt: DateTime.now(),
    ));

    await onboarding.complete();
    setState(() => _isSaving = false);

    if (mounted) {
      if (widget.isReplay) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainScreen(),
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    }
  }

  void _showError(String msg) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red[400],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0D0D1A), const Color(0xFF1A1A2E)]
                : [const Color(0xFF1A1A2E), const Color(0xFF2D2D5E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Progress Bar ──────────────────────────────────
              _buildProgressBar(),

              // ── Page Content ─────────────────────────────────
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildWelcomeStep(),
                    _buildNameStep(),
                    _buildCurrencyStep(),
                    _buildAccountStep(),
                    _buildTutorialStep(),
                  ],
                ),
              ),

              // ── Navigation Buttons ────────────────────────────
              _buildNavButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                GestureDetector(
                  onTap: _prevStep,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 18),
                  ),
                )
              else
                const SizedBox(width: 36),
              Text(
                '${_currentStep + 1} / $_totalSteps',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              if (_currentStep < _totalSteps - 1 && _currentStep != 0)
                GestureDetector(
                  onTap: () async => await _finish(),
                  child: Text(
                    'Lewati',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                )
              else
                const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 1: WELCOME ───────────────────────────────────────────
  Widget _buildWelcomeStep() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animasi
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (_, value, child) => Transform.scale(
                  scale: value,
                  child: child,
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Selamat Datang\ndi FinanceKu!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Aplikasi keuangan pribadi yang cerdas.\nCatat, analisis, dan kelola keuanganmu\ndengan mudah.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
              // Feature pills
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  '💰 Catat Transaksi',
                  '📊 Analisis AI',
                  '🔄 Auto Sync',
                  '🔐 Aman & Privat',
                ].map((f) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Text(f,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      )),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── STEP 2: NAMA ──────────────────────────────────────────────
  Widget _buildNameStep() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('👋', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 20),
              const Text(
                'Halo!\nSiapa namamu?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kami akan menyapa kamu dengan nama ini.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: TextField(
                  controller: _nameCtrl,
                  autofocus: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Nama kamu...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 22,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                    prefixIcon: const Icon(Icons.person_rounded,
                        color: Colors.white54),
                  ),
                  onSubmitted: (_) => _nextStep(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── STEP 3: MATA UANG ─────────────────────────────────────────
  Widget _buildCurrencyStep() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text('💱', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 20),
              const Text(
                'Mata Uang\nUtama',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Semua transaksi akan dicatat dalam mata uang ini.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _currencies.length,
                  itemBuilder: (_, i) {
                    final c = _currencies[i];
                    final isSelected = _selectedCurrency == c['code'];
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCurrency = c['code']!);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.white.withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Text(c['flag']!,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    c['code']!,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    c['name']!,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppTheme.primaryColor, size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── STEP 4: REKENING PERTAMA ──────────────────────────────────
  Widget _buildAccountStep() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text('🏦', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 20),
              const Text(
                'Rekening\nPertama',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tambah rekening utama kamu sekarang.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),

              // Account type selector
              const Text('Jenis Rekening',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Row(
                children: _accountTypes.map((t) {
                  final isSelected = _accountType == t['type'];
                  final color = colorFromHex(t['color'] as String);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _accountType = t['type'] as String;
                          _accountColor = t['color'] as String;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : Colors.white.withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(t['icon'] as IconData,
                                color: isSelected ? color : Colors.white54,
                                size: 20),
                            const SizedBox(height: 4),
                            Text(
                              t['label'] as String,
                              style: TextStyle(
                                color: isSelected ? color : Colors.white54,
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Nama rekening
              _darkTextField(
                controller: _accountNameCtrl,
                hint: 'Nama rekening (misal: BCA, Dompet)',
                icon: Icons.label_rounded,
              ),
              const SizedBox(height: 12),

              // Saldo awal
              _darkTextField(
                controller: _balanceCtrl,
                hint: 'Saldo awal (boleh 0)',
                icon: Icons.payments_rounded,
                keyboardType: TextInputType.number,
                prefix: '$_selectedCurrency ',
              ),
              const SizedBox(height: 8),
              Text(
                'Isi saldo sesuai kondisi rekening kamu saat ini.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── STEP 5: TUTORIAL ──────────────────────────────────────────
  Widget _buildTutorialStep() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                'Halo, ${_nameCtrl.text.trim().isEmpty ? "Kamu" : _nameCtrl.text.trim()}! 🎉',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sebelum mulai, kenalan dulu\ndengan fitur utama FinanceKu.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _features.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final f = _features[i];
                    final color = f['color'] as Color;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + i * 80),
                      curve: Curves.easeOut,
                      builder: (_, value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: color.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(f['icon'] as IconData,
                                  color: color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f['title'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    f['desc'] as String,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 11,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── NAV BUTTONS ───────────────────────────────────────────────
  Widget _buildNavButtons() {
    final isLast = _currentStep == _totalSteps - 1;
    final label = switch (_currentStep) {
      0 => 'Mulai Setup',
      1 => 'Lanjut',
      2 => 'Pilih & Lanjut',
      3 => 'Buat Rekening',
      _ => 'Mulai FinanceKu! 🚀',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: isLast
                ? const Color(0xFF4CAF50)
                : AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    if (!isLast) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────
  Widget _darkTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? prefix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          prefixText: prefix,
          prefixStyle: const TextStyle(
              color: Colors.white70, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

Color colorFromHex(String hex) {
  try {
    final h = hex.replaceAll('#', '').trim();
    if (h.length != 6) return Colors.blue;
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return Colors.blue;
  }
}