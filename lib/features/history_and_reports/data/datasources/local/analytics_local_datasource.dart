import 'package:intl/intl.dart';
import 'package:pos_umkm/core/database/app_database.dart';

class DailySalesPoint {
  final String dateKey; // yyyy-MM-dd
  final String shortLabel; // dd/MM
  final int totalSales;
  final int orderCount;

  const DailySalesPoint({
    required this.dateKey,
    required this.shortLabel,
    required this.totalSales,
    required this.orderCount,
  });
}

class HourlySalesPoint {
  final int hour; // 0..23
  final int orderCount;
  final int totalSales;

  const HourlySalesPoint({
    required this.hour,
    required this.orderCount,
    required this.totalSales,
  });

  String get hourLabel => '${hour.toString().padLeft(2, '0')}:00';
}

class TopMenuPerformance {
  final String productName;
  final String categoryName;
  final String imageUrl;
  final int totalQty;
  final int totalSales;

  const TopMenuPerformance({
    required this.productName,
    required this.categoryName,
    required this.imageUrl,
    required this.totalQty,
    required this.totalSales,
  });
}

class CategoryPerformance {
  final String categoryName;
  final int totalQty;
  final int totalSales;

  const CategoryPerformance({
    required this.categoryName,
    required this.totalQty,
    required this.totalSales,
  });
}

class DeviceCashierPerformance {
  final String deviceName;
  final String cashierName;
  final int orderCount;
  final int totalSales;
  final int cashSales;
  final int qrisSales;

  const DeviceCashierPerformance({
    required this.deviceName,
    required this.cashierName,
    required this.orderCount,
    required this.totalSales,
    required this.cashSales,
    required this.qrisSales,
  });
}

class AnalyticsDashboardData {
  final int totalOmzet;
  final int totalOrders;
  final int averageBasketSize;
  final int cashOmzet;
  final int qrisOmzet;
  final int totalItemsSold;
  final String busiestHourRange;
  final List<String> availableDevices;
  final List<DailySalesPoint> dailyTrend;
  final List<HourlySalesPoint> hourlyPeak;
  final List<TopMenuPerformance> topMenus;
  final List<CategoryPerformance> categoryBreakdown;
  final List<DeviceCashierPerformance> deviceBreakdown;

  const AnalyticsDashboardData({
    required this.totalOmzet,
    required this.totalOrders,
    required this.averageBasketSize,
    required this.cashOmzet,
    required this.qrisOmzet,
    required this.totalItemsSold,
    required this.busiestHourRange,
    required this.availableDevices,
    required this.dailyTrend,
    required this.hourlyPeak,
    required this.topMenus,
    required this.categoryBreakdown,
    required this.deviceBreakdown,
  });
}

class AnalyticsLocalDataSource {
  final AppDatabase appDatabase;

  AnalyticsLocalDataSource({AppDatabase? database})
      : appDatabase = database ?? AppDatabase.instance;

  Future<AnalyticsDashboardData> loadDashboardData({
    required String period, // 'TODAY', '7DAYS', 'MONTH', 'ALL'
    String deviceFilter = 'ALL',
  }) async {
    final db = await appDatabase.database;
    final now = DateTime.now();

    int startMillis = 0;
    if (period == 'TODAY') {
      startMillis = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    } else if (period == '7DAYS') {
      startMillis = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6))
          .millisecondsSinceEpoch;
    } else if (period == 'MONTH') {
      startMillis = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    }

    // Ambil daftar perangkat unik yang pernah bertransaksi atau terdaftar
    final deviceRows = await db.rawQuery('''
      SELECT DISTINCT device_name FROM orders WHERE device_name IS NOT NULL AND device_name != ''
      UNION
      SELECT DISTINCT assigned_device FROM users WHERE assigned_device IS NOT NULL AND assigned_device != ''
    ''');
    final availableDevices = deviceRows
        .map((r) => (r.values.first as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toList()
      ..sort();

    // Filter query orders
    final whereClauses = <String>["status = 'PAID'", 'created_at >= ?'];
    final whereArgs = <Object?>[startMillis];

    if (deviceFilter != 'ALL') {
      whereClauses.add('device_name = ?');
      whereArgs.add(deviceFilter);
    }

    final whereSql = whereClauses.join(' AND ');

    final orders = await db.rawQuery('''
      SELECT * FROM orders
      WHERE $whereSql
      ORDER BY created_at ASC
    ''', whereArgs);

    int totalOmzet = 0;
    int cashOmzet = 0;
    int qrisOmzet = 0;

    final Map<String, List<Map<String, dynamic>>> dailyMap = {};
    final Map<int, List<Map<String, dynamic>>> hourlyMap = {};
    final Map<String, List<Map<String, dynamic>>> deviceCashierMap = {};

    for (final o in orders) {
      final amount = (o['total_amount'] as num?)?.toInt() ?? 0;
      final method = o['payment_method'] as String? ?? 'CASH';
      final createdAt =
          DateTime.fromMillisecondsSinceEpoch(o['created_at'] as int);
      final dev = o['device_name'] as String? ?? 'HP-KASIR-1';
      final cashier = o['cashier_name'] as String? ?? 'Kasir 1';

      totalOmzet += amount;
      if (method == 'CASH') {
        cashOmzet += amount;
      } else {
        qrisOmzet += amount;
      }

      final dateKey = DateFormat('yyyy-MM-dd').format(createdAt);
      dailyMap.putIfAbsent(dateKey, () => []).add(o);

      hourlyMap.putIfAbsent(createdAt.hour, () => []).add(o);

      final devKey = '$dev|||$cashier';
      deviceCashierMap.putIfAbsent(devKey, () => []).add(o);
    }

    // Susun Daily Trend (minimal 7 titik terakhir jika kosong/sedikit agar grafik rapi)
    final List<DailySalesPoint> dailyTrend = [];
    if (period == 'TODAY' || period == '7DAYS') {
      final daysCount = period == 'TODAY' ? 1 : 7;
      for (int i = daysCount - 1; i >= 0; i--) {
        final d = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: i));
        final key = DateFormat('yyyy-MM-dd').format(d);
        final shortLabel = DateFormat('dd/MM').format(d);
        final dayOrders = dailyMap[key] ?? [];
        final daySum = dayOrders.fold<int>(
          0,
          (sum, item) => sum + ((item['total_amount'] as num?)?.toInt() ?? 0),
        );
        dailyTrend.add(DailySalesPoint(
          dateKey: key,
          shortLabel: shortLabel,
          totalSales: daySum,
          orderCount: dayOrders.length,
        ));
      }
    } else {
      final sortedKeys = dailyMap.keys.toList()..sort();
      for (final key in sortedKeys) {
        final dayOrders = dailyMap[key]!;
        final dt = DateTime.tryParse(key) ?? now;
        final daySum = dayOrders.fold<int>(
          0,
          (sum, item) => sum + ((item['total_amount'] as num?)?.toInt() ?? 0),
        );
        dailyTrend.add(DailySalesPoint(
          dateKey: key,
          shortLabel: DateFormat('dd/MM').format(dt),
          totalSales: daySum,
          orderCount: dayOrders.length,
        ));
      }
    }

    // Susun Hourly Peak (jam operasional 08:00 s/d 22:00 + jam aktif lainnya)
    final List<HourlySalesPoint> hourlyPeak = [];
    int maxHourCount = 0;
    int? busiestHour;

    for (int h = 8; h <= 22; h++) {
      final hOrders = hourlyMap[h] ?? [];
      final hSales = hOrders.fold<int>(
        0,
        (sum, item) => sum + ((item['total_amount'] as num?)?.toInt() ?? 0),
      );
      if (hOrders.length > maxHourCount) {
        maxHourCount = hOrders.length;
        busiestHour = h;
      }
      hourlyPeak.add(HourlySalesPoint(
        hour: h,
        orderCount: hOrders.length,
        totalSales: hSales,
      ));
    }

    // Cek juga jika ada transaksi di luar jam 08..22 (misal tengah malam)
    for (final entry in hourlyMap.entries) {
      if (entry.key < 8 || entry.key > 22) {
        final hOrders = entry.value;
        final hSales = hOrders.fold<int>(
          0,
          (sum, item) => sum + ((item['total_amount'] as num?)?.toInt() ?? 0),
        );
        if (hOrders.length > maxHourCount) {
          maxHourCount = hOrders.length;
          busiestHour = entry.key;
        }
        hourlyPeak.add(HourlySalesPoint(
          hour: entry.key,
          orderCount: hOrders.length,
          totalSales: hSales,
        ));
      }
    }
    hourlyPeak.sort((a, b) => a.hour.compareTo(b.hour));

    final busiestHourRange = busiestHour != null
        ? '${busiestHour.toString().padLeft(2, '0')}:00 - ${(busiestHour + 1).toString().padLeft(2, '0')}:00 ($maxHourCount transaksi)'
        : 'Belum ada transaksi';

    // Query Top Menu & Kategori
    final itemWhereClauses = <String>[
      "o.status = 'PAID'",
      'o.created_at >= ?',
    ];
    final itemWhereArgs = <Object?>[startMillis];
    if (deviceFilter != 'ALL') {
      itemWhereClauses.add('o.device_name = ?');
      itemWhereArgs.add(deviceFilter);
    }

    final itemRows = await db.rawQuery('''
      SELECT 
        oi.product_name,
        COALESCE(c.name, 'Menu Lainnya') as category_name,
        COALESCE(p.image_url, '') as image_url,
        SUM(oi.quantity) as total_qty,
        SUM(oi.subtotal) as total_sales
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      LEFT JOIN products p ON oi.product_id = p.id
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE ${itemWhereClauses.join(' AND ')}
      GROUP BY oi.product_name
      ORDER BY total_qty DESC, total_sales DESC
    ''', itemWhereArgs);

    int totalItemsSold = 0;
    final List<TopMenuPerformance> topMenus = [];
    final Map<String, CategoryPerformance> catMap = {};

    for (final r in itemRows) {
      final qty = (r['total_qty'] as num?)?.toInt() ?? 0;
      final sales = (r['total_sales'] as num?)?.toInt() ?? 0;
      final prodName = r['product_name'] as String? ?? 'Menu';
      final catName = r['category_name'] as String? ?? 'Menu Lainnya';
      final imgUrl = r['image_url'] as String? ?? '';

      totalItemsSold += qty;

      topMenus.add(TopMenuPerformance(
        productName: prodName,
        categoryName: catName,
        imageUrl: imgUrl,
        totalQty: qty,
        totalSales: sales,
      ));

      final existingCat = catMap[catName];
      if (existingCat == null) {
        catMap[catName] = CategoryPerformance(
          categoryName: catName,
          totalQty: qty,
          totalSales: sales,
        );
      } else {
        catMap[catName] = CategoryPerformance(
          categoryName: catName,
          totalQty: existingCat.totalQty + qty,
          totalSales: existingCat.totalSales + sales,
        );
      }
    }

    final categoryBreakdown = catMap.values.toList()
      ..sort((a, b) => b.totalSales.compareTo(a.totalSales));

    // Rekap Performa per HP Kasir
    final List<DeviceCashierPerformance> deviceBreakdown = [];
    deviceCashierMap.forEach((key, devOrders) {
      final parts = key.split('|||');
      final devName = parts.first;
      final cashName = parts.length > 1 ? parts[1] : 'Kasir';

      int dTotal = 0;
      int dCash = 0;
      int dQris = 0;
      for (final ord in devOrders) {
        final amt = (ord['total_amount'] as num?)?.toInt() ?? 0;
        dTotal += amt;
        if (ord['payment_method'] == 'CASH') {
          dCash += amt;
        } else {
          dQris += amt;
        }
      }

      deviceBreakdown.add(DeviceCashierPerformance(
        deviceName: devName,
        cashierName: cashName,
        orderCount: devOrders.length,
        totalSales: dTotal,
        cashSales: dCash,
        qrisSales: dQris,
      ));
    });
    deviceBreakdown.sort((a, b) => b.totalSales.compareTo(a.totalSales));

    final averageBasket =
        orders.isNotEmpty ? (totalOmzet ~/ orders.length) : 0;

    return AnalyticsDashboardData(
      totalOmzet: totalOmzet,
      totalOrders: orders.length,
      averageBasketSize: averageBasket,
      cashOmzet: cashOmzet,
      qrisOmzet: qrisOmzet,
      totalItemsSold: totalItemsSold,
      busiestHourRange: busiestHourRange,
      availableDevices: availableDevices,
      dailyTrend: dailyTrend,
      hourlyPeak: hourlyPeak,
      topMenus: topMenus,
      categoryBreakdown: categoryBreakdown,
      deviceBreakdown: deviceBreakdown,
    );
  }
}
