import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attendance_model.dart';

class AttendanceRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> addAttendance(AttendanceModel attendance) {
    return _client.from('attendance').insert(attendance.toMap());
  }

  Future<List<AttendanceModel>> queryByUser(String userId) async {
    final response = await _client
        .from('attendance')
        .select()
        .eq('user_id', userId)
        .order('timestamp', ascending: false);
    return List<Map<String, dynamic>>.from(response)
        .map((row) => AttendanceModel.fromMap(row['id']?.toString() ?? '', row))
        .toList();
  }

  Future<List<AttendanceModel>> queryByStatus(String status) async {
    final response = await _client
        .from('attendance')
        .select()
        .eq('status', status)
        .order('timestamp', ascending: false);
    return List<Map<String, dynamic>>.from(response)
        .map((row) => AttendanceModel.fromMap(row['id']?.toString() ?? '', row))
        .toList();
  }

  Future<void> updateStatus({
    required String id,
    required String status,
    required bool faceValid,
  }) {
    return _client.from('attendance').update({
      'status': status,
      'face_valid': faceValid,
    }).eq('id', id);
  }
}
