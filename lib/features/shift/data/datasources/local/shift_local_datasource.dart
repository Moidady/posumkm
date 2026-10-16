import 'package:pos_umkm/core/database/app_database.dart';
import 'package:pos_umkm/core/errors/exceptions.dart';
import 'package:pos_umkm/features/shift/domain/entities/daily_closing_summary.dart';
import 'package:uuid/uuid.dart';

abstract class ShiftLocalDataSource {
  Future<DailyClosingSummary> generateClosingSummary({
    required String cashierName,
    required int startingCash,
    required int actualCash,
    int cashIn = 0,
    int cashOut = 0,
  });

  Future<String> getOwnerWhatsAppNumber();
}

class ShiftLocalDataSourceImpl implements ShiftLocalDataSource {
  final AppDatabase appDatabase;
  static const _uuid = Uuid();

  ShiftLocalDataSourceImpl({AppDatabase? database})
      : appDatabase = database ?? AppDatabase.instance;

  @override
  Future<DailyClosingSummary> generateClosingSummary({
    required String cashierName,
    required int startingCash,
    required int actualCash,
    int cashIn = 0,
    int cashOut = 0,
  }) async {
    try {
      final db = await appDatabase.database;
      final now = DateTime.now();

      // Hitung batas awal hari ini (jam 00:00:00)
      final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

      // 1. Agregasi pesanan hari ini yang berstatus 'PAID'
      final ordersAgg = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_orders,
          COALESCE(SUM(total_amount), 0) as total_sales,
          COALESCE(SUM(CASE WHEN payment_method = 'CASH' THEN total_amount ELSE 0 END), 0) as cash_sales,
          COALESCE(SUM(CASE WHEN payment_method = 'QRIS' THEN total_amount ELSE 0 END), 0) as qris_sales
        FROM orders
        WHERE created_at >= ? AND status = 'PAID'
      ''', [startOfDay]);

      final totalOrders = (ordersAgg.first['total_orders'] as num?)?.toInt() ?? 0;
      final totalSales = (ordersAgg.first['total_sales'] as num?)?.toInt() ?? 0;
      final cashSales = (ordersAgg.first['cash_sales'] as num?)?.toInt() ?? 0;
      final qrisSales = (ordersAgg.first['qris_sales'] as num?)?.toInt() ?? 0;

      // 2. Query Top 5 Menu Terlaris Hari Ini
      final topProductsAgg = await db.rawQuery('''
        SELECT 
          oi.product_name,
          SUM(oi.quantity) as total_qty,
          SUM(oi.subtotal) as total_revenue
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.id
        WHERE o.created_at >= ? AND o.status = 'PAID'
        GROUP BY oi.product_name
        ORDER BY total_qty DESC
        LIMIT 5
      ''', [startOfDay]);

      final topProducts = topProductsAgg.map((row) {
        return TopProductSold(
          productName: row['product_name'] as String,
          quantity: (row['total_qty'] as num?)?.toInt() ?? 0,
          totalSales: (row['total_revenue'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      // 3. Ambil data nama toko
      final settingsList = await db.query('store_settings', limit: 1);
      final storeName = settingsList.isNotEmpty
          ? settingsList.first['store_name'] as String
          : 'Kedai Pos UMKM';

      // 4. Catat riwayat shift ke SQLite
      final shiftId = _uuid.v4();
      final systemCash = startingCash + cashSales + cashIn - cashOut;

      await db.insert('shifts', {
        'id': shiftId,
        'cashier_name': cashierName,
        'opened_at': startOfDay,
        'closed_at': now.millisecondsSinceEpoch,
        'starting_cash': startingCash,
        'actual_cash': actualCash,
        'system_cash': systemCash,
        'cash_in': cashIn,
        'cash_out': cashOut,
        'status': 'CLOSED',
      });

      return DailyClosingSummary(
        storeName: storeName,
        cashierName: cashierName,
        closingDate: now,
        totalOrders: totalOrders,
        totalSales: totalSales,
        cashSales: cashSales,
        qrisSales: qrisSales,
        startingCash: startingCash,
        cashIn: cashIn,
        cashOut: cashOut,
        actualCash: actualCash,
        topProducts: topProducts,
      );
    } catch (e) {
      throw DatabaseException('Gagal membuat rekap tutup toko: ${e.toString()}');
    }
  }

  @override
  Future<String> getOwnerWhatsAppNumber() async {
    try {
      final db = await appDatabase.database;
      final settingsList = await db.query('store_settings', limit: 1);
      if (settingsList.isNotEmpty) {
        final phone = settingsList.first['owner_whatsapp_number'] as String? ?? '';
        return phone.replaceAll(RegExp(r'[^0-9]'), '');
      }
      return '';
    } catch (_) {
      return '';
    }
  }
}
