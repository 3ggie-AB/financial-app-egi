// lib/screens/security/security_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/security_service.dart';
import '../../utils/app_theme.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final _security = SecurityService.instance;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Keamanan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status Card ────────────────────────────────────────
          Card(
            color: _security.lockEnabled
                ? Colors.green.withOpacity(0.08)
                : Colors.orange.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (_security.lockEnabled ? Colors.green : Colors.orange)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _security.lockEnabled
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded,
                      color: _security.lockEnabled ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _security.lockEnabled ? 'App Terkunci' : 'App Tidak Terkunci',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _security.lockEnabled ? Colors.green : Colors.orange,
                          ),
                        ),
                        Text(
                          _security.lockEnabled
                              ? 'PIN aktif · Proteksi menyala'
                              : 'Aktifkan PIN untuk proteksi data',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── PIN Section ────────────────────────────────────────
          _sectionHeader('🔐 PIN'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.pin_rounded, color: scheme.primary),
                  ),
                  title: Text(
                    _security.pinEnabled ? 'Ubah PIN' : 'Buat PIN',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    _security.pinEnabled
                        ? 'Ganti PIN yang sudah ada'
                        : '6 digit angka untuk proteksi app',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showSetPinFlow(context),
                ),
                if (_security.pinEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.no_encryption_rounded, color: Colors.red),
                    ),
                    title: const Text('Hapus PIN',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                    subtitle: const Text('Nonaktifkan proteksi PIN',
                        style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.red),
                    onTap: () => _confirmRemovePin(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Biometric Section ──────────────────────────────────
          _sectionHeader('👆 Biometrik'),
          Card(
            child: Column(
              children: [
                if (!_security.bioAvailable)
                  const ListTile(
                    leading: Icon(Icons.info_outline_rounded, color: Colors.grey),
                    title: Text('Biometrik Tidak Tersedia',
                        style: TextStyle(color: Colors.grey)),
                    subtitle: Text(
                        'Perangkat tidak mendukung fingerprint/face ID',
                        style: TextStyle(fontSize: 12)),
                  )
                else
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.fingerprint_rounded, color: Colors.blue),
                    ),
                    title: const Text('Fingerprint / Face ID',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      _security.pinEnabled
                          ? 'Buka app dengan biometrik'
                          : 'Aktifkan PIN terlebih dahulu',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _security.bioEnabled,
                    onChanged: _security.pinEnabled
                        ? (v) async {
                            if (v) {
                              // Test biometric sebelum enable
                              final ok = await _security.authenticateWithBio();
                              if (ok) {
                                await _security.setBioEnabled(true);
                                setState(() {});
                              } else if (mounted) {
                                _showSnack('Verifikasi biometrik gagal');
                              }
                            } else {
                              await _security.setBioEnabled(false);
                              setState(() {});
                            }
                          }
                        : null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Info ───────────────────────────────────────────────
          Card(
            color: Colors.blue.withOpacity(0.06),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.shield_rounded, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Text('Keamanan Data', style: TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  SizedBox(height: 8),
                  Text(
                    '• PIN disimpan terenkripsi di perangkat\n'
                    '• PIN tidak pernah dikirim ke server manapun\n'
                    '• Jika lupa PIN, data tidak bisa dipulihkan\n'
                    '• Disarankan backup data sebelum mengaktifkan PIN',
                    style: TextStyle(fontSize: 12, height: 1.8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── SET PIN FLOW ───────────────────────────────────────────────
  void _showSetPinFlow(BuildContext context) {
    if (_security.pinEnabled) {
      // Verify old PIN first
      _showPinInput(
        context,
        title: 'Masukkan PIN Lama',
        onComplete: (oldPin) async {
          final correct = await _security.verifyPin(oldPin);
          if (correct) {
            if (mounted) Navigator.pop(context);
            _showNewPinInput(context);
          } else {
            return 'PIN salah';
          }
          return null;
        },
      );
    } else {
      _showNewPinInput(context);
    }
  }

  void _showNewPinInput(BuildContext context) {
    String? firstPin;
    _showPinInput(
      context,
      title: 'Buat PIN Baru',
      subtitle: 'Masukkan 6 digit PIN',
      onComplete: (pin) async {
        if (firstPin == null) {
          firstPin = pin;
          if (mounted) Navigator.pop(context);
          _showPinInput(
            context,
            title: 'Konfirmasi PIN',
            subtitle: 'Masukkan PIN yang sama',
            onComplete: (confirmPin) async {
              if (confirmPin != firstPin) return 'PIN tidak cocok';
              await _security.setPin(confirmPin);
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
                _showSnack('✓ PIN berhasil diaktifkan!');
              }
              return null;
            },
          );
        }
        return null;
      },
    );
  }

  void _showPinInput(
    BuildContext context, {
    required String title,
    String? subtitle,
    required Future<String?> Function(String pin) onComplete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _PinInputSheet(
        title: title,
        subtitle: subtitle,
        onComplete: onComplete,
      ),
    );
  }

  Future<void> _confirmRemovePin(BuildContext context) async {
    // Verifikasi PIN dulu sebelum hapus
    _showPinInput(
      context,
      title: 'Konfirmasi Hapus PIN',
      subtitle: 'Masukkan PIN saat ini',
      onComplete: (pin) async {
        final correct = await _security.verifyPin(pin);
        if (!correct) return 'PIN salah';
        await _security.removePin();
        if (mounted) {
          Navigator.pop(context);
          setState(() {});
          _showSnack('PIN berhasil dihapus');
        }
        return null;
      },
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.green,
    ));
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
      );
}

// ── PIN INPUT SHEET ────────────────────────────────────────────────────────
class _PinInputSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Future<String?> Function(String pin) onComplete;

  const _PinInputSheet({
    required this.title,
    this.subtitle,
    required this.onComplete,
  });

  @override
  State<_PinInputSheet> createState() => _PinInputSheetState();
}

class _PinInputSheetState extends State<_PinInputSheet>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _error = '';
  bool _isLoading = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onKey(String key) {
    if (_pin.length >= 6 || _isLoading) return;
    HapticFeedback.lightImpact();
    setState(() { _pin += key; _error = ''; });
    if (_pin.length == 6) _submit();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final error = await widget.onComplete(_pin);
    if (!mounted) return;
    if (error != null) {
      HapticFeedback.heavyImpact();
      _shakeCtrl.forward(from: 0);
      setState(() { _isLoading = false; _pin = ''; _error = error; });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Text(widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(widget.subtitle!,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
          const SizedBox(height: 24),

          // PIN dots
          AnimatedBuilder(
            animation: _shakeAnim,
            builder: (_, child) {
              final offset = _shakeAnim.value * 10 *
                  (0.5 - (_shakeAnim.value % 0.25) / 0.25).abs();
              return Transform.translate(offset: Offset(offset, 0), child: child);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final filled = i < _pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppTheme.primaryColor : Colors.grey[300],
                  ),
                );
              }),
            ),
          ),

          // Error
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _error.isEmpty ? 0 : 32,
            child: Center(
              child: Text(_error,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 16),

          // Numpad
          ...['123', '456', '789'].map((row) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.split('').map(_buildKey).toList(),
            ),
          )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 64),
              _buildKey('0'),
              SizedBox(
                width: 64, height: 64,
                child: IconButton(
                  onPressed: _onDelete,
                  icon: const Icon(Icons.backspace_outlined),
                ),
              ),
            ],
          ),

          if (_isLoading) ...[
            const SizedBox(height: 12),
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],

          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String key) {
    return GestureDetector(
      onTap: () => _onKey(key),
      child: Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(key,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w400)),
        ),
      ),
    );
  }
}