// lib/screens/ai/ai_analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/ai_service.dart';
import '../../providers/finance_provider.dart';
import '../../utils/app_theme.dart';
import 'ai_settings_screen.dart';

class AiAnalysisScreen extends StatefulWidget {
  const AiAnalysisScreen({super.key});

  @override
  State<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends State<AiAnalysisScreen> {
  final _ai = AiService.instance;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<AiMessage> _messages = [];
  bool _systemPromptBuilt = false;
  String _systemPrompt = '';
  bool _isQuickLoading = false;

  // Quick prompt suggestions
  static const _quickPrompts = [
    '📊 Analisis keuangan bulan ini',
    '💸 Di mana saya paling boros?',
    '💡 Saran hemat bulan depan',
    '⚠️ Cek status budget saya',
    '📈 Tren pengeluaran saya',
    '🎯 Cara capai tabungan lebih banyak',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initChat());
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _initChat() {
    final fp = context.read<FinanceProvider>();
    final now = DateTime.now();
    final currentMonth = DateFormat('MMMM yyyy', 'id_ID').format(now);

    final expByCategory = fp.expensesByCategory(now);
    final categoryNames = <String, double>{};
    for (final entry in expByCategory.entries) {
      final cat = fp.categoryById(entry.key);
      if (cat != null) categoryNames[cat.name] = entry.value;
    }

    final budgetData = fp.budgets.map((b) {
      final cat = fp.categoryById(b.categoryId);
      return {
        'name': cat?.name ?? 'Budget',
        'spent': b.spentAmount,
        'limit': b.limitAmount,
        'percentage': b.percentage,
      };
    }).toList();

    final recentTxns = fp.transactions.take(20).map((t) {
      final cat = fp.categoryById(t.categoryId);
      return {
        'date': DateFormat('dd MMM', 'id_ID').format(t.date),
        'type': t.type.name,
        'category': cat?.name ?? 'Lainnya',
        'amount': t.amount,
      };
    }).toList();

    _systemPrompt = _ai.buildFinanceSystemPrompt(
      totalBalance: fp.totalBalance,
      monthlyIncome: fp.monthlyIncome(now),
      monthlyExpense: fp.monthlyExpense(now),
      expensesByCategory: categoryNames,
      recentTransactions: recentTxns,
      budgets: budgetData,
      currentMonth: currentMonth,
    );

    _systemPromptBuilt = true;

    // Welcome message
    setState(() {
      _messages.add(AiMessage(
        role: 'assistant',
        content:
            '👋 Halo! Saya asisten keuangan AI kamu yang didukung oleh **Groq**.\n\n'
            'Saya sudah membaca data keuangan kamu bulan **$currentMonth**. '
            'Tanya apa saja tentang kondisi keuanganmu! 💰\n\n'
            'Atau pilih salah satu pertanyaan cepat di bawah ini 👇',
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || !_systemPromptBuilt) return;

    final userMsg = text.trim();
    _msgCtrl.clear();

    setState(() {
      _messages.add(AiMessage(
        role: 'user',
        content: userMsg,
        timestamp: DateTime.now(),
      ));
    });

    _scrollToBottom();

    final response = await _ai.sendMessage(
      userMessage: userMsg,
      history: _messages.where((m) => m.role != 'system').toList(),
      systemPrompt: _systemPrompt,
    );

    setState(() {
      _messages.add(AiMessage(
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
      ));
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_ai.hasApiKey) {
      return _buildNoApiKeyScreen(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.7),
                ]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('AI Keuangan'),
          ],
        ),
        actions: [
          // Model indicator
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _ai.model.split('-').first.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  color: scheme.primary,
                  fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiSettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Chat messages ─────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_ai.isLoading ? 1 : 0),
              itemBuilder: (_, i) {
                // Loading bubble
                if (i == _messages.length) {
                  return _buildLoadingBubble();
                }
                return _buildMessageBubble(_messages[i], scheme, isDark);
              },
            ),
          ),

          // ── Quick prompts ─────────────────────────────────────
          if (_messages.length <= 1)
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickPrompts.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(_quickPrompts[i],
                        style: const TextStyle(fontSize: 12)),
                    onPressed: () => _sendMessage(_quickPrompts[i]),
                  ),
                ),
              ),
            ),

          // ── Input bar ─────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 12, right: 12, top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: 'Tanya tentang keuanganmu...',
                      filled: true,
                      fillColor: scheme.surfaceVariant.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: FloatingActionButton.small(
                    onPressed: _ai.isLoading
                        ? null
                        : () => _sendMessage(_msgCtrl.text),
                    backgroundColor: _ai.isLoading
                        ? Colors.grey
                        : AppTheme.primaryColor,
                    child: Icon(
                      _ai.isLoading
                          ? Icons.hourglass_empty_rounded
                          : Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      AiMessage msg, ColorScheme scheme, bool isDark) {
    final isUser = msg.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.7),
                ]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primaryColor
                    : (isDark
                        ? const Color(0xFF2A2A3E)
                        : Colors.grey[100]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: _buildMessageContent(msg.content, isUser),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageContent(String content, bool isUser) {
    // Simple markdown-like rendering
    final textColor = isUser ? Colors.white : null;
    final lines = content.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('**') && line.endsWith('**')) {
          return Text(
            line.replaceAll('**', ''),
            style: TextStyle(
                fontWeight: FontWeight.bold, color: textColor, fontSize: 13),
          );
        }
        if (line.startsWith('- ') || line.startsWith('• ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: textColor, fontSize: 13)),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          );
        }
        return Text(
          line,
          style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.7),
              ]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(150),
                const SizedBox(width: 4),
                _dot(300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, value, __) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor
              .withOpacity(0.3 + value * 0.7),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildNoApiKeyScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Keuangan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.15),
                      AppTheme.primaryColor.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    size: 56, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 24),
              const Text(
                'Aktifkan AI Keuangan',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Dapatkan analisis mendalam tentang pola pengeluaran, saran hemat, dan insight keuangan yang dipersonalisasi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gratis! Pakai Groq API — daftar di console.groq.com, tidak perlu kartu kredit.',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiSettingsScreen()),
                  ),
                  icon: const Icon(Icons.key_rounded),
                  label: const Text('Set API Key Groq',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}