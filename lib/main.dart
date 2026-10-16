import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'app.dart';
import 'core/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi databaseFactory sesuai platform (Web vs Desktop/Mobile)
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Pre-inisialisasi database SQLite lokal dan seed data F&B
  try {
    await AppDatabase.instance.database;
  } catch (e, stack) {
    debugPrint('Database initialization warning: $e\n$stack');
  }

  runApp(const PosUmkmApp());
}
