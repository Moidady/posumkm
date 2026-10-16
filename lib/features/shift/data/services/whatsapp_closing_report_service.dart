import 'package:pos_umkm/features/shift/domain/entities/daily_closing_summary.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppClosingReportService {
  /// Membuka aplikasi WhatsApp langsung dengan pesan rekap harian tertuju ke nomor Owner
  static Future<bool> sendReportToOwner({
    required String rawPhoneNumber,
    required DailyClosingSummary summary,
  }) async {
    final message = summary.toWhatsAppMessage();

    // Normalisasi format nomor WhatsApp Indonesia (contoh: 081234567890 -> 6281234567890)
    var phone = rawPhoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    }

    final encodedMessage = Uri.encodeComponent(message);

    // 1. Coba luncurkan URL scheme WhatsApp langsung
    final whatsappUri = Uri.parse('whatsapp://send?phone=$phone&text=$encodedMessage');
    final webWaUri = Uri.parse('https://wa.me/$phone?text=$encodedMessage');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        return true;
      } else if (await canLaunchUrl(webWaUri)) {
        await launchUrl(webWaUri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (_) {
      // Abaikan dan gunakan fallback
    }

    // 2. Fallback aman menggunakan Share Dialog bawaan sistem jika WhatsApp URI gagal
    await Share.share(
      message,
      subject: 'Laporan Tutup Toko - ${summary.storeName}',
    );
    return true;
  }
}
