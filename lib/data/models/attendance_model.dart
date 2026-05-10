class AttendanceModel {
  const AttendanceModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
    required this.lat,
    required this.lng,
    required this.distance,
    required this.locationValid,
    required this.faceValid,
    required this.status,
    required this.photoUrl,
  });

  final String id;
  final String userId;
  final String type;
  final DateTime timestamp;
  final double? lat;
  final double? lng;
  final double? distance;
  final bool locationValid;
  final bool faceValid;
  final String status;
  final String photoUrl;

  factory AttendanceModel.fromMap(String id, Map<String, dynamic> data) {
    return AttendanceModel(
      id: id,
      userId: data['user_id'] as String? ?? '',
      type: data['type'] as String? ?? 'check_in',
      timestamp: _parseDateTime(data['timestamp']) ?? DateTime.now(),
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      distance: (data['distance'] as num?)?.toDouble(),
      locationValid: data['location_valid'] as bool? ?? false,
      faceValid: data['face_valid'] as bool? ?? false,
      status: data['status'] as String? ?? 'rejected',
      photoUrl: data['photo_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'lat': lat,
      'lng': lng,
      'distance': distance,
      'location_valid': locationValid,
      'face_valid': faceValid,
      'status': status,
      'photo_url': photoUrl,
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
