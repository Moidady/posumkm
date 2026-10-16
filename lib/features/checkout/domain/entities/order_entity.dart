import 'package:equatable/equatable.dart';
import 'order_item_entity.dart';

class OrderEntity extends Equatable {
  final String id;
  final String orderNumber;
  final String? shiftId;
  final int subtotal;
  final int discountAmount;
  final int taxAmount;
  final int totalAmount;
  final String paymentMethod; // 'CASH' atau 'QRIS'
  final int cashTendered;
  final int changeDue;
  final String? qrisReferenceNo;
  final String? qrisScannedTimestamp;
  final String? qrisProofImagePath;
  final String status; // 'PAID' atau 'VOID'
  final String cashierName;
  final String deviceName;
  final DateTime createdAt;
  final String hlcTimestamp;
  final List<OrderItemEntity> items;

  const OrderEntity({
    required this.id,
    required this.orderNumber,
    this.shiftId,
    required this.subtotal,
    this.discountAmount = 0,
    this.taxAmount = 0,
    required this.totalAmount,
    required this.paymentMethod,
    this.cashTendered = 0,
    this.changeDue = 0,
    this.qrisReferenceNo,
    this.qrisScannedTimestamp,
    this.qrisProofImagePath,
    this.status = 'PAID',
    this.cashierName = 'Kasir 1',
    this.deviceName = 'HP-KASIR-1',
    required this.createdAt,
    required this.hlcTimestamp,
    this.items = const [],
  });

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        shiftId,
        subtotal,
        discountAmount,
        taxAmount,
        totalAmount,
        paymentMethod,
        cashTendered,
        changeDue,
        qrisReferenceNo,
        qrisScannedTimestamp,
        qrisProofImagePath,
        status,
        cashierName,
        deviceName,
        createdAt,
        hlcTimestamp,
        items,
      ];
}
