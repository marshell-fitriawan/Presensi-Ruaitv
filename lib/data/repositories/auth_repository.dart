import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  /// Konversi NIP/ID Karyawan menjadi format email untuk Supabase Auth.
  /// Contoh: NIP "12345" → "12345@ruaitv.local"
  static String nipToEmail(String nip) {
    final cleaned = nip.trim().toLowerCase();
    // Jika user sudah input format email, gunakan langsung
    if (cleaned.contains('@')) {
      return cleaned;
    }
    return '$cleaned@ruaitv.local';
  }

  /// Login menggunakan ID Karyawan / NIP.
  /// NIP dikonversi ke format email internal (nip@ruaitv.local)
  /// sehingga tidak perlu lookup ke tabel users terlebih dahulu.
  Future<AuthResponse> signInWithNip(String nip, String password) async {
    final email = nipToEmail(nip);
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('ID Karyawan/NIP atau password salah.');
      }
      throw Exception(e.message);
    }
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
