class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.nip,
    required this.employeeId,
    required this.department,
    required this.role,
    required this.faceEmbeddingId,
    required this.facePhotoUrl,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String nip;
  final String employeeId;
  final String department;
  final String role;
  final String faceEmbeddingId;
  final String facePhotoUrl;
  final bool isActive;
  final DateTime createdAt;

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      nip: data['nip'] as String? ?? '',
      employeeId: data['employee_id'] as String? ?? '',
      department: data['department'] as String? ?? '',
      role: data['role'] as String? ?? 'employee',
      faceEmbeddingId: data['face_embedding_id'] as String? ?? '',
      facePhotoUrl: data['face_photo_url'] as String? ?? '',
      isActive: data['is_active'] as bool? ?? true,
      createdAt: _parseDateTime(data['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'nip': nip,
      'employee_id': employeeId,
      'department': department,
      'role': role,
      'face_embedding_id': faceEmbeddingId,
      'face_photo_url': facePhotoUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return null;
}
