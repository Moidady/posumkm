import '../entities/digital_receipt.dart';
import '../repositories/order_repository.dart';
import '../../../pos/domain/entities/cart_item.dart';

class ProcessCheckoutUseCase {
  final OrderRepository repository;

  ProcessCheckoutUseCase(this.repository);

  Future<DigitalReceipt> execute({
    required List<CartItem> cartItems,
    required int subtotal,
    required int discountAmount,
    required int totalAmount,
    required String paymentMethod,
    required int cashTendered,
    required int changeDue,
    String? qrisReferenceNo,
    String? qrisScannedTimestamp,
    String? qrisProofImagePath,
    String? shiftId,
    String cashierName = 'Kasir 1',
    String deviceName = 'HP-KASIR-1',
  }) {
    return repository.processCheckout(
      cartItems: cartItems,
      subtotal: subtotal,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      cashTendered: cashTendered,
      changeDue: changeDue,
      qrisReferenceNo: qrisReferenceNo,
      qrisScannedTimestamp: qrisScannedTimestamp,
      qrisProofImagePath: qrisProofImagePath,
      shiftId: shiftId,
      cashierName: cashierName,
      deviceName: deviceName,
    );
  }
}
