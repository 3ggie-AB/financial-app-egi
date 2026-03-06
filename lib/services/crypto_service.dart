// services/crypto_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CryptoPrice {
  final String symbol;   // e.g. "BTC"
  final String pair;     // e.g. "BTCUSDT"
  final double priceUsd;
  final double priceIdr;
  final double change24h; // percentage
  final DateTime fetchedAt;

  CryptoPrice({
    required this.symbol,
    required this.pair,
    required this.priceUsd,
    required this.priceIdr,
    required this.change24h,
    required this.fetchedAt,
  });
}

class CryptoCoin {
  final String symbol;
  final String name;
  final String icon;

  const CryptoCoin({required this.symbol, required this.name, required this.icon});
}

class CryptoService {
  static final CryptoService instance = CryptoService._internal();
  CryptoService._internal();

  // Cache harga agar tidak terlalu sering hit API
  final Map<String, CryptoPrice> _cache = {};
  static const _cacheDuration = Duration(minutes: 2);

  // Kurs USD ke IDR (fallback jika API gagal)
  double _usdToIdr = 15800;
  DateTime? _lastRateFetch;

  // Daftar coin yang didukung
  static const List<CryptoCoin> supportedCoins = [
    CryptoCoin(symbol: 'BTC',  name: 'Bitcoin',       icon: '₿'),
    CryptoCoin(symbol: 'ETH',  name: 'Ethereum',      icon: 'Ξ'),
    CryptoCoin(symbol: 'BNB',  name: 'BNB',           icon: '⬡'),
    CryptoCoin(symbol: 'SOL',  name: 'Solana',        icon: '◎'),
    CryptoCoin(symbol: 'XRP',  name: 'Ripple',        icon: '✕'),
    CryptoCoin(symbol: 'ADA',  name: 'Cardano',       icon: '₳'),
    CryptoCoin(symbol: 'DOGE', name: 'Dogecoin',      icon: 'Ð'),
    CryptoCoin(symbol: 'DOT',  name: 'Polkadot',      icon: '●'),
    CryptoCoin(symbol: 'MATIC',name: 'Polygon',       icon: '⬟'),
    CryptoCoin(symbol: 'AVAX', name: 'Avalanche',     icon: '▲'),
    CryptoCoin(symbol: 'LINK', name: 'Chainlink',     icon: '⬡'),
    CryptoCoin(symbol: 'UNI',  name: 'Uniswap',       icon: '🦄'),
    CryptoCoin(symbol: 'LTC',  name: 'Litecoin',      icon: 'Ł'),
    CryptoCoin(symbol: 'ATOM', name: 'Cosmos',        icon: '⚛'),
    CryptoCoin(symbol: 'NEAR', name: 'NEAR Protocol', icon: 'Ⓝ'),
    CryptoCoin(symbol: 'USDT', name: 'Tether (USDT)', icon: '₮'),
    CryptoCoin(symbol: 'USDC', name: 'USD Coin',      icon: r'$'),
  ];

  static CryptoCoin? coinBySymbol(String symbol) {
    try {
      return supportedCoins.firstWhere(
        (c) => c.symbol.toUpperCase() == symbol.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Fetch kurs USD/IDR dari API publik
  Future<double> _getUsdToIdr() async {
    final now = DateTime.now();
    if (_lastRateFetch != null &&
        now.difference(_lastRateFetch!) < const Duration(hours: 1)) {
      return _usdToIdr;
    }
    try {
      final res = await http
          .get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _usdToIdr = (data['rates']['IDR'] as num).toDouble();
        _lastRateFetch = now;
      }
    } catch (e) {
      debugPrint('ExchangeRate fetch error: $e');
      // Gunakan kurs fallback
    }
    return _usdToIdr;
  }

  /// Fetch harga satu coin dari Binance
  Future<CryptoPrice?> getPrice(String symbol) async {
    final upperSymbol = symbol.toUpperCase();

    // Stablecoin — harga tetap $1
    if (upperSymbol == 'USDT' || upperSymbol == 'USDC') {
      final idr = await _getUsdToIdr();
      return CryptoPrice(
        symbol: upperSymbol,
        pair: '${upperSymbol}USDT',
        priceUsd: 1.0,
        priceIdr: idr,
        change24h: 0,
        fetchedAt: DateTime.now(),
      );
    }

    // Cek cache
    final cached = _cache[upperSymbol];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _cacheDuration) {
      return cached;
    }

    try {
      final pair = '${upperSymbol}USDT';
      final uri = Uri.parse(
        'https://api.binance.com/api/v3/ticker/24hr?symbol=$pair',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      final priceUsd = double.parse(data['lastPrice'].toString());
      final change24h = double.parse(data['priceChangePercent'].toString());
      final idr = await _getUsdToIdr();

      final price = CryptoPrice(
        symbol: upperSymbol,
        pair: pair,
        priceUsd: priceUsd,
        priceIdr: priceUsd * idr,
        change24h: change24h,
        fetchedAt: DateTime.now(),
      );

      _cache[upperSymbol] = price;
      return price;
    } catch (e) {
      debugPrint('Binance fetch error ($symbol): $e');
      return null;
    }
  }

  /// Fetch harga banyak coin sekaligus
  Future<Map<String, CryptoPrice>> getPrices(List<String> symbols) async {
    final results = <String, CryptoPrice>{};
    await Future.wait(
      symbols.map((s) async {
        final price = await getPrice(s);
        if (price != null) results[s.toUpperCase()] = price;
      }),
    );
    return results;
  }

  /// Hitung nilai IDR dari jumlah coin
  Future<double?> calcIdrValue(String symbol, double amount) async {
    final price = await getPrice(symbol);
    if (price == null) return null;
    return price.priceIdr * amount;
  }

  void clearCache() => _cache.clear();
}