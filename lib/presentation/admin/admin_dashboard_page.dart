import 'package:flutter/material.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/services/session_service.dart';
import 'attendance_review_page.dart';
import 'employee_management_page.dart';
import 'rekap_admin_page.dart';
import 'report_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  Future<void> _signOut() async {
    await AuthRepository().signOut();
    await SessionService().clearSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuItem(
            context,
            icon: Icons.people,
            title: 'Manajemen Karyawan',
            subtitle: 'Tambah, edit, hapus karyawan',
            page: const EmployeeManagementPage(),
          ),
          _buildMenuItem(
            context,
            icon: Icons.fact_check_outlined,
            title: 'Review Presensi',
            subtitle: 'Approve/reject presensi karyawan',
            page: const AttendanceReviewPage(),
          ),
          _buildMenuItem(
            context,
            icon: Icons.bar_chart,
            title: 'Rekap Absensi',
            subtitle: 'Rekap bulanan: masuk, telat, tidak masuk',
            page: const RekapAdminPage(),
          ),
          _buildMenuItem(
            context,
            icon: Icons.table_chart_outlined,
            title: 'Laporan',
            subtitle: 'Detail semua presensi',
            page: const ReportPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => page),
        ),
      ),
    );
  }
}
