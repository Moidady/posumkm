import 'package:intl/intl.dart';

/// Formatter standar untuk nominal mata uang Rupiah Indonesia.
/// Mematuhi aturan PRD & AGENT: Nominal selalu berupa integer (bukan double).
class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Mengonversi nilai integer Rupiah menjadi format tampilan (contoh: 15000 -> "Rp 15.000")
  static String format(int amount) {
    try {
      return _formatter.format(amount);
    } catch (_) {
      // Fallback manual jika locale id_ID belum terinisialisasi
      final str = amount.toString();
      final buffer = StringBuffer();
      for (int i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) {
          buffer.write('.');
        }
        buffer.write(str[i]);
      }
      return 'Rp ${buffer.toString()}';
    }
  }

  /// Membersihkan input teks dari simbol dan mengembalikan nilai integer bersih
  static int parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return 0;
    return int.tryParse(cleaned) ?? 0;
  }
}
