import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../data/models/attendance_model.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/auth_repository.dart';

class RekapBulananPage extends StatefulWidget {
  const RekapBulananPage({super.key});

  @override
  State<RekapBulananPage> createState() => _RekapBulananPageState();
}

class _RekapBulananPageState extends State<RekapBulananPage> {
  final _authRepository = AuthRepository();
  final _attendanceRepository = AttendanceRepository();

  bool _isLoading = true;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  int _totalMasuk = 0;
  int _totalTelat = 0;
  int _totalTidakMasuk = 0;
  int _totalPulang = 0;
  int _hariKerja = 0;
  List<_DailyRecord> _dailyRecords = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final records = await _attendanceRepository.queryByUser(user.id);

      // Filter bulan yang dipilih
      final monthRecords = records.where((r) =>
          r.timestamp.year == _selectedMonth.year &&
          r.timestamp.month == _selectedMonth.month);

      // Hitung hari kerja (Senin-Jumat) dalam bulan ini
      final now = DateTime.now();
      final lastDay = _selectedMonth.year == now.year &&
              _selectedMonth.month == now.month
          ? now.day
          : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

      int hariKerja = 0;
      for (int d = 1; d <= lastDay; d++) {
        final date = DateTime(_selectedMonth.year, _selectedMonth.month, d);
        if (date.weekday <= 5) {
          hariKerja++;
        }
      }

      // Group by date
      final Map<String, List<AttendanceModel>> byDate = {};
      for (final r in monthRecords) {
        final key = DateFormat('yyyy-MM-dd').format(r.timestamp);
        byDate.putIfAbsent(key, () => []).add(r);
      }

      int masuk = 0;
      int telat = 0;
      int pulang = 0;
      final List<_DailyRecord> daily = [];

      // Iterasi setiap hari kerja
      for (int d = 1; d <= lastDay; d++) {
        final date = DateTime(_selectedMonth.year, _selectedMonth.month, d);
        if (date.weekday > 5) continue; // Skip weekend

        final key = DateFormat('yyyy-MM-dd').format(date);
        final dayRecords = byDate[key] ?? [];

        final checkIns =
            dayRecords.where((r) => r.type == 'check_in').toList();
        final checkOuts =
            dayRecords.where((r) => r.type == 'check_out').toList();

        String status = 'tidak_masuk';
        String? jamMasuk;
        String? jamPulang;
        bool isTelat = false;

        if (checkIns.isNotEmpty) {
          masuk++;
          final firstCheckIn = checkIns.first;
          jamMasuk = DateFormat('HH:mm').format(firstCheckIn.timestamp);

          // Cek telat
          final shiftStart = DateTime(
            date.year,
            date.month,
            date.day,
            AppConstants.shiftStartHour,
            AppConstants.shiftStartMinute,
          ).add(const Duration(minutes: AppConstants.lateToleranceMinutes));

          if (firstCheckIn.timestamp.isAfter(shiftStart)) {
            telat++;
            isTelat = true;
            status = 'telat';
          } else {
            status = 'hadir';
          }
        }

        if (checkOuts.isNotEmpty) {
          pulang++;
          jamPulang = DateFormat('HH:mm').format(checkOuts.last.timestamp);
        }

        // Hanya tampilkan sampai hari ini
        if (date.isAfter(now)) continue;

        daily.add(_DailyRecord(
          tanggal: date,
          status: status,
          jamMasuk: jamMasuk,
          jamPulang: jamPulang,
          isTelat: isTelat,
        ));
      }

      final tidakMasuk = hariKerja -
          masuk -
          (now.isBefore(DateTime(_selectedMonth.year, _selectedMonth.month + 1))
              ? (hariKerja - lastDay)
              : 0);

      if (!mounted) return;
      setState(() {
        _totalMasuk = masuk;
        _totalTelat = telat;
        _totalTidakMasuk = tidakMasuk < 0 ? 0 : tidakMasuk;
        _totalPulang = pulang;
        _hariKerja = hariKerja;
        _dailyRecords = daily.reversed.toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel =
        DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth);

    return Scaffold(
      appBar: AppBar(title: const Text('Rekap Bulanan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Month selector
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => _changeMonth(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        monthLabel,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => _changeMonth(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),

                // Summary cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                          child: _buildStat(
                              'Masuk', _totalMasuk, Colors.green, Icons.check_circle)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildStat(
                              'Telat', _totalTelat, Colors.orange, Icons.schedule)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildStat('Tidak\nMasuk', _totalTidakMasuk,
                              Colors.red, Icons.cancel)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Hari kerja: $_hariKerja hari',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),

                // Daily list
                Expanded(
                  child: _dailyRecords.isEmpty
                      ? const Center(child: Text('Belum ada data.'))
                      : ListView.separated(
                          itemCount: _dailyRecords.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final rec = _dailyRecords[i];
                            return _buildDayTile(rec);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStat(String label, int count, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTile(_DailyRecord rec) {
    final dayStr = DateFormat('EEE, d MMM', 'id_ID').format(rec.tanggal);
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (rec.status) {
      case 'hadir':
        statusColor = Colors.green;
        statusLabel = 'Hadir';
        statusIcon = Icons.check_circle;
        break;
      case 'telat':
        statusColor = Colors.orange;
        statusLabel = 'Telat';
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Colors.red;
        statusLabel = 'Tidak Masuk';
        statusIcon = Icons.cancel;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.1),
        child: Icon(statusIcon, color: statusColor, size: 20),
      ),
      title: Text(dayStr),
      subtitle: rec.jamMasuk != null
          ? Text(
              'Masuk: ${rec.jamMasuk}${rec.jamPulang != null ? ' • Pulang: ${rec.jamPulang}' : ''}')
          : null,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          statusLabel,
          style: TextStyle(
              color: statusColor, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _DailyRecord {
  final DateTime tanggal;
  final String status;
  final String? jamMasuk;
  final String? jamPulang;
  final bool isTelat;

  _DailyRecord({
    required this.tanggal,
    required this.status,
    this.jamMasuk,
    this.jamPulang,
    this.isTelat = false,
  });
}
