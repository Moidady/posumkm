import 'package:intl/intl.dart';

/// Formatter standar untuk penanggalan dan waktu Indonesia (id_ID)
/// dilengkapi fallback nama bulan & hari Bahasa Indonesia agar bebas LocaleDataException.
class DateFormatter {
  static const List<String> _monthsFull = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const List<String> _daysFull = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  /// Format lengkap tanggal dan jam: "16 Okt 2026, 14:05"
  static String formatDateTime(DateTime dateTime) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
    } catch (_) {
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = _monthsShort[dateTime.month - 1];
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$day $month ${dateTime.year}, $hour:$minute';
    }
  }

  /// Format tanggal dengan nama hari: "Jumat, 16 Oktober 2026"
  static String formatDayDate(DateTime dateTime) {
    try {
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(dateTime);
    } catch (_) {
      final dayName = _daysFull[dateTime.weekday - 1];
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = _monthsFull[dateTime.month - 1];
      return '$dayName, $day $month ${dateTime.year}';
    }
  }

  /// Format tanggal saja: "16 Oktober 2026"
  static String formatDate(DateTime dateTime) {
    try {
      return DateFormat('dd MMMM yyyy', 'id_ID').format(dateTime);
    } catch (_) {
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = _monthsFull[dateTime.month - 1];
      return '$day $month ${dateTime.year}';
    }
  }

  /// Format bulan dan tahun: "Oktober 2026"
  static String formatMonthYear(DateTime dateTime) {
    try {
      return DateFormat('MMMM yyyy', 'id_ID').format(dateTime);
    } catch (_) {
      final month = _monthsFull[dateTime.month - 1];
      return '$month ${dateTime.year}';
    }
  }

  /// Format waktu saja: "14:05"
  static String formatTime(DateTime dateTime) {
    try {
      return DateFormat('HH:mm', 'id_ID').format(dateTime);
    } catch (_) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Format tanggal singkat: "16/10/2026"
  static String formatShortDate(DateTime dateTime) {
    try {
      return DateFormat('dd/MM/yyyy', 'id_ID').format(dateTime);
    } catch (_) {
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      return '$day/$month/${dateTime.year}';
    }
  }
}
