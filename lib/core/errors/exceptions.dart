/// Base class untuk exception di data layer.
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class DatabaseException extends AppException {
  const DatabaseException([super.message = 'Gagal mengakses database lokal SQLite.']);
}

class PaymentProofExpiredException extends AppException {
  const PaymentProofExpiredException([super.message = 'Bukti pembayaran kedaluwarsa atau jam transaksi melebihi batas toleransi 10 menit.']);
}

class InvalidPaymentAmountException extends AppException {
  final int expected;
  final int detected;
  const InvalidPaymentAmountException({required this.expected, required this.detected})
      : super('Nominal bukti bayar (Rp $detected) tidak sesuai dengan total tagihan (Rp $expected).');
}

class KeywordNotFoundException extends AppException {
  const KeywordNotFoundException([super.message = 'Kata penanda sukses bayar (Berhasil / Sukses) tidak ditemukan pada layar.']);
}

class StoreSettingsNotConfiguredException extends AppException {
  const StoreSettingsNotConfiguredException([super.message = 'Pengaturan toko atau nomor WhatsApp Owner belum dikonfigurasi.']);
}
