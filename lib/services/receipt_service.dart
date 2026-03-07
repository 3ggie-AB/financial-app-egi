// lib/services/receipt_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptResult {
  final double? totalAmount;
  final String? merchantName;
  final DateTime? date;
  final List<ReceiptItem> items;
  final String rawText;
  final String? suggestedCategory;

  const ReceiptResult({
    this.totalAmount,
    this.merchantName,
    this.date,
    this.items = const [],
    required this.rawText,
    this.suggestedCategory,
  });
}

class ReceiptItem {
  final String name;
  final double? price;
  final int? qty;

  const ReceiptItem({required this.name, this.price, this.qty});
}

class ReceiptService {
  static final ReceiptService instance = ReceiptService._internal();
  ReceiptService._internal();

  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<ReceiptResult> processImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognized = await _recognizer.processImage(inputImage);
      final rawText = recognized.text;

      debugPrint('=== OCR RAW TEXT ===\n$rawText\n===================');

      return _parseReceipt(rawText);
    } catch (e) {
      debugPrint('OCR Error: $e');
      return ReceiptResult(rawText: '', totalAmount: null);
    }
  }

  ReceiptResult _parseReceipt(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    double? totalAmount;
    String? merchantName;
    DateTime? date;
    final items = <ReceiptItem>[];

    // ── 1. MERCHANT NAME ─────────────────────────────────────────
    // Biasanya di baris pertama atau kedua, huruf besar semua
    for (int i = 0; i < lines.length && i < 4; i++) {
      final line = lines[i];
      if (line.length > 3 &&
          !_containsPrice(line) &&
          !_isDateLine(line) &&
          line.replaceAll(RegExp(r'[^A-Za-z\s]'), '').trim().length > 2) {
        merchantName ??= _cleanMerchantName(line);
        break;
      }
    }

    // ── 2. DATE ───────────────────────────────────────────────────
    for (final line in lines) {
      final d = _extractDate(line);
      if (d != null) { date = d; break; }
    }

    // ── 3. TOTAL AMOUNT ───────────────────────────────────────────
    // Cari dari bawah ke atas — total biasanya di bawah
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i].toLowerCase();
      // Keyword total dalam berbagai bahasa/format
      if (line.contains('total') ||
          line.contains('grand') ||
          line.contains('jumlah') ||
          line.contains('amount') ||
          line.contains('bayar') ||
          line.contains('tagihan') ||
          line.contains('tunai') ||
          line.contains('cash')) {
        final amount = _extractAmount(lines[i]);
        if (amount != null && amount > 0) {
          totalAmount = amount;
          break;
        }
      }
    }

    // Fallback: ambil angka terbesar di nota (kemungkinan besar adalah total)
    if (totalAmount == null) {
      double maxAmount = 0;
      for (final line in lines) {
        final amount = _extractAmount(line);
        if (amount != null && amount > maxAmount && amount < 100000000) {
          maxAmount = amount;
        }
      }
      if (maxAmount > 0) totalAmount = maxAmount;
    }

    // ── 4. LINE ITEMS ─────────────────────────────────────────────
    for (final line in lines) {
      final item = _extractLineItem(line);
      if (item != null) items.add(item);
    }

    // ── 5. SUGGEST CATEGORY ───────────────────────────────────────
    final suggestedCategory = _suggestCategory(text, merchantName);

    return ReceiptResult(
      totalAmount: totalAmount,
      merchantName: merchantName,
      date: date,
      items: items,
      rawText: text,
      suggestedCategory: suggestedCategory,
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────
  bool _containsPrice(String line) {
    return RegExp(r'\d{3,}').hasMatch(line);
  }

  bool _isDateLine(String line) {
    return RegExp(
      r'\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}|\d{4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,2}',
    ).hasMatch(line);
  }

  String _cleanMerchantName(String line) {
    return line
        .replaceAll(RegExp(r'[^\w\s\-\.]'), '')
        .trim()
        .split(' ')
        .map((w) => w.isEmpty
            ? ''
            : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ')
        .trim();
  }

  DateTime? _extractDate(String line) {
    // Format: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, YYYY-MM-DD
    final patterns = [
      RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})'),
      RegExp(r'(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})'),
      RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2})$'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        try {
          int year, month, day;
          if (match.group(1)!.length == 4) {
            year = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            day = int.parse(match.group(3)!);
          } else {
            day = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            year = int.parse(match.group(3)!);
            if (year < 100) year += 2000;
          }
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            return DateTime(year, month, day);
          }
        } catch (_) {}
      }
    }
    return null;
  }

  double? _extractAmount(String line) {
    // Hapus karakter non-angka kecuali . dan ,
    // Format Indonesia: 50.000 atau 50,000 atau Rp 50.000
    final cleaned = line
        .replaceAll(RegExp(r'[Rr][Pp]\.?\s*'), '')  // hapus "Rp"
        .replaceAll(RegExp(r'IDR\s*'), '')            // hapus "IDR"
        .replaceAll('\$', '')
        .trim();

    // Coba berbagai format angka
    final patterns = [
      // 50.000,00 atau 50.000
      RegExp(r'(\d{1,3}(?:\.\d{3})+(?:,\d{1,2})?)'),
      // 50,000.00 atau 50,000
      RegExp(r'(\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?)'),
      // 50000 (angka biasa)
      RegExp(r'(\d{4,})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(cleaned);
      if (match != null) {
        try {
          String numStr = match.group(1)!;
          // Normalize: hapus titik ribuan, ganti koma desimal dengan titik
          if (numStr.contains('.') && numStr.contains(',')) {
            // Format Indonesia: 50.000,00
            numStr = numStr.replaceAll('.', '').replaceAll(',', '.');
          } else if (numStr.contains('.') && !numStr.contains(',')) {
            // Bisa 50.000 (ribuan) atau 50.5 (desimal)
            final parts = numStr.split('.');
            if (parts.last.length == 3) {
              // 50.000 = ribuan
              numStr = numStr.replaceAll('.', '');
            }
            // else: 50.5 = desimal, biarkan
          } else if (numStr.contains(',') && !numStr.contains('.')) {
            final parts = numStr.split(',');
            if (parts.last.length == 3) {
              // 50,000 = ribuan
              numStr = numStr.replaceAll(',', '');
            } else {
              // 50,5 = desimal
              numStr = numStr.replaceAll(',', '.');
            }
          }
          final val = double.parse(numStr);
          if (val >= 100) return val; // minimal Rp 100
        } catch (_) {}
      }
    }
    return null;
  }

  ReceiptItem? _extractLineItem(String line) {
    // Skip baris yang kemungkinan bukan item
    final lower = line.toLowerCase();
    if (lower.contains('total') || lower.contains('subtotal') ||
        lower.contains('tax') || lower.contains('pajak') ||
        lower.contains('ppn') || lower.contains('service') ||
        lower.contains('discount') || lower.contains('diskon') ||
        lower.contains('change') || lower.contains('kembalian') ||
        lower.length < 3) {
      return null;
    }

    // Coba extract: "Nama Item    Harga" atau "Qty x Nama    Harga"
    final priceMatch = RegExp(r'(\d[\d\.,\.]+)\s*$').firstMatch(line);
    if (priceMatch != null) {
      final price = _extractAmount(priceMatch.group(1) ?? '');
      final namePart = line.substring(0, priceMatch.start).trim();

      // Cek qty: "2 x Item" atau "2x Item"
      final qtyMatch = RegExp(r'^(\d+)\s*[xX]\s*(.+)').firstMatch(namePart);
      if (qtyMatch != null && namePart.length > 2) {
        return ReceiptItem(
          name: qtyMatch.group(2)!.trim(),
          price: price,
          qty: int.tryParse(qtyMatch.group(1)!),
        );
      }

      if (namePart.length > 2 && price != null) {
        return ReceiptItem(name: namePart, price: price);
      }
    }

    return null;
  }

  String? _suggestCategory(String text, String? merchant) {
    final lower = text.toLowerCase();
    final merchantLower = merchant?.toLowerCase() ?? '';

    // Makanan & Minuman
    if (_matchAny(lower, ['resto', 'restaurant', 'cafe', 'kafe', 'warung',
        'makan', 'minum', 'food', 'beverage', 'bakery', 'pizza', 'burger',
        'ayam', 'nasi', 'mie', 'kopi', 'coffee', 'tea', 'indomaret',
        'alfamart', 'minimarket', 'supermarket', 'grocery', 'mart'])) {
      return 'Makanan & Minuman';
    }

    // Transportasi
    if (_matchAny(lower, ['gojek', 'grab', 'ojek', 'taksi', 'taxi',
        'bensin', 'bbm', 'pertamina', 'shell', 'spbu', 'toll', 'tol',
        'parkir', 'parking', 'bus', 'kereta', 'kai', 'busway'])) {
      return 'Transportasi';
    }

    // Belanja
    if (_matchAny(lower, ['shop', 'store', 'mall', 'plaza', 'fashion',
        'clothing', 'baju', 'sepatu', 'tas', 'electronic', 'elektronik',
        'lazada', 'tokopedia', 'shopee', 'blibli'])) {
      return 'Belanja';
    }

    // Tagihan & Utilitas
    if (_matchAny(lower, ['listrik', 'pln', 'air', 'pdam', 'internet',
        'telkom', 'indihome', 'wifi', 'pulsa', 'token', 'tagihan',
        'electricity', 'water', 'gas'])) {
      return 'Tagihan & Utilitas';
    }

    // Kesehatan
    if (_matchAny(lower, ['apotek', 'apotik', 'farmasi', 'pharmacy',
        'klinik', 'clinic', 'rumah sakit', 'hospital', 'dokter', 'doctor',
        'obat', 'medicine', 'health', 'medis'])) {
      return 'Kesehatan';
    }

    // Hiburan
    if (_matchAny(lower, ['cinema', 'bioskop', 'cgv', 'xxi', 'netflix',
        'spotify', 'game', 'hiburan', 'entertainment', 'hotel', 'resort',
        'wisata', 'travel'])) {
      return 'Hiburan';
    }

    // Pendidikan
    if (_matchAny(lower, ['sekolah', 'school', 'universitas', 'university',
        'kursus', 'course', 'buku', 'book', 'pendidikan', 'education',
        'les', 'bimbel'])) {
      return 'Pendidikan';
    }

    return 'Lainnya';
  }

  bool _matchAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  void dispose() {
    _recognizer.close();
  }
}