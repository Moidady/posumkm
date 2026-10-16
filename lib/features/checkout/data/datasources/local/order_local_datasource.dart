import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:pos_umkm/core/database/app_database.dart';
import 'package:pos_umkm/core/errors/exceptions.dart';
import 'package:pos_umkm/features/checkout/domain/entities/digital_receipt.dart';
import 'package:pos_umkm/features/checkout/domain/entities/order_entity.dart';
import 'package:pos_umkm/features/checkout/domain/entities/order_item_entity.dart';
import 'package:pos_umkm/features/pos/domain/entities/cart_item.dart';
import 'package:uuid/uuid.dart';

abstract class OrderLocalDataSource {
  Future<DigitalReceipt> createOrder({
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

class OrderLocalDataSourceImpl implements OrderLocalDataSource {
  final AppDatabase appDatabase;
  static const _uuid = Uuid();

  OrderLocalDataSourceImpl({AppDatabase? database})
      : appDatabase = database ?? AppDatabase.instance;

  @override
  Future<DigitalReceipt> createOrder({
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
  }) async {
    final db = await appDatabase.database;
    final orderId = _uuid.v4();
    final now = DateTime.now();
    final nowMillis = now.millisecondsSinceEpoch;

    // Format nomor order manusiawi: ORD-20261016-1234
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final randomDigits = (Random().nextInt(9000) + 1000).toString();
    final orderNumber = 'ORD-$dateStr-$randomDigits';
    final hlcTimestamp = '${nowMillis}_0_device';

    final orderItemsToInsert = <OrderItemEntity>[];

    for (final cartItem in cartItems) {
      final itemId = _uuid.v4();
      final modifiersJson = jsonEncode(cartItem.selectedModifiers
          .map((m) => {
                'id': m.id,
                'name': m.name,
                'extra_price': m.extraPrice,
                'group': m.groupName,
              })
          .toList());

      orderItemsToInsert.add(OrderItemEntity(
        id: itemId,
        orderId: orderId,
        productId: cartItem.product.id,
        productName: cartItem.product.name,
        unitPrice: cartItem.unitPrice,
        quantity: cartItem.quantity,
        subtotal: cartItem.subtotal,
        notes: cartItem.notes,
        selectedModifiersJson: modifiersJson,
      ));
    }

    try {
      // Eksekusi atomik menggunakan db.transaction
      await db.transaction((txn) async {
        // 1. Simpan tabel orders
        await txn.insert('orders', {
          'id': orderId,
          'order_number': orderNumber,
          'shift_id': shiftId,
          'subtotal': subtotal,
          'discount_amount': discountAmount,
          'tax_amount': 0,
          'total_amount': totalAmount,
          'payment_method': paymentMethod,
          'cash_tendered': cashTendered,
          'change_due': changeDue,
          'qris_reference_no': qrisReferenceNo,
          'qris_scanned_timestamp': qrisScannedTimestamp,
          'qris_proof_image_path': qrisProofImagePath,
          'status': 'PAID',
          'created_at': nowMillis,
          'hlc_timestamp': hlcTimestamp,
        });

        // 2. Simpan setiap order_item
        for (final item in orderItemsToInsert) {
          await txn.insert('order_items', {
            'id': item.id,
            'order_id': orderId,
            'product_id': item.productId,
            'product_name': item.productName,
            'unit_price': item.unitPrice,
            'quantity': item.quantity,
            'subtotal': item.subtotal,
            'notes': item.notes,
            'selected_modifiers_json': item.selectedModifiersJson,
          });
        }

        // 3. Catat mutasi CRDT sync queue
        await txn.insert('crdt_mutations', {
          'id': _uuid.v4(),
          'table_name': 'orders',
          'record_id': orderId,
          'action': 'INSERT',
          'payload_json': jsonEncode({
            'order_number': orderNumber,
            'total_amount': totalAmount,
            'payment_method': paymentMethod,
            'items_count': orderItemsToInsert.length,
          }),
          'hlc_timestamp': hlcTimestamp,
          'is_synced': 0,
        });
      });

      // Ambil data toko untuk struk
      final settingsList = await db.query('store_settings', limit: 1);
      final storeName = settingsList.isNotEmpty
          ? settingsList.first['store_name'] as String
          : 'Kedai Pos UMKM';
      final storeAddress = settingsList.isNotEmpty
          ? settingsList.first['address'] as String
          : 'Pusat Kuliner UMKM';
      final storePhone = settingsList.isNotEmpty
          ? settingsList.first['phone_number'] as String
          : '0812-3456-7890';

      final createdOrder = OrderEntity(
        id: orderId,
        orderNumber: orderNumber,
        shiftId: shiftId,
        subtotal: subtotal,
        discountAmount: discountAmount,
        taxAmount: 0,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        cashTendered: cashTendered,
        changeDue: changeDue,
        qrisReferenceNo: qrisReferenceNo,
        qrisScannedTimestamp: qrisScannedTimestamp,
        qrisProofImagePath: qrisProofImagePath,
        status: 'PAID',
        createdAt: now,
        hlcTimestamp: hlcTimestamp,
        items: orderItemsToInsert,
      );

      return DigitalReceipt(
        order: createdOrder,
        storeName: storeName,
        storeAddress: storeAddress,
        storePhone: storePhone,
      );
    } catch (e) {
      throw DatabaseException('Gagal memproses pesanan kasir: ${e.toString()}');
    }
  }

  @override
  Future<List<OrderEntity>> getOrders({int limit = 50}) async {
    try {
      final db = await appDatabase.database;
      final orderMaps = await db.query(
        'orders',
        orderBy: 'created_at DESC',
        limit: limit,
      );

      final List<OrderEntity> orders = [];

      for (final oMap in orderMaps) {
        final orderId = oMap['id'] as String;
        final itemMaps = await db.query(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [orderId],
        );

        final items = itemMaps.map((iMap) {
          return OrderItemEntity(
            id: iMap['id'] as String,
            orderId: orderId,
            productId: iMap['product_id'] as String,
            productName: iMap['product_name'] as String,
            unitPrice: iMap['unit_price'] as int,
            quantity: iMap['quantity'] as int,
            subtotal: iMap['subtotal'] as int,
            notes: iMap['notes'] as String? ?? '',
            selectedModifiersJson: iMap['selected_modifiers_json'] as String? ?? '[]',
          );
        }).toList();

        orders.add(OrderEntity(
          id: orderId,
          orderNumber: oMap['order_number'] as String,
          shiftId: oMap['shift_id'] as String?,
          subtotal: oMap['subtotal'] as int,
          discountAmount: oMap['discount_amount'] as int? ?? 0,
          taxAmount: oMap['tax_amount'] as int? ?? 0,
          totalAmount: oMap['total_amount'] as int,
          paymentMethod: oMap['payment_method'] as String,
          cashTendered: oMap['cash_tendered'] as int? ?? 0,
          changeDue: oMap['change_due'] as int? ?? 0,
          qrisReferenceNo: oMap['qris_reference_no'] as String?,
          qrisScannedTimestamp: oMap['qris_scanned_timestamp'] as String?,
          qrisProofImagePath: oMap['qris_proof_image_path'] as String?,
          status: oMap['status'] as String? ?? 'PAID',
          createdAt: DateTime.fromMillisecondsSinceEpoch(oMap['created_at'] as int),
          hlcTimestamp: oMap['hlc_timestamp'] as String? ?? '',
          items: items,
        ));
      }

      return orders;
    } catch (e) {
      throw DatabaseException('Gagal memuat riwayat transaksi: ${e.toString()}');
    }
  }
}
