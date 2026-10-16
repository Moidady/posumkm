import 'package:intl/intl.dart';

/// Formatter standar untuk penanggalan dan waktu Indonesia (id_ID).
class DateFormatter {
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
  static final DateFormat _timeFormat = DateFormat('HH:mm', 'id_ID');
  static final DateFormat _dayDateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yyyy', 'id_ID');

  /// Format lengkap tanggal dan jam: "16 Okt 2026, 14:05"
  static String formatDateTime(DateTime dateTime) {
    try {
      return _dateTimeFormat.format(dateTime);
    } catch (_) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Format tanggal dengan nama hari: "Jumat, 16 Oktober 2026"
  static String formatDayDate(DateTime dateTime) {
    try {
      return _dayDateFormat.format(dateTime);
    } catch (_) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Format tanggal saja: "16 Oktober 2026"
  static String formatDate(DateTime dateTime) {
    try {
      return _dateFormat.format(dateTime);
    } catch (_) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Format waktu saja: "14:05"
  static String formatTime(DateTime dateTime) {
    try {
      return _timeFormat.format(dateTime);
    } catch (_) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Format tanggal singkat: "16/10/2026"
  static String formatShortDate(DateTime dateTime) {
    try {
      return _shortDateFormat.format(dateTime);
    } catch (_) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
