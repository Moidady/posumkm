import 'dart:convert';
import 'package:pos_umkm/core/database/app_database.dart';
import 'package:pos_umkm/core/errors/exceptions.dart';
import 'package:pos_umkm/features/settings/data/models/store_settings_model.dart';
import 'package:pos_umkm/features/settings/domain/entities/store_settings.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:uuid/uuid.dart';

abstract class SettingsLocalDataSource {
  Future<StoreSettings> getStoreSettings();
  Future<StoreSettings> updateStoreSettings(StoreSettings settings);
  Future<bool> verifyOwnerPin(String inputPin);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final AppDatabase appDatabase;
  static const _uuid = Uuid();

  SettingsLocalDataSourceImpl({AppDatabase? database})
      : appDatabase = database ?? AppDatabase.instance;

  @override
  Future<StoreSettings> getStoreSettings() async {
    try {
      final db = await appDatabase.database;
      final rows = await db.query('store_settings', limit: 1);
      if (rows.isEmpty) {
        const defaultSettings = StoreSettingsModel(
          id: 'default-store',
          storeName: 'Kedai Pos UMKM',
          address: 'Jl. Kuliner No. 12, Foodcourt Stand B-04',
          phoneNumber: '0812-3456-7890',
          ownerWhatsappNumber: '081234567890',
          ownerPinHash: '123456',
        );
        await db.insert(
          'store_settings',
          defaultSettings.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return defaultSettings;
      }
      return StoreSettingsModel.fromMap(rows.first);
    } catch (e) {
      throw DatabaseException('Gagal memuat pengaturan toko: ${e.toString()}');
    }
  }

  @override
  Future<StoreSettings> updateStoreSettings(StoreSettings settings) async {
    try {
      final db = await appDatabase.database;
      final model = StoreSettingsModel(
        id: settings.id.isEmpty ? 'default-store' : settings.id,
        storeName: settings.storeName.trim(),
        address: settings.address.trim(),
        phoneNumber: settings.phoneNumber.trim(),
        ownerWhatsappNumber: settings.ownerWhatsappNumber.trim(),
        ownerPinHash: settings.ownerPinHash.trim().isEmpty
            ? '123456'
            : settings.ownerPinHash.trim(),
      );

      final nowIso = DateTime.now().toIso8601String();

      await db.transaction((txn) async {
        await txn.insert(
          'store_settings',
          model.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await txn.insert('crdt_mutations', {
          'id': _uuid.v4(),
          'table_name': 'store_settings',
          'record_id': model.id,
          'action': 'UPSERT',
          'payload_json': jsonEncode(model.toMap()),
          'hlc_timestamp': nowIso,
          'is_synced': 0,
        });
      });

      return model;
    } catch (e) {
      throw DatabaseException('Gagal menyimpan pengaturan toko: ${e.toString()}');
    }
  }

  @override
  Future<bool> verifyOwnerPin(String inputPin) async {
    final settings = await getStoreSettings();
    return settings.ownerPinHash.trim() == inputPin.trim();
  }
}
