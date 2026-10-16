import 'package:pos_umkm/features/checkout/data/datasources/local/order_local_datasource.dart';
import 'package:pos_umkm/features/checkout/domain/entities/digital_receipt.dart';
import 'package:pos_umkm/features/checkout/domain/entities/order_entity.dart';
import 'package:pos_umkm/features/checkout/domain/repositories/order_repository.dart';
import 'package:pos_umkm/features/pos/domain/entities/cart_item.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderLocalDataSource localDataSource;

  OrderRepositoryImpl({OrderLocalDataSource? dataSource})
      : localDataSource = dataSource ?? OrderLocalDataSourceImpl();

  @override
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
  }) {
    return localDataSource.createOrder(
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
    );
  }

  @override
  Future<List<OrderEntity>> getOrders({int limit = 50}) =>
      localDataSource.getOrders(limit: limit);
}
