import 'package:equatable/equatable.dart';

class OrderItemEntity extends Equatable {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final int unitPrice;
  final int quantity;
  final int subtotal;
  final String notes;
  final String selectedModifiersJson;

  const OrderItemEntity({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    this.notes = '',
    this.selectedModifiersJson = '[]',
  });

  @override
  List<Object?> get props => [
        id,
        orderId,
        productId,
        productName,
        unitPrice,
        quantity,
        subtotal,
        notes,
        selectedModifiersJson,
      ];
}
