// lib/services/ai_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiMessage {
  final String role; // 'user' atau 'assistant'
  final String content;
  final DateTime timestamp;

  AiMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

class AiService extends ChangeNotifier {
  static final AiService instance = AiService._internal();
  AiService._internal();

  static const _prefsApiKey = 'groq_api_key';
  static const _prefsModel = 'groq_model';
  static const _groqBaseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  String? _apiKey;
  String _model = 'llama-3.3-70b-versatile';
  bool _isLoading = false;

  String? get apiKey => _apiKey;
  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;
  String get model => _model;
  bool get isLoading => _isLoading;

  static const List<Map<String, String>> availableModels = [
    {'id': 'llama-3.3-70b-versatile', 'name': 'LLaMA 3.3 70B', 'desc': 'Kualitas terbaik'},
    {'id': 'llama-3.1-8b-instant', 'name': 'LLaMA 3.1 8B', 'desc': 'Paling cepat'},
    {'id': 'gemma2-9b-it', 'name': 'Gemma 2 9B', 'desc': 'Google model'},
    {'id': 'mixtral-8x7b-32768', 'name': 'Mixtral 8x7B', 'desc': 'Konteks panjang'},
  ];

  // ─── INIT ──────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_prefsApiKey);
    _model = prefs.getString(_prefsModel) ?? 'llama-3.3-70b-versatile';
  }

  Future<void> saveApiKey(String key) async {
    _apiKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsApiKey, _apiKey!);
    notifyListeners();
  }

  Future<void> saveModel(String modelId) async {
    _model = modelId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsModel, modelId);
    notifyListeners();
  }

  Future<void> removeApiKey() async {
    _apiKey = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsApiKey);
    notifyListeners();
  }

  // ─── KIRIM PESAN ───────────────────────────────────────────────
  Future<String> sendMessage({
    required String userMessage,
    required List<AiMessage> history,
    required String systemPrompt,
  }) async {
    if (!hasApiKey) return 'API key belum diatur. Silakan set API key terlebih dahulu.';

    _isLoading = true;
    notifyListeners();

    try {
      // Build messages array
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
        // History sebelumnya (max 10 pesan terakhir)
        ...history.takeLast(10).map((m) => {
          'role': m.role,
          'content': m.content,
        }),
        {'role': 'user', 'content': userMessage},
      ];

      final response = await http.post(
        Uri.parse(_groqBaseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        _isLoading = false;
        notifyListeners();
        return content;
      } else if (response.statusCode == 401) {
        _isLoading = false;
        notifyListeners();
        return '❌ API key tidak valid. Periksa kembali API key kamu di Settings.';
      } else if (response.statusCode == 429) {
        _isLoading = false;
        notifyListeners();
        return '⏳ Rate limit tercapai. Coba lagi dalam beberapa menit.';
      } else {
        final err = jsonDecode(response.body);
        _isLoading = false;
        notifyListeners();
        return '❌ Error: ${err['error']?['message'] ?? response.statusCode}';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Groq API error: $e');
      return '❌ Gagal terhubung ke Groq. Periksa koneksi internet kamu.';
    }
  }

  // ─── ANALISIS OTOMATIS ────────────────────────────────────────
  /// Generate system prompt berisi data keuangan user
  String buildFinanceSystemPrompt({
    required double totalBalance,
    required double monthlyIncome,
    required double monthlyExpense,
    required Map<String, double> expensesByCategory,
    required List<Map<String, dynamic>> recentTransactions,
    required List<Map<String, dynamic>> budgets,
    required String currentMonth,
  }) {
    final categoryBreakdown = expensesByCategory.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final categoryText = categoryBreakdown
        .map((e) => '  - ${e.key}: Rp ${_fmt(e.value)}')
        .join('\n');

    final budgetText = budgets.isEmpty
        ? '  Tidak ada budget aktif'
        : budgets
            .map((b) =>
                '  - ${b['name']}: ${(b['percentage'] * 100).toStringAsFixed(0)}% terpakai '
                '(Rp ${_fmt(b['spent'])} dari Rp ${_fmt(b['limit'])})')
            .join('\n');

    final txnText = recentTransactions.take(10)
        .map((t) => '  - ${t['date']}: ${t['type']} ${t['category']} Rp ${_fmt(t['amount'])}')
        .join('\n');

    return '''Kamu adalah asisten keuangan pribadi yang cerdas dan friendly untuk app FinanceKu.
Kamu berbicara dalam Bahasa Indonesia, singkat, to-the-point, dan menggunakan emoji secara wajar.

DATA KEUANGAN USER ($currentMonth):
- Total Saldo: Rp ${_fmt(totalBalance)}
- Pemasukan bulan ini: Rp ${_fmt(monthlyIncome)}
- Pengeluaran bulan ini: Rp ${_fmt(monthlyExpense)}
- Selisih: Rp ${_fmt(monthlyIncome - monthlyExpense)}

PENGELUARAN PER KATEGORI:
$categoryText

STATUS BUDGET:
$budgetText

10 TRANSAKSI TERAKHIR:
$txnText

INSTRUKSI:
- Berikan insight yang spesifik berdasarkan data di atas
- Gunakan angka nyata dari data user dalam jawabanmu
- Berikan saran yang actionable dan realistis
- Jangan terlalu panjang, maksimal 3-4 paragraf per respons
- Kalau user tanya di luar keuangan, tetap jawab tapi arahkan kembali ke topik keuangan
- Format dengan markdown sederhana (bold, bullet) agar mudah dibaca''';
  }

  // ─── QUICK ANALYSIS (tanpa chat) ─────────────────────────────
  Future<String> quickAnalysis({
    required double monthlyIncome,
    required double monthlyExpense,
    required Map<String, double> expensesByCategory,
    required List<Map<String, dynamic>> budgets,
    required String currentMonth,
  }) async {
    if (!hasApiKey) return 'API key belum diatur.';

    final categoryList = (expensesByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((e) => '${e.key}: Rp ${_fmt(e.value)}')
        .join(', ');

    final prompt = '''Analisis keuangan bulan $currentMonth:
- Pemasukan: Rp ${_fmt(monthlyIncome)}
- Pengeluaran: Rp ${_fmt(monthlyExpense)}  
- Top kategori: $categoryList

Berikan analisis singkat (3-4 bullet point) dalam Bahasa Indonesia:
1. Kondisi keuangan bulan ini
2. Kategori yang perlu diperhatikan
3. Saran hemat yang spesifik
4. Prediksi/rekomendasi bulan depan

Gunakan emoji, singkat dan langsung ke intinya.''';

    return await sendMessage(
      userMessage: prompt,
      history: [],
      systemPrompt:
          'Kamu adalah asisten keuangan pribadi. Jawab dalam Bahasa Indonesia, singkat, pakai emoji, dan berikan insight berdasarkan angka yang diberikan.',
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
    return v.toStringAsFixed(0);
  }
}

extension IterableExtension<T> on Iterable<T> {
  Iterable<T> takeLast(int n) {
    final list = toList();
    if (list.length <= n) return list;
    return list.sublist(list.length - n);
  }
}