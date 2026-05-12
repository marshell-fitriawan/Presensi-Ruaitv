import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Rekap absensi bulanan untuk admin/management.
/// Menampilkan per karyawan: jumlah masuk, telat, tidak masuk.
class MonthlyRecapPage extends StatefulWidget {
  const MonthlyRecapPage({super.key});

  @override
  State<MonthlyRecapPage> createState() => _MonthlyRecapPageState();
}

class _MonthlyRecapPageState extends State<MonthlyRecapPage> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<_EmployeeRecap> _recaps = [];

  // Jam masuk standar (bisa disesuaikan)
  static const int _jamMasukJam = 8;
  static const int _jamMasukMenit = 0;

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
      // Ambil semua karyawan
      final usersRes = await supabase.functions.invoke(
        'admin-api',
        body: {"action": "get_users"},
      );

      if (usersRes.data['error'] != null) {
        throw Exception(usersRes.data['error'].toString());
      }

      final List usersList = usersRes.data['data'] ?? [];

      // Ambil semua attendance
      final attRes = await supabase.functions.invoke(
        'admin-api',
        body: {"action": "get_attendance"},
      );

      if (attRes.data['error'] != null) {
        throw Exception(attRes.data['error'].toString());
      }

      final List attList = attRes.data['data'] ?? [];

      // Filter attendance bulan terpilih
      final startOfMonth = _selectedMonth;
      final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);

      final monthAttendances = attList.where((a) {
        final ts = DateTime.tryParse(a['timestamp'] ?? '');
        if (ts == null) return false;
        return ts.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
            ts.isBefore(endOfMonth);
      }).toList();

      // Hitung hari kerja dalam bulan (Senin-Jumat)
      final hariKerja = _countWorkDays(startOfMonth, endOfMonth);

      // Hitung rekap per karyawan
      final recaps = <_EmployeeRecap>[];

      for (final user in usersList) {
        final userId = user['id'] as String;
        final name = user['name'] as String? ?? 'Unknown';
        final department = user['department'] as String? ?? '';
        final nip = user['nip'] as String? ?? user['employee_id'] as String? ?? '';

        // Filter check_in untuk user ini
        final userCheckIns = monthAttendances.where((a) =>
            a['user_id'] == userId &&
            a['type'] == 'check_in' &&
            (a['status'] == 'approved' || a['status'] == 'pending')).toList();

        // Hitung hari unik masuk
        final daysPresent = <String>{};
        int telatCount = 0;

        for (final ci in userCheckIns) {
          final ts = DateTime.tryParse(ci['timestamp'] ?? '');
          if (ts == null) continue;
          final dayKey = DateFormat('yyyy-MM-dd').format(ts);
          if (!daysPresent.contains(dayKey)) {
            daysPresent.add(dayKey);
            // Cek telat
            if (ts.hour > _jamMasukJam ||
                (ts.hour == _jamMasukJam && ts.minute > _jamMasukMenit)) {
              telatCount++;
            }
          }
        }

        final jumlahMasuk = daysPresent.length;
        final tidakMasuk = hariKerja - jumlahMasuk;

        recaps.add(_EmployeeRecap(
          name: name,
          nip: nip,
          department: department,
          jumlahMasuk: jumlahMasuk,
          jumlahTelat: telatCount,
          tidakMasuk: tidakMasuk < 0 ? 0 : tidakMasuk,
          hariKerja: hariKerja,
        ));
      }

      // Sort by name
      recaps.sort((a, b) => a.name.compareTo(b.name));

      if (!mounted) return;
      setState(() {
        _recaps = recaps;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  int _countWorkDays(DateTime start, DateTime end) {
    int count = 0;
    DateTime current = start;
    final now = DateTime.now();
    // Hanya hitung sampai hari ini jika bulan berjalan
    final limit = end.isAfter(now) ? now : end;
    while (current.isBefore(limit)) {
      if (current.weekday >= 1 && current.weekday <= 5) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }
    return count;
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _load();
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isAfter(DateTime(now.year, now.month + 1))) return;
    setState(() {
      _selectedMonth = next;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel =
        DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Absensi Bulanan'),
      ),
      body: Column(
        children: [
          // Month selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  monthLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(_errorMessage!,
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _load,
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _recaps.isEmpty
                        ? const Center(child: Text('Tidak ada data karyawan.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _recaps.length,
                            itemBuilder: (context, index) {
                              return _buildRecapCard(_recaps[index]);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapCard(_EmployeeRecap recap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    recap.name.isNotEmpty ? recap.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recap.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (recap.nip.isNotEmpty || recap.department.isNotEmpty)
                        Text(
                          [
                            if (recap.nip.isNotEmpty) 'NIP: ${recap.nip}',
                            if (recap.department.isNotEmpty) recap.department,
                          ].join(' • '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: 'Masuk',
                    value: '${recap.jumlahMasuk}/${recap.hariKerja}',
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    label: 'Telat',
                    value: '${recap.jumlahTelat}',
                    color: Colors.orange,
                    icon: Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    label: 'Tidak Masuk',
                    value: '${recap.tidakMasuk}',
                    color: Colors.red,
                    icon: Icons.cancel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _EmployeeRecap {
  final String name;
  final String nip;
  final String department;
  final int jumlahMasuk;
  final int jumlahTelat;
  final int tidakMasuk;
  final int hariKerja;

  const _EmployeeRecap({
    required this.name,
    required this.nip,
    required this.department,
    required this.jumlahMasuk,
    required this.jumlahTelat,
    required this.tidakMasuk,
    required this.hariKerja,
  });
}
