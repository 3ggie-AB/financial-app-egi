// services/currency_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;
  final String flag;
  final String locale;
  final int decimalDigits;

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    required this.locale,
    this.decimalDigits = 2,
  });
}

class CurrencyService {
  static final CurrencyService instance = CurrencyService._internal();
  CurrencyService._internal();

  String _baseCurrency = 'IDR';
  Map<String, double> _rates = {'IDR': 1.0};
  DateTime? _lastFetch;
  static const _cacheDuration = Duration(hours: 6);

  String get baseCurrency => _baseCurrency;

  static const List<CurrencyInfo> supportedCurrencies = [
    CurrencyInfo(code: 'IDR', name: 'Rupiah Indonesia', symbol: 'Rp', flag: '🇮🇩', locale: 'id_ID', decimalDigits: 0),
    CurrencyInfo(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸', locale: 'en_US'),
    CurrencyInfo(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺', locale: 'de_DE'),
    CurrencyInfo(code: 'JPY', name: 'Japanese Yen', symbol: '¥', flag: '🇯🇵', locale: 'ja_JP', decimalDigits: 0),
    CurrencyInfo(code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧', locale: 'en_GB'),
    CurrencyInfo(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$', flag: '🇸🇬', locale: 'en_SG'),
    CurrencyInfo(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM', flag: '🇲🇾', locale: 'ms_MY'),
    CurrencyInfo(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$', flag: '🇦🇺', locale: 'en_AU'),
    CurrencyInfo(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳', locale: 'zh_CN'),
    CurrencyInfo(code: 'KRW', name: 'South Korean Won', symbol: '₩', flag: '🇰🇷', locale: 'ko_KR', decimalDigits: 0),
    CurrencyInfo(code: 'THB', name: 'Thai Baht', symbol: '฿', flag: '🇹🇭', locale: 'th_TH'),
    CurrencyInfo(code: 'HKD', name: 'Hong Kong Dollar', symbol: 'HK\$', flag: '🇭🇰', locale: 'zh_HK'),
    CurrencyInfo(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$', flag: '🇨🇦', locale: 'en_CA'),
    CurrencyInfo(code: 'CHF', name: 'Swiss Franc', symbol: 'Fr', flag: '🇨🇭', locale: 'de_CH'),
    CurrencyInfo(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼', flag: '🇸🇦', locale: 'ar_SA'),
    CurrencyInfo(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ', flag: '🇦🇪', locale: 'ar_AE'),
    CurrencyInfo(code: 'INR', name: 'Indian Rupee', symbol: '₹', flag: '🇮🇳', locale: 'hi_IN'),
    CurrencyInfo(code: 'PHP', name: 'Philippine Peso', symbol: '₱', flag: '🇵🇭', locale: 'en_PH'),
    CurrencyInfo(code: 'VND', name: 'Vietnamese Dong', symbol: '₫', flag: '🇻🇳', locale: 'vi_VN', decimalDigits: 0),
    CurrencyInfo(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$', flag: '🇧🇷', locale: 'pt_BR'),
  ];

  static CurrencyInfo? byCode(String code) {
    try {
      return supportedCurrencies.firstWhere(
        (c) => c.code.toUpperCase() == code.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> loadSavedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _baseCurrency = prefs.getString('baseCurrency') ?? 'IDR';
  }

  Future<void> setBaseCurrency(String code) async {
    _baseCurrency = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseCurrency', code);
  }

  /// Fetch exchange rates from open API (base: USD)
  Future<Map<String, double>> getRates() async {
    final now = DateTime.now();
    if (_lastFetch != null && now.difference(_lastFetch!) < _cacheDuration) {
      return _rates;
    }
    try {
      final res = await http
          .get(Uri.parse('https://api.exchangerate-api.com/v4/latest/IDR'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rawRates = data['rates'] as Map<String, dynamic>;
        _rates = {'IDR': 1.0};
        for (final entry in rawRates.entries) {
          _rates[entry.key] = (entry.value as num).toDouble();
        }
        _lastFetch = now;
      }
    } catch (e) {
      debugPrint('Exchange rate fetch error: $e');
    }
    return _rates;
  }

  /// Convert amount from one currency to another
  Future<double> convert(double amount, String from, String to) async {
    if (from == to) return amount;
    final rates = await getRates();
    final fromRate = rates[from] ?? 1.0;
    final toRate = rates[to] ?? 1.0;
    // Convert: amount (from) -> IDR -> to
    final inIdr = from == 'IDR' ? amount : amount / fromRate;
    return to == 'IDR' ? inIdr : inIdr * toRate;
  }

  /// Format amount with the currency's proper format
  String format(double amount, String currencyCode) {
    final info = byCode(currencyCode);
    if (info == null) return '$currencyCode ${amount.toStringAsFixed(2)}';

    if (info.decimalDigits == 0) {
      final formatted = amount.round().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return '${info.symbol} $formatted';
    }

    final formatted = amount.toStringAsFixed(info.decimalDigits);
    final parts = formatted.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '${info.symbol} $intPart.${parts[1]}';
  }

  void clearCache() {
    _lastFetch = null;
  }
}