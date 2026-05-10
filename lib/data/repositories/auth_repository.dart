import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  /// Login menggunakan ID Karyawan atau NIP.
  /// Cari user di tabel 'users' berdasarkan nip atau employee_id,
  /// lalu gunakan email yang terdaftar untuk sign in via Supabase Auth.
  ///
  /// Tabel 'users' harus memiliki kolom 'nip' dan/atau 'employee_id'.
  Future<AuthResponse> signInWithNip(String nip, String password) async {
    // Cari user berdasarkan NIP atau employee_id
    final response = await _client
        .from('users')
        .select('email')
        .or('nip.eq.$nip,employee_id.eq.$nip')
        .maybeSingle();

    if (response == null) {
      throw Exception('ID Karyawan / NIP tidak ditemukan.');
    }

    final email = response['email'] as String?;
    if (email == null || email.isEmpty) {
      throw Exception('Email belum terdaftar untuk akun ini.');
    }

    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
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
