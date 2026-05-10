import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/attendance_model.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/geolocation_service.dart';
import '../../data/services/storage_service.dart';
import 'selfie_capture_page.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final _authRepository = AuthRepository();
  final _attendanceRepository = AttendanceRepository();
  final _geolocationService = GeolocationService();
  final _storageService = StorageService();

  bool _isLoading = false;
  String? _message;
  bool? _isSuccess;

  Future<void> _submitAttendance(String type) async {
    final user = _authRepository.currentUser;
    if (user == null) {
      setState(() {
        _message = 'User belum login.';
        _isSuccess = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _message = null;
      _isSuccess = null;
    });

    try {
      // 1. Ambil selfie terlebih dahulu
      final selfie = await Navigator.of(context).push<XFile>(
        MaterialPageRoute(builder: (_) => const SelfieCapturePage()),
      );
      if (selfie == null) {
        setState(() {
          _isLoading = false;
          _message = 'Foto dibatalkan.';
          _isSuccess = false;
        });
        return;
      }

      // 2. Ambil lokasi GPS (untuk bukti, bebas area)
      final position = await _geolocationService.getCurrentPosition();

      // 3. Upload selfie ke storage
      final bytes = await selfie.readAsBytes();
      final safeTimestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-');
      final path = 'attendance/${user.id}/$safeTimestamp.jpg';
      final storedPath = await _storageService.uploadSelfie(
        path: path,
        bytes: bytes,
        contentType: 'image/jpeg',
      );

      // 4. Simpan data presensi (bebas area, langsung approved)
      final attendance = AttendanceModel(
        id: '',
        userId: user.id,
        type: type,
        timestamp: DateTime.now(),
        lat: position.latitude,
        lng: position.longitude,
        distance: null,
        locationValid: true,
        faceValid: true,
        status: 'approved',
        photoUrl: storedPath,
      );

      await _attendanceRepository.addAttendance(attendance);

      final typeLabel = type == 'check_in' ? 'Masuk' : 'Pulang';
      setState(() {
        _message = 'Presensi $typeLabel berhasil dicatat.';
        _isSuccess = true;
        _isLoading = false;
      });
    } catch (error) {
      String msg = error.toString();
      if (msg.contains('Location permission denied')) {
        msg = 'Izin lokasi ditolak. Aktifkan GPS dan izin lokasi di pengaturan.';
      } else if (msg.contains('Exception:')) {
        msg = msg.replaceAll('Exception: ', '');
      }
      setState(() {
        _message = msg;
        _isSuccess = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
    final timeStr = DateFormat('HH:mm').format(now);

    return Scaffold(
      appBar: AppBar(title: const Text('Presensi')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info waktu
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      timeStr,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Pesan status
            if (_message != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess == true
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess == true
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess == true
                          ? Icons.check_circle
                          : Icons.error_outline,
                      color: _isSuccess == true ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _isSuccess == true
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Tombol Masuk
            FilledButton.icon(
              onPressed:
                  _isLoading ? null : () => _submitAttendance('check_in'),
              icon: const Icon(Icons.login),
              label: const Text('Presensi Masuk'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Tombol Pulang
            OutlinedButton.icon(
              onPressed:
                  _isLoading ? null : () => _submitAttendance('check_out'),
              icon: const Icon(Icons.logout),
              label: const Text('Presensi Pulang'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),

            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Memproses presensi...',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],

            const Spacer(),

            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ambil foto selfie sebagai bukti presensi. Lokasi GPS akan dicatat otomatis.',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
