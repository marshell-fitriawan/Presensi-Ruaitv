import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/user_repository.dart';
import '../../data/services/session_service.dart';
import '../admin/admin_dashboard_page.dart';
import '../employee/dashboard_page.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<String> _resolveRole(User user) async {
    final sessionService = SessionService();
    final cachedRole = await sessionService.getRole();
    if (cachedRole != null && cachedRole.isNotEmpty) {
      return cachedRole;
    }
    final data = await UserRepository().getUser(user.id);
    if (data == null) {
      throw StateError('Profil user belum tersedia.');
    }
    final role = data['role'] as String? ?? 'employee';
    await sessionService.saveSession(uid: user.id, role: role);
    return role;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data?.session?.user;
        if (user == null) {
          return const LoginPage();
        }
        return FutureBuilder<String>(
          future: _resolveRole(user),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (roleSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          roleSnapshot.error.toString(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () async {
                            await Supabase.instance.client.auth.signOut();
                            await SessionService().clearSession();
                          },
                          child: const Text('Kembali ke Login'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            final role = roleSnapshot.data ?? 'employee';
            if (role == 'admin') {
              return const AdminDashboardPage();
            }
            return const DashboardPage();
          },
        );
      },
    );
  }
}
