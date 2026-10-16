import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_umkm/core/database/app_database.dart';
import 'package:pos_umkm/core/utils/currency_formatter.dart';
import 'package:pos_umkm/core/utils/date_formatter.dart';
import 'package:share_plus/share_plus.dart';

class ExcelExportService {
  final AppDatabase appDatabase;

  ExcelExportService({AppDatabase? database})
      : appDatabase = database ?? AppDatabase.instance;

  /// Menghasilkan file spreadsheet .xlsx dengan 3 sheet lengkap dan membagikannya
  Future<String> exportMonthlyReport({DateTime? targetMonth}) async {
    final db = await appDatabase.database;
    final now = targetMonth ?? DateTime.now();

    // Tentukan rentang waktu bulan
    final startOfMonth = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final nextMonth = now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
    final endOfMonth = nextMonth.millisecondsSinceEpoch;

    // Ambil data transaksi bulan ini
    final orderMaps = await db.rawQuery('''
      SELECT * FROM orders
      WHERE created_at >= ? AND created_at < ? AND status = 'PAID'
      ORDER BY created_at ASC
    ''', [startOfMonth, endOfMonth]);

    // Ambil data performa menu
    final itemMaps = await db.rawQuery('''
      SELECT 
        oi.product_name,
        c.name as category_name,
        SUM(oi.quantity) as total_qty,
        SUM(oi.subtotal) as total_sales
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      JOIN products p ON oi.product_id = p.id
      JOIN categories c ON p.category_id = c.id
      WHERE o.created_at >= ? AND o.created_at < ? AND o.status = 'PAID'
      GROUP BY oi.product_name
      ORDER BY total_qty DESC
    ''', [startOfMonth, endOfMonth]);

    // Buat Workbook Excel
    final excel = Excel.createExcel();
    excel.delete('Sheet1'); // Hapus sheet default

    // ==========================================
    // SHEET 1: RINGKASAN HARIAN
    // ==========================================
    final sheet1 = excel['Ringkasan Harian'];
    final headers1 = ['Tanggal', 'Jumlah Transaksi', 'Total Omzet (Rp)', 'Porsi Tunai (Rp)', 'Porsi QRIS (Rp)'];
    sheet1.appendRow(headers1.map((h) => TextCellValue(h)).toList());

    // Kelompokkan data per hari
    final Map<String, List<Map<String, dynamic>>> dailyGroups = {};
    for (final o in orderMaps) {
      final date = DateTime.fromMillisecondsSinceEpoch(o['created_at'] as int);
      final key = DateFormat('yyyy-MM-dd').format(date);
      dailyGroups.putIfAbsent(key, () => []).add(o);
    }

    int grandTotalOmzet = 0;
    int grandTotalTunai = 0;
    int grandTotalQris = 0;

    dailyGroups.forEach((dateKey, orders) {
      int dailyOmzet = 0;
      int dailyTunai = 0;
      int dailyQris = 0;

      for (final ord in orders) {
        final amount = ord['total_amount'] as int;
        dailyOmzet += amount;
        if (ord['payment_method'] == 'CASH') {
          dailyTunai += amount;
        } else {
          dailyQris += amount;
        }
      }

      grandTotalOmzet += dailyOmzet;
      grandTotalTunai += dailyTunai;
      grandTotalQris += dailyQris;

      sheet1.appendRow([
        TextCellValue(dateKey),
        IntCellValue(orders.length),
        IntCellValue(dailyOmzet),
        IntCellValue(dailyTunai),
        IntCellValue(dailyQris),
      ]);
    });

    // Baris Total Sheet 1
    sheet1.appendRow([
      TextCellValue('TOTAL BULANAN'),
      IntCellValue(orderMaps.length),
      IntCellValue(grandTotalOmzet),
      IntCellValue(grandTotalTunai),
      IntCellValue(grandTotalQris),
    ]);

    // ==========================================
    // SHEET 2: LOG TRANSAKSI LENGKAP
    // ==========================================
    final sheet2 = excel['Log Transaksi Lengkap'];
    final headers2 = ['No. Order', 'Waktu Transaksi', 'Metode Bayar', 'Total Tagihan (Rp)', 'No. Ref QRIS / Tunai'];
    sheet2.appendRow(headers2.map((h) => TextCellValue(h)).toList());

    for (final o in orderMaps) {
      final dt = DateTime.fromMillisecondsSinceEpoch(o['created_at'] as int);
      final ref = o['payment_method'] == 'CASH'
          ? 'Bayar: ${CurrencyFormatter.format(o['cash_tendered'] as int)}'
          : (o['qris_reference_no'] as String? ?? '-');

      sheet2.appendRow([
        TextCellValue(o['order_number'] as String),
        TextCellValue(DateFormatter.formatDateTime(dt)),
        TextCellValue(o['payment_method'] as String),
        IntCellValue(o['total_amount'] as int),
        TextCellValue(ref),
      ]);
    }

    // ==========================================
    // SHEET 3: PERFORMA MENU & PRODUK
    // ==========================================
    final sheet3 = excel['Performa Menu'];
    final headers3 = ['Kategori', 'Nama Menu', 'Porsi Terjual', 'Total Penjualan (Rp)'];
    sheet3.appendRow(headers3.map((h) => TextCellValue(h)).toList());

    for (final itm in itemMaps) {
      sheet3.appendRow([
        TextCellValue(itm['category_name'] as String? ?? 'Umum'),
        TextCellValue(itm['product_name'] as String),
        IntCellValue((itm['total_qty'] as num).toInt()),
        IntCellValue((itm['total_sales'] as num).toInt()),
      ]);
    }

    // Simpan & bagikan file spreadsheet
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Gagal meng-encode file Excel.');

    final fileName = 'Laporan_PosUmkm_${DateFormat('yyyy_MM').format(now)}.xlsx';

    if (kIsWeb) {
      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(bytes),
            name: fileName,
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        text: '📊 Laporan Penjualan Bulan ${DateFormat('MMMM yyyy', 'id_ID').format(now)}',
      );
      return fileName;
    } else {
      final tempDir = await getApplicationDocumentsDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '📊 Laporan Penjualan Bulan ${DateFormat('MMMM yyyy', 'id_ID').format(now)}',
      );
      return file.path;
    }
  }
}
