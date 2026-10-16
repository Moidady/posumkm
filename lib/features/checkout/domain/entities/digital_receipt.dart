import 'package:equatable/equatable.dart';
import 'package:pos_umkm/core/utils/currency_formatter.dart';
import 'package:pos_umkm/core/utils/date_formatter.dart';
import 'package:pos_umkm/features/checkout/domain/entities/order_entity.dart';

class DigitalReceipt extends Equatable {
  final OrderEntity order;
  final String storeName;
  final String storeAddress;
  final String storePhone;

  const DigitalReceipt({
    required this.order,
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
  });

  /// Menyusun teks ringkasan rapi untuk dikirimkan ke WhatsApp pelanggan
  String toWhatsAppMessage() {
    final buffer = StringBuffer();
    buffer.writeln('================================');
    buffer.writeln('🧾 *STRUK PEMBELIAN*');
    buffer.writeln('*$storeName*');
    buffer.writeln(storeAddress);
    buffer.writeln('WA: $storePhone');
    buffer.writeln('================================');
    buffer.writeln('No. Pesanan : ${order.orderNumber}');
    buffer.writeln('Kasir / HP  : ${order.cashierName} (${order.deviceName})');
    buffer.writeln('Tanggal     : ${DateFormatter.formatDateTime(order.createdAt)}');
    buffer.writeln('--------------------------------');

    for (final item in order.items) {
      buffer.writeln('${item.quantity}x ${item.productName}');
      if (item.notes.isNotEmpty) {
        buffer.writeln('   _Catatan: ${item.notes}_');
      }
      buffer.writeln('   @${CurrencyFormatter.format(item.unitPrice)} = ${CurrencyFormatter.format(item.subtotal)}');
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('Subtotal : ${CurrencyFormatter.format(order.subtotal)}');
    if (order.discountAmount > 0) {
      buffer.writeln('Diskon   : -${CurrencyFormatter.format(order.discountAmount)}');
    }
    buffer.writeln('*TOTAL    : ${CurrencyFormatter.format(order.totalAmount)}*');
    buffer.writeln('Metode   : ${order.paymentMethod}');

    if (order.paymentMethod == 'CASH') {
      buffer.writeln('Tunai    : ${CurrencyFormatter.format(order.cashTendered)}');
      buffer.writeln('Kembali  : ${CurrencyFormatter.format(order.changeDue)}');
    } else {
      buffer.writeln('Status   : LUNAS QRIS');
      if (order.qrisReferenceNo != null && order.qrisReferenceNo!.isNotEmpty) {
        buffer.writeln('No. Ref  : ${order.qrisReferenceNo}');
      }
    }

    buffer.writeln('================================');
    buffer.writeln('Terima kasih atas kunjungan Anda!');
    buffer.writeln('Simpan struk ini sebagai bukti pembayaran.');
    return buffer.toString();
  }

  @override
  List<Object?> get props => [order, storeName, storeAddress, storePhone];
}
