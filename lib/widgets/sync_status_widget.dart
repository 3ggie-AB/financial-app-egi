// widgets/sync_status_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/backup_service.dart';

class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final backup = context.watch<BackupService>();
    if (!backup.isSignedIn) return const SizedBox.shrink();

    final state = backup.syncState;

    return GestureDetector(
      onTap: () => _showSyncDetail(context, backup),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _bgColor(state.status).withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _bgColor(state.status).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(state.status),
            const SizedBox(width: 5),
            Text(
              _label(state),
              style: TextStyle(
                fontSize: 11,
                color: _bgColor(state.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(SyncStatus status) {
    final color = _bgColor(status);
    if (status == SyncStatus.syncing) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: color,
        ),
      );
    }
    return Icon(_iconData(status), size: 13, color: color);
  }

  Color _bgColor(SyncStatus status) => switch (status) {
        SyncStatus.syncing => const Color(0xFF2196F3),
        SyncStatus.success => const Color(0xFF4CAF50),
        SyncStatus.error => const Color(0xFFF44336),
        SyncStatus.conflict => const Color(0xFFFF9800),
        SyncStatus.idle => const Color(0xFF9E9E9E),
      };

  IconData _iconData(SyncStatus status) => switch (status) {
        SyncStatus.syncing => Icons.sync_rounded,
        SyncStatus.success => Icons.cloud_done_rounded,
        SyncStatus.error => Icons.cloud_off_rounded,
        SyncStatus.conflict => Icons.warning_amber_rounded,
        SyncStatus.idle => Icons.cloud_queue_rounded,
      };

  String _label(SyncState state) {
    return switch (state.status) {
      SyncStatus.syncing => 'Menyinkron...',
      SyncStatus.success => state.lastSync != null
          ? 'Sync ${_timeAgo(state.lastSync!)}'
          : 'Tersinkron',
      SyncStatus.error => 'Gagal sync',
      SyncStatus.conflict => 'Konflik',
      SyncStatus.idle => state.lastSync != null
          ? 'Sync ${_timeAgo(state.lastSync!)}'
          : 'Belum sync',
    };
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    return DateFormat('dd MMM', 'id_ID').format(time);
  }

  void _showSyncDetail(BuildContext context, BackupService backup) {
    final state = backup.syncState;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.sync_rounded, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                const Text('Status Sinkronisasi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            _detailRow(Icons.person_rounded, 'Akun', backup.userEmail ?? '-'),
            const SizedBox(height: 12),
            _detailRow(
              Icons.access_time_rounded,
              'Terakhir Sync',
              state.lastSync != null
                  ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(state.lastSync!)
                  : 'Belum pernah',
            ),
            const SizedBox(height: 12),
            _detailRow(
              Icons.info_outline_rounded,
              'Status',
              state.message ?? '-',
            ),
            const SizedBox(height: 20),

            // Toggle auto sync
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto Sync',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Sinkron otomatis setiap ada perubahan',
                  style: TextStyle(fontSize: 12)),
              value: backup.autoSyncEnabled,
              onChanged: (v) => backup.setAutoSync(v),
            ),
            const SizedBox(height: 12),

            // Manual sync button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text('Sync Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: state.status == SyncStatus.syncing
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await backup.backupToDrive();
                      },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}