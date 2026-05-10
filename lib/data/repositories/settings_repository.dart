import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> getOfficeSettings() async {
    final response = await _client
        .from('settings')
        .select()
        .eq('key', 'office_location')
        .maybeSingle();
    return response;
  }

  Future<void> upsertOfficeSettings({
    required double lat,
    required double lng,
    required double radiusMeters,
    required String updatedBy,
  }) {
    return _client.from('settings').upsert({
      'key': 'office_location',
      'lat': lat,
      'lng': lng,
      'radius_meters': radiusMeters,
      'updated_by': updatedBy,
    });
  }
}
