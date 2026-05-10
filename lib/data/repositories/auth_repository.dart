import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  /// Login menggunakan NIP/ID Karyawan via Edge Function.
  /// Fallback: jika edge function gagal, coba login langsung.
  Future<void> signInWithNip(String nip, String password) async {
    final trimmedNip = nip.trim();

    // Coba via Edge Function dulu (bypass RLS)
    try {
      final response = await _client.functions.invoke(
        'login-nip',
        body: {
          'nip': trimmedNip,
          'password': password,
        },
      );

      final data = response.data;

      if (data != null && data is Map) {
        final body = Map<String, dynamic>.from(data);

        if (body['session'] != null) {
          final accessToken = body['session']['access_token'] as String?;
          if (accessToken != null) {
            await _client.auth.setSession(accessToken);
            return;
          }
        }

        // Edge function returned error
        if (body['error'] != null) {
          final errorMsg = body['error'].toString();
          // Jika NIP tidak ditemukan di DB, coba fallback
          if (!errorMsg.contains('tidak ditemukan')) {
            throw Exception(errorMsg);
          }
        }
      }
    } catch (e) {
      // Jika edge function belum deploy / network error, lanjut ke fallback
      if (e is Exception &&
          e.toString().contains('Password salah')) {
        rethrow;
      }
      // Lanjut ke fallback strategies
    }

    // Fallback 1: Login langsung dengan email jika input berupa email
    if (trimmedNip.contains('@')) {
      try {
        await _client.auth.signInWithPassword(
          email: trimmedNip,
          password: password,
        );
        return;
      } on AuthException {
        throw Exception('Email atau password salah.');
      }
    }

    // Fallback 2: Coba format nip@ruaitv.local
    try {
      await _client.auth.signInWithPassword(
        email: '$trimmedNip@ruaitv.local',
        password: password,
      );
      return;
    } on AuthException {
      // Lanjut ke fallback berikutnya
    }

    // Fallback 3: Coba lookup dari tabel users (mungkin RLS allow)
    try {
      final result = await _client
          .from('users')
          .select('email')
          .or('nip.eq.$trimmedNip,employee_id.eq.$trimmedNip')
          .maybeSingle();

      if (result != null && result['email'] != null) {
        final email = result['email'] as String;
        await _client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        return;
      }
    } catch (_) {
      // RLS mungkin block, abaikan
    }

    throw Exception('ID Karyawan/NIP tidak ditemukan.');
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
