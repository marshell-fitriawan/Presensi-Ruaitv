import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static const String _bucket = 'face-photos';
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> uploadSelfie({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return path;
  }

  Future<String> createSignedUrl(String path, {int expiresIn = 3600}) async {
    final response = await _client.storage.from(_bucket).createSignedUrl(
          path,
          expiresIn,
        );
    return response;
  }
}
