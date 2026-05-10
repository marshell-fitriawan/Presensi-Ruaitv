import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/attendance_model.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/auth_repository.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _authRepository = AuthRepository();
  final _attendanceRepository = AttendanceRepository();

  bool _isLoading = true;
  List<AttendanceModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _authRepository.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final data = await _attendanceRepository.queryByUser(user.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _items = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Presensi'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _isLoading = true);
              _load();
            },
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
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada data presensi.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final typeLabel =
                          item.type == 'check_in' ? 'Masuk' : 'Pulang';
                      final typeIcon = item.type == 'check_in'
                          ? Icons.login
                          : Icons.logout;
                      final typeColor = item.type == 'check_in'
                          ? Colors.green
                          : Colors.orange;
                      final timeStr =
                          DateFormat('HH:mm').format(item.timestamp);
                      final dateStr = DateFormat('d MMM yyyy', 'id_ID')
                          .format(item.timestamp);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: typeColor.withOpacity(0.1),
                          child: Icon(typeIcon, color: typeColor, size: 20),
                        ),
                        title: Text(
                          '$typeLabel - $timeStr',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(dateStr),
                        trailing: _buildStatusChip(item.status),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'Diterima';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Ditolak';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
