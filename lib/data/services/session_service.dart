import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _roleKey = 'user_role';
  static const String _uidKey = 'user_uid';

  Future<void> saveSession({required String uid, required String role}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uidKey, uid);
    await prefs.setString(_roleKey, role);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_uidKey);
    await prefs.remove(_roleKey);
  }
}
