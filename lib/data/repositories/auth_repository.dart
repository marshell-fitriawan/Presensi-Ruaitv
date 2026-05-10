import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  /// Login menggunakan NIP/ID Karyawan via Edge Function.
  /// Edge Function bypass RLS untuk lookup NIP → email → sign in.
  Future<void> signInWithNip(String nip, String password) async {
    final response = await _client.functions.invoke(
      'login-nip',
      body: {
        'nip': nip.trim(),
        'password': password,
      },
    );

    final data = response.data;

    // Handle jika response bukan Map (bisa String error dari Supabase)
    if (data == null) {
      throw Exception('Tidak ada respons dari server.');
    }

    // Jika data adalah String (error HTML/text dari server)
    if (data is String) {
      if (data.contains('not found') || data.contains('404')) {
        throw Exception(
            'Edge function belum di-deploy. Jalankan: supabase functions deploy login-nip');
      }
      throw Exception('Server error: $data');
    }

    final Map<String, dynamic> body = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);

    // Cek error dari edge function
    if (body.containsKey('error') && body['error'] != null) {
      throw Exception(body['error'].toString());
    }

    // Ambil session
    final session = body['session'];
    if (session == null) {
      throw Exception('Login gagal. Session tidak ditemukan.');
    }

    final accessToken = session['access_token'] as String?;
    final refreshToken = session['refresh_token'] as String?;

    if (accessToken == null || refreshToken == null) {
      throw Exception('Login gagal. Token tidak valid.');
    }

    // Set session di client agar AuthGate mendeteksi user sudah login
    await _client.auth.setSession(accessToken);
  }

  Future<AuthResponse> signIn(String email, String password) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }
}
