class AppConstants {
  static const double officeLat = -0.006625056302077418;
  static const double officeLng = 109.36360448257791;
  static const double radiusMeters = 50.0;

  // Jam kerja standar (untuk deteksi telat)
  static const int shiftStartHour = 8; // 08:00
  static const int shiftStartMinute = 0;
  static const int shiftEndHour = 17; // 17:00
  static const int shiftEndMinute = 0;

  // Toleransi telat (menit)
  static const int lateToleranceMinutes = 15;
}
