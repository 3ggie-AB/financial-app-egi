// lib/services/onboarding_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static final OnboardingService instance = OnboardingService._internal();
  OnboardingService._internal();

  static const _prefsCompleted = 'onboarding_completed';
  static const _prefsUserName = 'user_name';
  static const _prefsCurrency = 'user_currency';

  bool _completed = false;
  String _userName = '';
  String _currency = 'IDR';

  bool get completed => _completed;
  String get userName => _userName;
  String get currency => _currency;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _completed = prefs.getBool(_prefsCompleted) ?? false;
    _userName = prefs.getString(_prefsUserName) ?? '';
    _currency = prefs.getString(_prefsCurrency) ?? 'IDR';
  }

  Future<void> saveUserName(String name) async {
    _userName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsUserName, name);
  }

  Future<void> saveCurrency(String currency) async {
    _currency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsCurrency, currency);
  }

  Future<void> complete() async {
    _completed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsCompleted, true);
  }

  Future<void> reset() async {
    _completed = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsCompleted, false);
  }
}