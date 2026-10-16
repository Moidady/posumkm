import 'package:pos_umkm/core/utils/currency_formatter.dart';
import 'package:pos_umkm/features/checkout/domain/entities/qris_proof_result.dart';

/// UseCase Pure Dart untuk memvalidasi bukti pembayaran QRIS secara Offline
/// Sesuai Aturan #7 & Bagian 5 AGENT.md:
/// 1. Validasi Status Sukses ("Berhasil", "Sukses", "Selesai", "Successful")
/// 2. Validasi Tanggal Hari Ini & Rentang Jam <= 10 menit
/// 3. Validasi Kesesuaian Nominal Persis (int Rupiah)
class VerifyQrisProofUseCase {
  static const int maxToleranceMinutes = 10;

  QrisProofResult validateProof({
    required int expectedAmount,
    required int detectedAmount,
    required DateTime transactionTime,
    required String statusText,
    required String referenceNumber,
    DateTime? currentTime,
    String? proofImagePath,
  }) {
    final now = currentTime ?? DateTime.now();
    final normalizedStatus = statusText.toLowerCase();

    // 1. Validasi Kata Kunci Status Sukses
    final hasSuccessKeyword = normalizedStatus.contains('berhasil') ||
        normalizedStatus.contains('sukses') ||
        normalizedStatus.contains('selesai') ||
        normalizedStatus.contains('successful');

    if (!hasSuccessKeyword) {
      return QrisProofResult(
        isValid: false,
        detectedAmount: detectedAmount,
        referenceNumber: referenceNumber,
        transactionTimestamp: transactionTime,
        rawText: statusText,
        proofImagePath: proofImagePath,
        errorMessage:
            'Status pembayaran belum terdeteksi berhasil. Pastikan layar pembeli menampilkan status "Berhasil" atau "Sukses".',
      );
    }

    // 2. Validasi Tanggal Hari Ini & Toleransi Waktu <= 10 Menit
    final isSameDay = transactionTime.year == now.year &&
        transactionTime.month == now.month &&
        transactionTime.day == now.day;

    final diffMinutes = now.difference(transactionTime).inMinutes.abs();

    if (!isSameDay || diffMinutes > maxToleranceMinutes) {
      return QrisProofResult(
        isValid: false,
        detectedAmount: detectedAmount,
        referenceNumber: referenceNumber,
        transactionTimestamp: transactionTime,
        rawText: statusText,
        proofImagePath: proofImagePath,
        errorMessage:
            'Bukti transfer kedaluwarsa atau jam transaksi melebihi batas 10 menit. Pastikan pembeli menunjukkan bukti transaksi baru.',
      );
    }

    // 3. Validasi Nominal Uang Persis (Integer Rupiah)
    if (detectedAmount != expectedAmount) {
      final detectedStr = CurrencyFormatter.format(detectedAmount).replaceAll('Rp ', '');
      final expectedStr = CurrencyFormatter.format(expectedAmount).replaceAll('Rp ', '');
      return QrisProofResult(
        isValid: false,
        detectedAmount: detectedAmount,
        referenceNumber: referenceNumber,
        transactionTimestamp: transactionTime,
        rawText: statusText,
        proofImagePath: proofImagePath,
        errorMessage:
            'Nominal bukti bayar (Rp $detectedStr) tidak sesuai dengan total tagihan (Rp $expectedStr).',
      );
    }

    final cleanRrn = referenceNumber.trim().isEmpty
        ? 'RRN-${now.millisecondsSinceEpoch.toString().substring(5)}'
        : referenceNumber.trim();

    return QrisProofResult(
      isValid: true,
      detectedAmount: detectedAmount,
      referenceNumber: cleanRrn,
      transactionTimestamp: transactionTime,
      rawText: statusText,
      proofImagePath: proofImagePath,
    );
  }
}
