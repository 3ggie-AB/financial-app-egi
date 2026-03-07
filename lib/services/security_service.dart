// lib/services/security_service.dart
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityService extends ChangeNotifier {
  static final SecurityService instance = SecurityService._internal();
  SecurityService._internal();

  final _localAuth = LocalAuthentication();

  static const _prefsPinHash = 'security_pin_hash';
  static const _prefsPinEnabled = 'security_pin_enabled';
  static const _prefsBioEnabled = 'security_bio_enabled';
  static const _prefsLockEnabled = 'security_lock_enabled';

  bool _pinEnabled = false;
  bool _bioEnabled = false;
  bool _lockEnabled = false;
  bool _isUnlocked = false;
  bool _bioAvailable = false;

  bool get pinEnabled => _pinEnabled;
  bool get bioEnabled => _bioEnabled;
  bool get lockEnabled => _lockEnabled;
  bool get isUnlocked => _isUnlocked;
  bool get bioAvailable => _bioAvailable;
  bool get hasPin => _pinEnabled;

  // ─── INIT ──────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _pinEnabled = prefs.getBool(_prefsPinEnabled) ?? false;
    _bioEnabled = prefs.getBool(_prefsBioEnabled) ?? false;
    _lockEnabled = prefs.getBool(_prefsLockEnabled) ?? false;

    // Cek ketersediaan biometric
    try {
      _bioAvailable = await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } catch (_) {
      _bioAvailable = false;
    }

    // Kalau tidak ada lock, langsung unlock
    if (!_lockEnabled) _isUnlocked = true;

    notifyListeners();
  }

  // ─── SET PIN ───────────────────────────────────────────────────
  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsPinHash, hash);
    await prefs.setBool(_prefsPinEnabled, true);
    await prefs.setBool(_prefsLockEnabled, true);
    _pinEnabled = true;
    _lockEnabled = true;
    notifyListeners();
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsPinHash);
    await prefs.setBool(_prefsPinEnabled, false);
    await prefs.setBool(_prefsBioEnabled, false);
    await prefs.setBool(_prefsLockEnabled, false);
    _pinEnabled = false;
    _bioEnabled = false;
    _lockEnabled = false;
    _isUnlocked = true;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_prefsPinHash);
    if (storedHash == null) return false;
    return _hashPin(pin) == storedHash;
  }

  // ─── BIOMETRIC ────────────────────────────────────────────────
  Future<void> setBioEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsBioEnabled, enabled);
    _bioEnabled = enabled;
    notifyListeners();
  }

  Future<bool> authenticateWithBio() async {
    if (!_bioAvailable) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Verifikasi identitas untuk membuka FinanceKu',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint('Bio auth error: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  // ─── LOCK / UNLOCK ─────────────────────────────────────────────
  void unlock() {
    _isUnlocked = true;
    notifyListeners();
  }

  void lock() {
    if (_lockEnabled) {
      _isUnlocked = false;
      notifyListeners();
    }
  }

  // ─── HELPER ───────────────────────────────────────────────────
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + 'financeku_salt_2024');
    return sha256.convert(bytes).toString();
  }
}