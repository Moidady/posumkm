import '../../domain/entities/digital_receipt.dart';
import '../../domain/entities/order_entity.dart';
import '../../../pos/domain/entities/cart_item.dart';

abstract class OrderRepository {
  Future<DigitalReceipt> processCheckout({
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
  });

  Future<List<OrderEntity>> getOrders({int limit = 50});
}
