// lib/screens/notifications/notification_settings_screen.dart
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../../providers/finance_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _notif = NotificationService.instance;

  late bool _enabled;
  late double _budgetThreshold;
  late bool _dailySummary;
  late bool _weeklySummary;
  late bool _monthlySummary;
  late bool _dailyReminder;
  late int _reminderHour;
  late int _reminderMinute;
  late int _summaryHour;
  late int _summaryMinute;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFromService();
  }

  void _loadFromService() {
    _enabled = _notif.enabled;
    _budgetThreshold = _notif.budgetThreshold;
    _dailySummary = _notif.dailySummary;
    _weeklySummary = _notif.weeklySummary;
    _monthlySummary = _notif.monthlySummary;
    _dailyReminder = _notif.dailyReminder;
    _reminderHour = _notif.reminderHour;
    _reminderMinute = _notif.reminderMinute;
    _summaryHour = _notif.summaryHour;
    _summaryMinute = _notif.summaryMinute;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await _notif.saveSettings(
      enabled: _enabled,
      budgetThreshold: _budgetThreshold,
      dailySummary: _dailySummary,
      weeklySummary: _weeklySummary,
      monthlySummary: _monthlySummary,
      dailyReminder: _dailyReminder,
      reminderHour: _reminderHour,
      reminderMinute: _reminderMinute,
      summaryHour: _summaryHour,
      summaryMinute: _summaryMinute,
    );
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 10),
            Text('Pengaturan notifikasi disimpan'),
          ]),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickTime({required bool isReminder}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: isReminder ? _reminderHour : _summaryHour,
        minute: isReminder ? _reminderMinute : _summaryMinute,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isReminder) {
          _reminderHour = picked.hour;
          _reminderMinute = picked.minute;
        } else {
          _summaryHour = picked.hour;
          _summaryMinute = picked.minute;
        }
      });
    }
  }

  String _fmtTime(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Notifikasi'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Simpan',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Master Switch ──────────────────────────────────────
          Card(
            child: SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.notifications_rounded, color: scheme.primary),
              ),
              title: const Text('Aktifkan Notifikasi',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Matikan semua notifikasi sekaligus'),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
          ),
          const SizedBox(height: 16),

          // ── Budget Warning ─────────────────────────────────────
          _sectionHeader('⚠️ Peringatan Budget'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Batas Peringatan',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _thresholdColor(_budgetThreshold)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_budgetThreshold.toInt()}%',
                          style: TextStyle(
                            color: _thresholdColor(_budgetThreshold),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Notifikasi muncul saat budget terpakai ≥ ${_budgetThreshold.toInt()}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Slider(
                    value: _budgetThreshold,
                    min: 50,
                    max: 95,
                    divisions: 9,
                    activeColor: _thresholdColor(_budgetThreshold),
                    label: '${_budgetThreshold.toInt()}%',
                    onChanged: _enabled
                        ? (v) => setState(() => _budgetThreshold = v)
                        : null,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('50%',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[400])),
                      Text('95%',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Preview chips
                  Wrap(
                    spacing: 8,
                    children: [60, 70, 75, 80, 85, 90].map((v) {
                      final selected = _budgetThreshold.toInt() == v;
                      return ChoiceChip(
                        label: Text('$v%'),
                        selected: selected,
                        selectedColor:
                            _thresholdColor(v.toDouble()).withOpacity(0.2),
                        onSelected: _enabled
                            ? (s) {
                                if (s) {
                                  setState(
                                      () => _budgetThreshold = v.toDouble());
                                }
                              }
                            : null,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Summary ───────────────────────────────────────────
          _sectionHeader('📊 Ringkasan Keuangan'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Ringkasan Harian'),
                  subtitle: const Text('Setiap malam hari'),
                  secondary: const Icon(Icons.today_rounded, color: Colors.blue),
                  value: _dailySummary && _enabled,
                  onChanged: _enabled
                      ? (v) => setState(() => _dailySummary = v)
                      : null,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Ringkasan Mingguan'),
                  subtitle: const Text('Setiap Minggu malam'),
                  secondary:
                      const Icon(Icons.view_week_rounded, color: Colors.purple),
                  value: _weeklySummary && _enabled,
                  onChanged: _enabled
                      ? (v) => setState(() => _weeklySummary = v)
                      : null,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Ringkasan Bulanan'),
                  subtitle: const Text('Setiap tanggal 1'),
                  secondary: const Icon(Icons.calendar_month_rounded,
                      color: Colors.green),
                  value: _monthlySummary && _enabled,
                  onChanged: _enabled
                      ? (v) => setState(() => _monthlySummary = v)
                      : null,
                ),
                if (_dailySummary || _weeklySummary || _monthlySummary) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.access_time_rounded,
                        color: Colors.grey),
                    title: const Text('Jam Pengiriman Ringkasan'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _fmtTime(_summaryHour, _summaryMinute),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit_rounded, size: 16,
                            color: Colors.grey),
                      ],
                    ),
                    onTap: _enabled
                        ? () => _pickTime(isReminder: false)
                        : null,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Daily Reminder ────────────────────────────────────
          _sectionHeader('💰 Pengingat Catat Transaksi'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Pengingat Harian'),
                  subtitle: const Text(
                      'Ingatkan jika belum ada transaksi pengeluaran hari ini'),
                  secondary: const Icon(Icons.notifications_active_rounded,
                      color: Colors.orange),
                  value: _dailyReminder && _enabled,
                  onChanged: _enabled
                      ? (v) => setState(() => _dailyReminder = v)
                      : null,
                ),
                if (_dailyReminder) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.access_time_rounded,
                        color: Colors.grey),
                    title: const Text('Jam Pengingat'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _fmtTime(_reminderHour, _reminderMinute),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit_rounded,
                            size: 16, color: Colors.grey),
                      ],
                    ),
                    onTap: _enabled
                        ? () => _pickTime(isReminder: true)
                        : null,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Test Notifikasi ───────────────────────────────────
          _sectionHeader('🧪 Test Notifikasi'),
          Card(
            child: Column(
              children: [
                _testTile(
                  icon: Icons.warning_amber_rounded,
                  color: Colors.orange,
                  title: 'Test Budget Warning',
                  onTap: () async {
                    await NotificationService.instance.checkAndNotifyBudgets(
                      budgets: [
                        {
                          'name': 'Makanan',
                          'spent': 850000.0,
                          'limit': 1000000.0,
                          'percentage': 0.85,
                        }
                      ],
                    );
                    _showTestSnack('Budget warning dikirim!');
                  },
                ),
                const Divider(height: 1),
                _testTile(
                  icon: Icons.today_rounded,
                  color: Colors.blue,
                  title: 'Test Ringkasan Harian',
                  onTap: () async {
                    final fp = context.read<FinanceProvider>();
                    final now = DateTime.now();
                    final todayTxns = fp.transactions.where((t) {
                      return t.date.year == now.year &&
                          t.date.month == now.month &&
                          t.date.day == now.day;
                    }).toList();
                    final expense = todayTxns
                        .where((t) =>
                            t.type.name == 'expense')
                        .fold(0.0, (s, t) => s + t.amount);
                    final income = todayTxns
                        .where((t) =>
                            t.type.name == 'income')
                        .fold(0.0, (s, t) => s + t.amount);

                    await NotificationService.instance.sendDailySummaryNow(
                      todayExpense: expense,
                      todayIncome: income,
                      txnCount: todayTxns.length,
                    );
                    _showTestSnack('Ringkasan harian dikirim!');
                  },
                ),
                const Divider(height: 1),
                _testTile(
                  icon: Icons.notifications_active_rounded,
                  color: Colors.green,
                  title: 'Test Pengingat Transaksi',
                  onTap: () async {
                    await AwesomeNotifications().createNotification(
                      content: NotificationContent(
                        id: 9999,
                        channelKey: NotificationService.channelReminder,
                        title: '💰 Jangan Lupa Catat Pengeluaran!',
                        body:
                            'Kamu belum mencatat transaksi hari ini. Yuk catat sekarang!',
                        notificationLayout: NotificationLayout.Default,
                        color: const Color(0xFF4CAF50),
                      ),
                    );
                    _showTestSnack('Pengingat dikirim!');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text('Simpan Pengaturan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
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

  Widget _testTile({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      trailing: const Icon(Icons.send_rounded, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }

  Color _thresholdColor(double v) {
    if (v >= 90) return Colors.red;
    if (v >= 80) return Colors.orange;
    return Colors.yellow[700]!;
  }

  void _showTestSnack(String msg) {
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey)),
      );
}