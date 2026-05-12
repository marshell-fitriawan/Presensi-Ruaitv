import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/attendance_model.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/session_service.dart';
import 'attendance_page.dart';
import 'history_page.dart';
import 'rekap_bulanan_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _authRepository = AuthRepository();
  final _attendanceRepository = AttendanceRepository();
  final _userRepository = UserRepository();

  String _userName = '';
  String _userDepartment = '';
  AttendanceModel? _lastCheckIn;
  AttendanceModel? _lastCheckOut;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    try {
      // Load user info
      final userData = await _userRepository.getUser(user.id);
      if (userData != null) {
        _userName = userData['name'] as String? ?? '';
        _userDepartment = userData['department'] as String? ?? '';
      }

      // Load today's attendance
      final records = await _attendanceRepository.queryByUser(user.id);
      final today = DateTime.now();
      final todayRecords = records.where((r) =>
          r.timestamp.year == today.year &&
          r.timestamp.month == today.month &&
          r.timestamp.day == today.day);

      _lastCheckIn = todayRecords
          .where((r) => r.type == 'check_in')
          .firstOrNull;
      _lastCheckOut = todayRecords
          .where((r) => r.type == 'check_out')
          .firstOrNull;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await AuthRepository().signOut();
    await SessionService().clearSession();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RuaiTV Presensi'),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Greeting
                  Text(
                    'Halo, ${_userName.isNotEmpty ? _userName : 'Karyawan'}!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (_userDepartment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _userDepartment,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Status presensi hari ini
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Hari Ini',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatusItem(
                                  icon: Icons.login,
                                  label: 'Masuk',
                                  time: _lastCheckIn != null
                                      ? DateFormat('HH:mm')
                                          .format(_lastCheckIn!.timestamp)
                                      : '-',
                                  color: Colors.green,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 48,
                                color: Colors.grey.shade300,
                              ),
                              Expanded(
                                child: _buildStatusItem(
                                  icon: Icons.logout,
                                  label: 'Pulang',
                                  time: _lastCheckOut != null
                                      ? DateFormat('HH:mm')
                                          .format(_lastCheckOut!.timestamp)
                                      : '-',
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Menu utama
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                                builder: (_) => const AttendancePage()),
                          )
                          .then((_) => _loadData());
                    },
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Presensi Sekarang'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoryPage()),
                    ),
                    icon: const Icon(Icons.history),
                    label: const Text('Riwayat Presensi'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const RekapBulananPage()),
                    ),
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('Rekap Bulanan'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          time,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }
}
