import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final response =
        await _client.from('users').select().eq('id', uid).maybeSingle();
    return response;
  }

  Future<void> setUser(String uid, Map<String, dynamic> data) {
    return _client.from('users').insert({...data, 'id': uid});
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) {
    return _client.from('users').update(data).eq('id', uid);
  }

  Future<List<Map<String, dynamic>>> listUsers() async {
    final response = await _client.from('users').select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }
}
