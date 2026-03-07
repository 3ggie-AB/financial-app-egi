// lib/screens/ai/ai_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/ai_service.dart';
import '../../utils/app_theme.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final _ai = AiService.instance;
  final _keyCtrl = TextEditingController();
  bool _obscure = true;
  bool _isSaving = false;
  bool _isTesting = false;
  String _testResult = '';

  @override
  void initState() {
    super.initState();
    if (_ai.hasApiKey) {
      _keyCtrl.text = _ai.apiKey!;
    }
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    if (_keyCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    await _ai.saveApiKey(_keyCtrl.text);
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✓ API key disimpan'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    }
  }

  Future<void> _testKey() async {
    if (_keyCtrl.text.trim().isEmpty) return;
    setState(() { _isTesting = true; _testResult = ''; });

    // Simpan sementara untuk test
    await _ai.saveApiKey(_keyCtrl.text);

    final result = await _ai.sendMessage(
      userMessage: 'Halo! Balas dengan: "Koneksi berhasil! 🎉"',
      history: [],
      systemPrompt: 'Kamu adalah asisten. Ikuti instruksi user.',
    );

    setState(() {
      _isTesting = false;
      _testResult = result.contains('❌') ? result : '✅ $result';
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Info Groq ──────────────────────────────────────────
          Card(
            color: Colors.green.withOpacity(0.06),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Text('Cara Mendapatkan API Key Groq',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _step('1', 'Buka console.groq.com'),
                  _step('2', 'Daftar/login — tidak perlu kartu kredit'),
                  _step('3', 'Klik "API Keys" → "Create API Key"'),
                  _step('4', 'Copy API key dan paste di bawah'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          const ClipboardData(text: 'https://console.groq.com/keys'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link disalin!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link_rounded,
                              color: Colors.green, size: 16),
                          SizedBox(width: 6),
                          Text('console.groq.com/keys',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                          SizedBox(width: 6),
                          Icon(Icons.copy_rounded,
                              color: Colors.green, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── API Key Input ──────────────────────────────────────
          _sectionHeader('🔑 API Key'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _keyCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Groq API Key',
                      hintText: 'gsk_...',
                      prefixIcon: const Icon(Icons.key_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Status
                  if (_ai.hasApiKey)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.green, size: 14),
                          SizedBox(width: 6),
                          Text('API key sudah tersimpan',
                              style: TextStyle(
                                  color: Colors.green, fontSize: 12)),
                        ],
                      ),
                    ),

                  // Test result
                  if (_testResult.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _testResult.startsWith('✅')
                            ? Colors.green.withOpacity(0.08)
                            : Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_testResult,
                          style: TextStyle(
                            fontSize: 12,
                            color: _testResult.startsWith('✅')
                                ? Colors.green
                                : Colors.red,
                          )),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isTesting ? null : _testKey,
                          icon: _isTesting
                              ? const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.network_check_rounded, size: 16),
                          label: Text(_isTesting ? 'Testing...' : 'Test Koneksi'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_ai.hasApiKey)
                        OutlinedButton.icon(
                          onPressed: () async {
                            await _ai.removeApiKey();
                            _keyCtrl.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 16, color: Colors.red),
                          label: const Text('Hapus',
                              style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Model Selection ────────────────────────────────────
          _sectionHeader('🤖 Model AI'),
          Card(
            child: Column(
              children: AiService.availableModels.map((m) {
                final isSelected = _ai.model == m['id'];
                return RadioListTile<String>(
                  value: m['id']!,
                  groupValue: _ai.model,
                  title: Text(m['name']!,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(m['desc']!,
                      style: const TextStyle(fontSize: 12)),
                  secondary: isSelected
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Aktif',
                              style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        )
                      : null,
                  onChanged: (v) async {
                    if (v != null) {
                      await _ai.saveModel(v);
                      setState(() {});
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Privacy note ───────────────────────────────────────
          Card(
            color: Colors.blue.withOpacity(0.06),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.privacy_tip_rounded, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Text('Privasi Data', style: TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  SizedBox(height: 8),
                  Text(
                    '• Data transaksi dikirim ke Groq untuk dianalisis\n'
                    '• API key disimpan terenkripsi di perangkat kamu\n'
                    '• Developer app tidak pernah melihat data kamu\n'
                    '• Groq privacy policy: groq.com/privacy',
                    style: TextStyle(fontSize: 12, height: 1.8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Save button ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveKey,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: const Text('Simpan & Aktifkan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _step(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green)),
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
      );
}