import 'dart:math';

double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadiusMeters = 6371000.0;
  final double dLat = _toRadians(lat2 - lat1);
  final double dLon = _toRadians(lon2 - lon1);
  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  return earthRadiusMeters * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _toRadians(double degrees) {
  return degrees * pi / 180.0;
}
