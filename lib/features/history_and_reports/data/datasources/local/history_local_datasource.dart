import 'dart:convert';
import 'package:pos_umkm/core/database/app_database.dart';
import 'package:pos_umkm/core/errors/exceptions.dart';
import 'package:pos_umkm/features/checkout/domain/entities/digital_receipt.dart';
import 'package:pos_umkm/features/checkout/domain/entities/order_entity.dart';
import 'package:pos_umkm/features/checkout/domain/entities/order_item_entity.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:uuid/uuid.dart';

class CashMovementRecord {
  final String id;
  final String type; // 'IN' atau 'OUT'
  final int amount;
  final String notes;
  final DateTime createdAt;

  const CashMovementRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.notes,
    required this.createdAt,
  });
}

class HistoryLocalDataSource {
  final AppDatabase appDatabase;
  static const _uuid = Uuid();

  HistoryLocalDataSource({AppDatabase? database})
      : appDatabase = database ?? AppDatabase.instance;

  /// Mengambil daftar transaksi hari ini beserta rincian itemnya
  Future<List<DigitalReceipt>> getTodayOrders() async {
    try {
      final db = await appDatabase.database;
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

      final settingsRows = await db.query('store_settings', limit: 1);
      final storeName = settingsRows.isNotEmpty
          ? settingsRows.first['store_name'] as String
          : 'Kedai Pos UMKM';
      final storeAddress = settingsRows.isNotEmpty
          ? settingsRows.first['address'] as String
          : 'Jl. Kuliner No. 12';
      final storePhone = settingsRows.isNotEmpty
          ? settingsRows.first['phone_number'] as String
          : '0812-3456-7890';

      final orderRows = await db.query(
        'orders',
        where: 'created_at >= ?',
        whereArgs: [startOfDay],
        orderBy: 'created_at DESC',
      );

      final List<DigitalReceipt> receipts = [];

      for (final row in orderRows) {
        final orderId = row['id'] as String;
        final itemRows = await db.query(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [orderId],
        );

        final items = itemRows.map((ir) {
          final rawJson = ir['selected_modifiers_json'] as String? ?? '[]';

          return OrderItemEntity(
            id: ir['id'] as String,
            orderId: orderId,
            productId: ir['product_id'] as String,
            productName: ir['product_name'] as String,
            unitPrice: (ir['unit_price'] as num).toInt(),
            quantity: (ir['quantity'] as num).toInt(),
            subtotal: (ir['subtotal'] as num).toInt(),
            notes: ir['notes'] as String? ?? '',
            selectedModifiersJson: rawJson,
          );
        }).toList();

        final order = OrderEntity(
          id: orderId,
          orderNumber: row['order_number'] as String,
          shiftId: row['shift_id'] as String?,
          subtotal: (row['subtotal'] as num).toInt(),
          discountAmount: (row['discount_amount'] as num?)?.toInt() ?? 0,
          taxAmount: (row['tax_amount'] as num?)?.toInt() ?? 0,
          totalAmount: (row['total_amount'] as num).toInt(),
          paymentMethod: row['payment_method'] as String? ?? 'CASH',
          cashTendered: (row['cash_tendered'] as num?)?.toInt() ?? 0,
          changeDue: (row['change_due'] as num?)?.toInt() ?? 0,
          qrisReferenceNo: row['qris_reference_no'] as String?,
          qrisScannedTimestamp: row['qris_scanned_timestamp'] as String?,
          qrisProofImagePath: row['qris_proof_image_path'] as String?,
          status: row['status'] as String? ?? 'PAID',
          createdAt: DateTime.fromMillisecondsSinceEpoch((row['created_at'] as num).toInt()),
          hlcTimestamp: row['hlc_timestamp'] as String? ?? '',
          items: items,
        );

        receipts.add(DigitalReceipt(
          storeName: storeName,
          storeAddress: storeAddress,
          storePhone: storePhone,
          order: order,
        ));
      }

      return receipts;
    } catch (e) {
      throw DatabaseException('Gagal memuat riwayat transaksi: ${e.toString()}');
    }
  }

  /// Membatalkan (Void) pesanan secara atomik (Aturan #6 AGENT.md)
  Future<void> voidOrder({
    required String orderId,
    required String reason,
  }) async {
    try {
      final db = await appDatabase.database;
      final nowIso = DateTime.now().toIso8601String();

      await db.transaction((txn) async {
        await txn.update(
          'orders',
          {
            'status': 'VOID',
            'hlc_timestamp': nowIso,
          },
          where: 'id = ?',
          whereArgs: [orderId],
        );

        await txn.insert('crdt_mutations', {
          'id': _uuid.v4(),
          'table_name': 'orders',
          'record_id': orderId,
          'action': 'VOID_ORDER',
          'payload_json': jsonEncode({
            'id': orderId,
            'status': 'VOID',
            'reason': reason,
          }),
          'hlc_timestamp': nowIso,
          'is_synced': 0,
        });
      });
    } catch (e) {
      throw DatabaseException('Gagal membatalkan pesanan: ${e.toString()}');
    }
  }

  /// Mencatat Kas Masuk / Kas Keluar Kecil (Cash Out Operasional)
  Future<void> addCashMovement({
    required String type, // 'IN' atau 'OUT'
    required int amount,
    required String notes,
  }) async {
    try {
      final db = await appDatabase.database;
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      const defaultShiftId = 'active-daily-shift';
      final movementId = _uuid.v4();

      await db.transaction((txn) async {
        // Pastikan shift aktif hari ini tersedia untuk memenuhi Foreign Key
        final existingShift = await txn.query(
          'shifts',
          where: 'id = ?',
          whereArgs: [defaultShiftId],
        );

        if (existingShift.isEmpty) {
          await txn.insert(
            'shifts',
            {
              'id': defaultShiftId,
              'cashier_name': 'Kasir Utama',
              'opened_at': startOfDay,
              'starting_cash': 200000,
              'cash_in': 0,
              'cash_out': 0,
              'status': 'OPEN',
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        await txn.insert('cash_movements', {
          'id': movementId,
          'shift_id': defaultShiftId,
          'type': type,
          'amount': amount,
          'notes': notes.trim(),
          'created_at': now.millisecondsSinceEpoch,
        });

        await txn.insert('crdt_mutations', {
          'id': _uuid.v4(),
          'table_name': 'cash_movements',
          'record_id': movementId,
          'action': 'INSERT',
          'payload_json': jsonEncode({
            'id': movementId,
            'type': type,
            'amount': amount,
            'notes': notes.trim(),
          }),
          'hlc_timestamp': now.toIso8601String(),
          'is_synced': 0,
        });
      });
    } catch (e) {
      throw DatabaseException('Gagal mencatat mutasi kas laci: ${e.toString()}');
    }
  }

  /// Mengambil daftar mutasi kas kecil hari ini
  Future<List<CashMovementRecord>> getTodayCashMovements() async {
    try {
      final db = await appDatabase.database;
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

      final rows = await db.query(
        'cash_movements',
        where: 'created_at >= ?',
        whereArgs: [startOfDay],
        orderBy: 'created_at DESC',
      );

      return rows.map((r) {
        return CashMovementRecord(
          id: r['id'] as String,
          type: r['type'] as String,
          amount: (r['amount'] as num).toInt(),
          notes: r['notes'] as String,
          createdAt: DateTime.fromMillisecondsSinceEpoch((r['created_at'] as num).toInt()),
        );
      }).toList();
    } catch (e) {
      throw DatabaseException('Gagal memuat mutasi kas: ${e.toString()}');
    }
  }
}
