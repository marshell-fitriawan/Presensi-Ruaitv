import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/attendance_model.dart';
import '../../data/services/storage_service.dart';

class AttendanceReviewPage extends StatefulWidget {
  const AttendanceReviewPage({super.key});

  @override
  State<AttendanceReviewPage> createState() => _AttendanceReviewPageState();
}

class _AttendanceReviewPageState extends State<AttendanceReviewPage> {
  final supabase = Supabase.instance.client;
  final _storageService = StorageService();

  bool _isLoading = true;
  List<_ReviewItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    try {
      // Get attendance
      final res = await supabase.functions.invoke(
        'admin-api',
        body: {"action": "get_attendance"},
      );

      final List attendanceList = res.data['data'] ?? [];

      // Get users for name lookup
      final usersRes = await supabase.functions.invoke(
        'admin-api',
        body: {"action": "get_users"},
      );
      final List usersList = usersRes.data['data'] ?? [];
      final Map<String, String> userNames = {};
      for (final u in usersList) {
        userNames[u['id'] as String? ?? ''] = u['name'] as String? ?? 'Unknown';
      }

      final items = <_ReviewItem>[];
      for (final a in attendanceList) {
        final status = a['status'] as String? ?? '';
        if (status != 'pending') continue;

        final attendance = AttendanceModel.fromMap(
          a['id'] as String? ?? '',
          Map<String, dynamic>.from(a),
        );

        items.add(_ReviewItem(
          attendance: attendance,
          employeeName: userNames[attendance.userId] ?? 'Unknown',
        ));
      }

      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(AttendanceModel item, String status) async {
    await supabase.functions.invoke(
      'admin-api',
      body: {
        "action":
            status == 'approved' ? 'approve_attendance' : 'reject_attendance',
        "payload": {"id": item.id}
      },
    );
    await _load();
  }

  Future<String?> _getPhotoUrl(String path) async {
    if (path.isEmpty) return null;
    try {
      return await _storageService.createSignedUrl(path);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Presensi'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('Semua presensi sudah di-review.'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final item = _items[i];
                    return _buildReviewCard(item);
                  },
                ),
    );
  }

  Widget _buildReviewCard(_ReviewItem item) {
    final a = item.attendance;
    final typeLabel = a.type == 'check_in' ? 'Masuk' : 'Pulang';
    final timeStr = DateFormat('HH:mm, d MMM yyyy').format(a.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.shade50,
                  child: const Icon(Icons.schedule, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.employeeName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$typeLabel • $timeStr',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Foto selfie
            if (a.photoUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              FutureBuilder<String?>(
                future: _getPhotoUrl(a.photoUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 150,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.data == null) {
                    return Container(
                      height: 150,
                      color: Colors.grey.shade200,
                      child: const Center(child: Text('Foto tidak tersedia')),
                    );
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      snapshot.data!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: Colors.grey.shade200,
                        child: const Center(child: Text('Gagal memuat foto')),
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(a, 'rejected'),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Tolak',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _updateStatus(a, 'approved'),
                    icon: const Icon(Icons.check),
                    label: const Text('Setujui'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewItem {
  final AttendanceModel attendance;
  final String employeeName;

  _ReviewItem({required this.attendance, required this.employeeName});
}
