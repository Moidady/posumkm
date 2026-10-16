import 'dart:convert';
import 'package:pos_umkm/core/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class SyncImportResult {
  final String sourceDevice;
  final String exportedBy;
  final int ordersMerged;
  final int itemsMerged;
  final int productsMerged;
  final int usersMerged;

  const SyncImportResult({
    required this.sourceDevice,
    required this.exportedBy,
    required this.ordersMerged,
    required this.itemsMerged,
    required this.productsMerged,
    required this.usersMerged,
  });
}

/// Layanan Sinkronisasi Multi-HP / Tablet (Idempotent CRDT / UUID Merge)
/// Memungkinkan 2 atau lebih HP/Tablet kasir menggabungkan transaksi, menu,
/// dan akun kasir secara utuh tanpa duplikasi data.
class MultiDeviceSyncService {
  final AppDatabase appDatabase;

  MultiDeviceSyncService({AppDatabase? database})
      : appDatabase = database ?? AppDatabase.instance;

  /// Mengekspor seluruh paket data transaksi & katalog dari HP ini ke format JSON
  Future<String> exportSyncJson({
    required String deviceName,
    required String cashierName,
  }) async {
    final db = await appDatabase.database;

    final orders = await db.query('orders');
    final orderItems = await db.query('order_items');
    final shifts = await db.query('shifts');
    final cashMovements = await db.query('cash_movements');
    final users = await db.query('users');
    final categories = await db.query('categories');
    final products = await db.query('products');
    final modifiers = await db.query('product_modifiers');

    final payload = {
      'schema': 'pos_umkm_multi_device_sync_v1',
      'exported_at': DateTime.now().toIso8601String(),
      'source_device': deviceName,
      'exported_by': cashierName,
      'data': {
        'users': users,
        'categories': categories,
        'products': products,
        'product_modifiers': modifiers,
        'shifts': shifts,
        'cash_movements': cashMovements,
        'orders': orders,
        'order_items': orderItems,
      },
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Menggabungkan paket data JSON dari HP Kasir lain ke database HP ini secara atomik
  Future<SyncImportResult> importSyncJson(String rawJson) async {
    final decoded = jsonDecode(rawJson.trim());
    if (decoded is! Map<String, dynamic> ||
        decoded['schema'] != 'pos_umkm_multi_device_sync_v1') {
      throw const FormatException(
        'Format kode/file sinkronisasi tidak valid. Pastikan berasal dari menu Sinkronisasi Multi-HP PosUmkm.',
      );
    }

    final sourceDevice = decoded['source_device'] as String? ?? 'HP-KASIR';
    final exportedBy = decoded['exported_by'] as String? ?? 'Kasir';
    final data = decoded['data'] as Map<String, dynamic>? ?? {};

    final users = List<Map<String, dynamic>>.from(data['users'] as List? ?? []);
    final categories =
        List<Map<String, dynamic>>.from(data['categories'] as List? ?? []);
    final products =
        List<Map<String, dynamic>>.from(data['products'] as List? ?? []);
    final modifiers = List<Map<String, dynamic>>.from(
        data['product_modifiers'] as List? ?? []);
    final shifts =
        List<Map<String, dynamic>>.from(data['shifts'] as List? ?? []);
    final cashMovements =
        List<Map<String, dynamic>>.from(data['cash_movements'] as List? ?? []);
    final orders =
        List<Map<String, dynamic>>.from(data['orders'] as List? ?? []);
    final orderItems =
        List<Map<String, dynamic>>.from(data['order_items'] as List? ?? []);

    final db = await appDatabase.database;

    int ordersCount = 0;
    int itemsCount = 0;
    int productsCount = 0;
    int usersCount = 0;

    await db.transaction((txn) async {
      for (final u in users) {
        await txn.insert(
          'users',
          Map<String, Object?>.from(u),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        usersCount++;
      }

      for (final c in categories) {
        await txn.insert(
          'categories',
          Map<String, Object?>.from(c),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final p in products) {
        await txn.insert(
          'products',
          Map<String, Object?>.from(p),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        productsCount++;
      }

      for (final m in modifiers) {
        await txn.insert(
          'product_modifiers',
          Map<String, Object?>.from(m),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final s in shifts) {
        await txn.insert(
          'shifts',
          Map<String, Object?>.from(s),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final cm in cashMovements) {
        await txn.insert(
          'cash_movements',
          Map<String, Object?>.from(cm),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      for (final o in orders) {
        final orderMap = Map<String, Object?>.from(o);
        orderMap.putIfAbsent('cashier_name', () => exportedBy);
        orderMap.putIfAbsent('device_name', () => sourceDevice);
        await txn.insert(
          'orders',
          orderMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        ordersCount++;
      }

      for (final oi in orderItems) {
        await txn.insert(
          'order_items',
          Map<String, Object?>.from(oi),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        itemsCount++;
      }
    });

    return SyncImportResult(
      sourceDevice: sourceDevice,
      exportedBy: exportedBy,
      ordersMerged: ordersCount,
      itemsMerged: itemsCount,
      productsMerged: productsCount,
      usersMerged: usersCount,
    );
  }
}
