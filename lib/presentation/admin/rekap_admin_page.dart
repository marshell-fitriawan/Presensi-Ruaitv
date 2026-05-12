import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants.dart';

class RekapAdminPage extends StatefulWidget {
  const RekapAdminPage({super.key});

  @override
  State<RekapAdminPage> createState() => _RekapAdminPageState();
}

class _RekapAdminPageState extends State<RekapAdminPage> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<_EmployeeRekap> _rekapList = [];
  int _totalHariKerja = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await supabase.functions.invoke(
        'admin-api',
        body: {"action": "get_attendance"},
      );

      if (res.data['error'] != null) {
        throw Exception(res.data['error'].toString());
      }

      final List attendanceData = res.data['data'] ?? [];

      // Get users
      final usersRes = await supabase.functions.invoke(
        'admin-api',
        body: {"action": "get_users"},
      );
      final List usersData = usersRes.data['data'] ?? [];

      // Hitung hari kerja bulan ini
      final now = DateTime.now();
      final lastDay = _selectedMonth.year == now.year &&
              _selectedMonth.month == now.month
          ? now.day
          : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

      int hariKerja = 0;
      for (int d = 1; d <= lastDay; d++) {
        final date = DateTime(_selectedMonth.year, _selectedMonth.month, d);
        if (date.weekday <= 5) hariKerja++;
      }

      // Filter attendance bulan ini
      final monthAttendance = attendanceData.where((a) {
        final ts = DateTime.tryParse(a['timestamp'] ?? '');
        if (ts == null) return false;
        return ts.year == _selectedMonth.year &&
            ts.month == _selectedMonth.month;
      }).toList();

      // Group by user
      final Map<String, List<Map<String, dynamic>>> byUser = {};
      for (final a in monthAttendance) {
        final userId = a['user_id'] as String? ?? '';
        byUser.putIfAbsent(userId, () => []).add(a);
      }

      // Build rekap per employee
      final List<_EmployeeRekap> rekapList = [];

      for (final user in usersData) {
        final userId = user['id'] as String? ?? '';
        final name = user['name'] as String? ?? 'Unknown';
        final nip = user['nip'] as String? ?? user['employee_id'] as String? ?? '-';
        final records = byUser[userId] ?? [];

        // Group by date
        final Map<String, List<Map<String, dynamic>>> byDate = {};
        for (final r in records) {
          final ts = DateTime.tryParse(r['timestamp'] ?? '');
          if (ts == null) continue;
          final key = DateFormat('yyyy-MM-dd').format(ts);
          byDate.putIfAbsent(key, () => []).add(r);
        }

        int masuk = 0;
        int telat = 0;

        for (final entry in byDate.entries) {
          final dayRecords = entry.value;
          final checkIns =
              dayRecords.where((r) => r['type'] == 'check_in').toList();

          if (checkIns.isNotEmpty) {
            masuk++;
            final firstTs = DateTime.parse(checkIns.first['timestamp']);
            final date = DateTime(firstTs.year, firstTs.month, firstTs.day);
            final shiftStart = date.add(Duration(
              hours: AppConstants.shiftStartHour,
              minutes: AppConstants.shiftStartMinute + AppConstants.lateToleranceMinutes,
            ));
            if (firstTs.isAfter(shiftStart)) {
              telat++;
            }
          }
        }

        final tidakMasuk = hariKerja - masuk;

        rekapList.add(_EmployeeRekap(
          name: name,
          nip: nip,
          totalMasuk: masuk,
          totalTelat: telat,
          totalTidakMasuk: tidakMasuk < 0 ? 0 : tidakMasuk,
        ));
      }

      // Sort by name
      rekapList.sort((a, b) => a.name.compareTo(b.name));

      if (!mounted) return;
      setState(() {
        _rekapList = rekapList;
        _totalHariKerja = hariKerja;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
      appBar: AppBar(title: const Text('Rekap Absensi')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_errorMessage!),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('Coba Lagi')),
                      ],
                    ),
                  ),
                )
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
                          Column(
                            children: [
                              Text(
                                monthLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Hari kerja: $_totalHariKerja hari',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => _changeMonth(1),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),

                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: Colors.grey.shade100,
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('Nama', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                          Expanded(child: Text('Masuk', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                          Expanded(child: Text('Telat', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                          Expanded(child: Text('Absen', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        ],
                      ),
                    ),

                    // List
                    Expanded(
                      child: _rekapList.isEmpty
                          ? const Center(child: Text('Belum ada data.'))
                          : ListView.separated(
                              itemCount: _rekapList.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final r = _rekapList[i];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(r.name,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500)),
                                            Text('NIP: ${r.nip}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600])),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${r.totalMasuk}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${r.totalTelat}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${r.totalTidakMasuk}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _EmployeeRekap {
  final String name;
  final String nip;
  final int totalMasuk;
  final int totalTelat;
  final int totalTidakMasuk;

  _EmployeeRekap({
    required this.name,
    required this.nip,
    required this.totalMasuk,
    required this.totalTelat,
    required this.totalTidakMasuk,
  });
}
