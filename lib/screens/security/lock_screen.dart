// lib/screens/security/lock_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/security_service.dart';
import '../../utils/app_theme.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  final _security = SecurityService.instance;
  String _pin = '';
  String _errorMsg = '';
  int _attempts = 0;
  bool _isLoading = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  static const _maxAttempts = 5;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );

    // Auto-trigger biometric saat screen muncul
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_security.bioEnabled && _security.bioAvailable) {
        _tryBiometric();
      }
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    setState(() => _isLoading = true);
    final success = await _security.authenticateWithBio();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _security.unlock();
      widget.onUnlocked();
    }
  }

  void _onKeyPress(String key) {
    if (_pin.length >= 6 || _isLoading) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin += key;
      _errorMsg = '';
    });
    if (_pin.length == 6) {
      _verifyPin();
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 200));

    final correct = await _security.verifyPin(_pin);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (correct) {
      HapticFeedback.mediumImpact();
      _security.unlock();
      widget.onUnlocked();
    } else {
      HapticFeedback.heavyImpact();
      _attempts++;
      _shakeCtrl.forward(from: 0);
      setState(() {
        _pin = '';
        _errorMsg = _attempts >= _maxAttempts
            ? 'Terlalu banyak percobaan. Coba lagi nanti.'
            : 'PIN salah. Sisa ${_maxAttempts - _attempts} percobaan.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D1A) : const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            // ── App Icon + Title ────────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'FinanceKu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Masukkan PIN untuk melanjutkan',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
              ),
            ),

            const Spacer(),

            // ── PIN Dots ────────────────────────────────────────
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) {
                final offset = _shakeAnim.value * 12 *
                    (0.5 - (_shakeAnim.value % 0.25) / 0.25).abs();
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: filled ? 16 : 14,
                    height: filled ? 16 : 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? AppTheme.primaryColor
                          : Colors.white.withOpacity(0.2),
                      boxShadow: filled
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.5),
                                blurRadius: 8,
                              )
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ),

            // ── Error Message ───────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _errorMsg.isEmpty ? 0 : 36,
              child: Center(
                child: Text(
                  _errorMsg,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ── Numpad ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _numRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _numRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _numRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Biometric button
                      _actionButton(
                        icon: _security.bioEnabled && _security.bioAvailable
                            ? Icons.fingerprint_rounded
                            : null,
                        onTap: _security.bioEnabled && _security.bioAvailable
                            ? _tryBiometric
                            : null,
                      ),
                      _numButton('0'),
                      _actionButton(
                        icon: Icons.backspace_outlined,
                        onTap: _pin.isEmpty ? null : _onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Loading indicator
            if (_isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _numRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map(_numButton).toList(),
    );
  }

  Widget _numButton(String key) {
    return GestureDetector(
      onTap: () => _onKeyPress(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: Text(
            key,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({IconData? icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        height: 72,
        child: Center(
          child: icon != null
              ? Icon(icon, color: Colors.white.withOpacity(onTap != null ? 0.8 : 0.2), size: 28)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}