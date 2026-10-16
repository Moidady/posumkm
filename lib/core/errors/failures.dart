import 'package:equatable/equatable.dart';

/// Base class untuk seluruh kegagalan domain pada aplikasi PosUmkm.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Terjadi kesalahan pada database lokal.']);
}

class OrderValidationFailure extends Failure {
  const OrderValidationFailure([super.message = 'Validasi pesanan kasir gagal.']);
}

class InsufficientPaymentFailure extends Failure {
  final int shortfall;
  const InsufficientPaymentFailure(this.shortfall)
      : super('Nominal pembayaran kurang Rp $shortfall. Masukkan jumlah uang yang sesuai.');

  @override
  List<Object?> get props => [message, shortfall];
}

class QrisVerificationFailure extends Failure {
  const QrisVerificationFailure([super.message = 'Bukti pembayaran QRIS tidak valid atau kedaluwarsa.']);
}

class ShiftClosedFailure extends Failure {
  const ShiftClosedFailure([super.message = 'Shift kasir belum dibuka. Silakan buka shift terlebih dahulu.']);
}

class PinAuthFailure extends Failure {
  const PinAuthFailure([super.message = 'PIN otorisasi supervisor salah.']);
}
