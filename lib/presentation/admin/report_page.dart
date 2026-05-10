import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/attendance_model.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;
  int _pending = 0;
  int _approved = 0;
  int _rejected = 0;
  List<AttendanceModel> _attendances = [];
  String _filterStatus = 'all'; // all, pending, approved, rejected

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

      final List data = res.data['data'] ?? [];

      int p = 0, a = 0, r = 0;
      final attendances = <AttendanceModel>[];

      for (final i in data) {
        final status = i['status'] as String? ?? '';
        if (status == 'pending') p++;
        if (status == 'approved') a++;
        if (status == 'rejected') r++;

        attendances.add(AttendanceModel(
          id: i['id'] ?? '',
          userId: i['user_id'] ?? '',
          type: i['type'] ?? '',
          timestamp: i['timestamp'] != null
              ? DateTime.parse(i['timestamp'])
              : DateTime.now(),
          lat: (i['lat'] as num?)?.toDouble() ?? 0.0,
          lng: (i['lng'] as num?)?.toDouble() ?? 0.0,
          distance: (i['distance'] as num?)?.toDouble() ?? 0.0,
          locationValid: i['location_valid'] as bool? ?? false,
          faceValid: i['face_valid'] as bool? ?? false,
          status: status,
          photoUrl: i['photo_url'] ?? '',
        ));
      }

      if (!mounted) return;

      setState(() {
        _pending = p;
        _approved = a;
        _rejected = r;
        _attendances = attendances;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  List<AttendanceModel> get _filteredAttendances {
    if (_filterStatus == 'all') return _attendances;
    return _attendances.where((a) => a.status == _filterStatus).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Presensi')),
      body: _isLoading
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
                        Text(
                          'Gagal memuat laporan',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // Summary Cards
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ringkasan',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    label: 'Menunggu',
                                    count: _pending,
                                    color: Colors.orange,
                                    icon: Icons.schedule,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    label: 'Disetujui',
                                    count: _approved,
                                    color: Colors.green,
                                    icon: Icons.check_circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    label: 'Ditolak',
                                    count: _rejected,
                                    color: Colors.red,
                                    icon: Icons.cancel,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Filter
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterChip('all', 'Semua'),
                                    const SizedBox(width: 8),
                                    _buildFilterChip('pending', 'Menunggu'),
                                    const SizedBox(width: 8),
                                    _buildFilterChip('approved', 'Disetujui'),
                                    const SizedBox(width: 8),
                                    _buildFilterChip('rejected', 'Ditolak'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // List
                    _filteredAttendances.isEmpty
                        ? SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inbox,
                                      size: 64,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Tidak ada data',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final attendance = _filteredAttendances[index];
                                return _buildAttendanceCard(attendance);
                              },
                              childCount: _filteredAttendances.length,
                            ),
                          ),
                  ],
                ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      backgroundColor: isSelected ? null : Colors.grey[200],
      selectedColor: Colors.blue[100],
    );
  }

  Widget _buildAttendanceCard(AttendanceModel attendance) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(attendance.status),
              shape: BoxShape.circle,
            ),
            child: Icon(
              attendance.status == 'approved'
                  ? Icons.check
                  : attendance.status == 'rejected'
                      ? Icons.close
                      : Icons.schedule,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            attendance.type.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            DateFormat('dd MMM yyyy, HH:mm').format(attendance.timestamp),
          ),
          trailing: Chip(
            label: Text(_getStatusLabel(attendance.status)),
            backgroundColor: _getStatusColor(attendance.status).withAlpha(100),
            labelStyle: TextStyle(
              color: _getStatusColor(attendance.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
