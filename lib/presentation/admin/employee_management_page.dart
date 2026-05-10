import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/user_model.dart';

class EmployeeManagementPage extends StatefulWidget {
  const EmployeeManagementPage({super.key});

  @override
  State<EmployeeManagementPage> createState() => _EmployeeManagementPageState();
}

class _EmployeeManagementPageState extends State<EmployeeManagementPage> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await supabase.functions.invoke(
        'admin-api',
        body: {"action": "get_users"},
      );

      if (res.data['error'] != null) {
        throw Exception(res.data['error'].toString());
      }

      final List list = res.data['data'] ?? [];

      final data = list
          .map((row) => UserModel.fromMap(row['id'] as String, row))
          .toList();

      if (!mounted) return;

      setState(() {
        _users = data;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
        _users = [];
      });
    }
  }

  Future<void> _updateUser(UserModel user,
      {bool? isActive, String? role}) async {
    await supabase.functions.invoke(
      'admin-api',
      body: {
        "action": "update_user",
        "payload": {
          "id": user.id,
          if (isActive != null) "is_active": isActive,
          if (role != null) "role": role,
        }
      },
    );

    await _load();
  }

  Future<void> _deleteUser(String id) async {
    await supabase.functions.invoke(
      'admin-api',
      body: {
        "action": "delete_user",
        "payload": {"id": id}
      },
    );

    await _load();
  }

  Future<void> _openCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    final nipController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    final departmentController = TextEditingController();

    String role = 'employee';
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tambah Karyawan'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'Nama Lengkap'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nipController,
                        decoration: const InputDecoration(
                            labelText: 'NIP / ID Karyawan'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'NIP wajib diisi' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password'),
                        validator: (v) =>
                            v != null && v.length >= 6 ? null : 'Min 6 karakter',
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: departmentController,
                        decoration:
                            const InputDecoration(labelText: 'Departemen'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField(
                        value: role,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: const [
                          DropdownMenuItem(
                              value: 'employee', child: Text('Employee')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        ],
                        onChanged: (v) => setState(() => role = v!),
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal')),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setState(() => isSubmitting = true);

                          // Konversi NIP ke format email untuk Supabase Auth
                          final nip = nipController.text.trim();
                          final email = nip.contains('@')
                              ? nip
                              : '$nip@ruaitv.local';

                          final res = await supabase.functions.invoke(
                            'admin-api',
                            body: {
                              "action": "create_user",
                              "payload": {
                                "email": email,
                                "password": passwordController.text,
                                "name": nameController.text,
                                "nip": nip,
                                "department": departmentController.text,
                                "role": role,
                              }
                            },
                          );

                          setState(() => isSubmitting = false);

                          if (res.data['error'] != null) return;

                          Navigator.pop(context);
                          await _load();
                        },
                  child: const Text('Simpan'),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Karyawan')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Gagal memuat data karyawan',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _users.isEmpty
                  ? const Center(
                      child: Text('Belum ada data karyawan.'),
                    )
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (_, i) {
                        final u = _users[i];
                        return ListTile(
                          title: Text(u.name),
                          subtitle: Text(u.email),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButton(
                                value: u.role,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'employee',
                                      child: Text('Employee')),
                                  DropdownMenuItem(
                                      value: 'admin', child: Text('Admin')),
                                ],
                                onChanged: (v) => _updateUser(u, role: v),
                              ),
                              Switch(
                                value: u.isActive,
                                onChanged: (v) => _updateUser(u, isActive: v),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
