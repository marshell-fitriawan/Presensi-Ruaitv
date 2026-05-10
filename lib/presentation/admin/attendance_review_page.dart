import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/attendance_model.dart';
import '../../data/services/storage_service.dart';

class AttendanceReviewPage extends StatefulWidget {
  const AttendanceReviewPage({super.key});

  @override
  State<AttendanceReviewPage> createState() => _AttendanceReviewPageState();
}

class _AttendanceReviewPageState extends State<AttendanceReviewPage> {
  final supabase = Supabase.instance.client;
  final _storageService = StorageService();

  bool _isLoading = true;
  List<AttendanceModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await supabase.functions.invoke(
      'admin-api',
      body: {"action": "get_attendance"},
    );

    final List list = res.data['data'];

    final data = list
        .map((e) => AttendanceModel.fromMap(
            (e as Map<String, dynamic>)['id'] as String,
            e as Map<String, dynamic>))
        .where((e) => e.status == 'pending')
        .toList();

    if (!mounted) return;

    setState(() {
      _items = data;
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(AttendanceModel item, String status) async {
    await supabase.functions.invoke(
      'admin-api',
      body: {
        "action":
            status == 'approved' ? 'approve_attendance' : 'reject_attendance',
        "payload": {"id": item.id}
      },
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Selfie')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final item = _items[i];
                return ListTile(
                  title: Text(item.type),
                  trailing: PopupMenuButton(
                    onSelected: (v) => _updateStatus(item, v),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'approved', child: Text('Approve')),
                      PopupMenuItem(value: 'rejected', child: Text('Reject')),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
