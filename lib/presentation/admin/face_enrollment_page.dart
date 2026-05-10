import 'package:flutter/material.dart';

class FaceEnrollmentPage extends StatelessWidget {
  const FaceEnrollmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Manual')),
      body: const Center(
        child: Text('Gunakan menu Review Selfie untuk verifikasi.'),
      ),
    );
  }
}
