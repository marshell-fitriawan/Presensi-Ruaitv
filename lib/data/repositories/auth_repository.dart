import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  /// Login menggunakan NIP/ID Karyawan via Edge Function.
  /// Edge Function bypass RLS untuk lookup NIP → email,
  /// lalu sign in dan return session.
  Future<void> signInWithNip(String nip, String password) async {
    final response = await _client.functions.invoke(
      'login-nip',
      body: {
        'nip': nip.trim(),
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Tidak ada respons dari server.');
    }

    if (data['error'] != null) {
      throw Exception(data['error'].toString());
    }

    // Set session dari response Edge Function
    final session = data['session'];
    if (session == null) {
      throw Exception('Login gagal. Session tidak ditemukan.');
    }

    final accessToken = session['access_token'] as String?;
    final refreshToken = session['refresh_token'] as String?;

    if (accessToken == null || refreshToken == null) {
      throw Exception('Login gagal. Token tidak valid.');
    }

    // Recover session di client agar AuthGate mendeteksi user sudah login
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
