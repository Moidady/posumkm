import 'dart:convert';
import 'package:pos_umkm/core/database/app_database.dart';
import 'package:pos_umkm/core/errors/exceptions.dart';
import 'package:pos_umkm/features/pos/data/models/category_model.dart';
import 'package:pos_umkm/features/pos/data/models/product_modifier_model.dart';
import 'package:pos_umkm/features/pos/data/models/product_model.dart';
import 'package:pos_umkm/features/pos/domain/entities/category.dart';
import 'package:pos_umkm/features/pos/domain/entities/product.dart';
import 'package:pos_umkm/features/pos/domain/entities/product_modifier.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:uuid/uuid.dart';

abstract class CatalogLocalDataSource {
  Future<List<Category>> getCategories();
  Future<List<Product>> getProducts({
    String? categoryId,
    String? searchQuery,
    bool includeUnavailable = false,
  });
  Future<void> saveProduct(Product product);
  Future<void> toggleProductAvailability(String productId, bool isAvailable);
  Future<void> deleteProduct(String productId);
  Future<Category> addCategory({required String name, String icon = 'fastfood'});
}

class CatalogLocalDataSourceImpl implements CatalogLocalDataSource {
  final AppDatabase appDatabase;
  static const _uuid = Uuid();

  CatalogLocalDataSourceImpl({AppDatabase? database})
      : appDatabase = database ?? AppDatabase.instance;

  @override
  Future<List<Category>> getCategories() async {
    try {
      final db = await appDatabase.database;
      final result = await db.query(
        'categories',
        where: 'is_deleted = 0',
        orderBy: 'sort_order ASC',
      );
      return result.map((map) => CategoryModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Gagal memuat kategori: ${e.toString()}');
    }
  }

  @override
  Future<List<Product>> getProducts({
    String? categoryId,
    String? searchQuery,
    bool includeUnavailable = false,
  }) async {
    try {
      final db = await appDatabase.database;

      String whereClause = includeUnavailable
          ? 'is_deleted = 0'
          : 'is_deleted = 0 AND is_available = 1';
      List<dynamic> whereArgs = [];

      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        whereClause += ' AND category_id = ?';
        whereArgs.add(categoryId);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        whereClause += ' AND (name LIKE ? OR sku LIKE ?)';
        final pattern = '%${searchQuery.trim()}%';
        whereArgs.add(pattern);
        whereArgs.add(pattern);
      }

      final productMaps = await db.query(
        'products',
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'id ASC',
      );

      final List<Product> products = [];

      for (final prodMap in productMaps) {
        final prodId = prodMap['id'] as String;

        // Ambil modifiers untuk produk ini
        final modifierMaps = await db.query(
          'product_modifiers',
          where: 'product_id = ?',
          whereArgs: [prodId],
        );

        final List<ProductModifier> modifiers = modifierMaps
            .map((m) => ProductModifierModel.fromMap(m))
            .toList();

        final model = ProductModel.fromMap(
          prodMap,
          modifiers: modifiers.cast<ProductModifierModel>(),
        );
        products.add(model);
      }

      return products;
    } catch (e) {
      throw DatabaseException('Gagal memuat katalog produk: ${e.toString()}');
    }
  }

  @override
  Future<void> saveProduct(Product product) async {
    try {
      final db = await appDatabase.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final nowIso = DateTime.now().toIso8601String();
      final productId = product.id.trim().isEmpty ? _uuid.v4() : product.id;

      final prodData = {
        'id': productId,
        'category_id': product.categoryId,
        'name': product.name.trim(),
        'base_price': product.basePrice,
        'sku': product.sku.trim().isEmpty
            ? 'SKU-${productId.substring(0, 6).toUpperCase()}'
            : product.sku.trim().toUpperCase(),
        'image_url': product.imageUrl,
        'is_available': product.isAvailable ? 1 : 0,
        'updated_at': nowMs,
        'is_deleted': 0,
      };

      await db.transaction((txn) async {
        // 1. Upsert produk
        await txn.insert(
          'products',
          prodData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // 2. Sinkronisasi modifiers produk
        await txn.delete(
          'product_modifiers',
          where: 'product_id = ?',
          whereArgs: [productId],
        );

        for (final mod in product.modifiers) {
          final modId = mod.id.trim().isEmpty ? _uuid.v4() : mod.id;
          await txn.insert('product_modifiers', {
            'id': modId,
            'product_id': productId,
            'name': mod.name.trim(),
            'extra_price': mod.extraPrice,
            'group_name': mod.groupName.trim().isEmpty ? 'Topping Ekstra' : mod.groupName.trim(),
            'updated_at': nowMs,
          });
        }

        // 3. Catat ke antrean CRDT
        await txn.insert('crdt_mutations', {
          'id': _uuid.v4(),
          'table_name': 'products',
          'record_id': productId,
          'action': 'UPSERT',
          'payload_json': jsonEncode(prodData),
          'hlc_timestamp': nowIso,
          'is_synced': 0,
        });
      });
    } catch (e) {
      throw DatabaseException('Gagal menyimpan menu produk: ${e.toString()}');
    }
  }

  @override
  Future<void> toggleProductAvailability(String productId, bool isAvailable) async {
    try {
      final db = await appDatabase.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final nowIso = DateTime.now().toIso8601String();

      await db.transaction((txn) async {
        await txn.update(
          'products',
          {
            'is_available': isAvailable ? 1 : 0,
            'updated_at': nowMs,
          },
          where: 'id = ?',
          whereArgs: [productId],
        );

        await txn.insert('crdt_mutations', {
          'id': _uuid.v4(),
          'table_name': 'products',
          'record_id': productId,
          'action': 'UPDATE_AVAILABILITY',
          'payload_json': jsonEncode({'id': productId, 'is_available': isAvailable ? 1 : 0}),
          'hlc_timestamp': nowIso,
          'is_synced': 0,
        });
      });
    } catch (e) {
      throw DatabaseException('Gagal mengubah status ketersediaan menu: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      final db = await appDatabase.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final nowIso = DateTime.now().toIso8601String();

      await db.transaction((txn) async {
        await txn.update(
          'products',
          {
            'is_deleted': 1,
            'updated_at': nowMs,
          },
          where: 'id = ?',
          whereArgs: [productId],
        );

        await txn.insert('crdt_mutations', {
          'id': _uuid.v4(),
          'table_name': 'products',
          'record_id': productId,
          'action': 'SOFT_DELETE',
          'payload_json': jsonEncode({'id': productId, 'is_deleted': 1}),
          'hlc_timestamp': nowIso,
          'is_synced': 0,
        });
      });
    } catch (e) {
      throw DatabaseException('Gagal menghapus menu produk: ${e.toString()}');
    }
  }

  @override
  Future<Category> addCategory({required String name, String icon = 'fastfood'}) async {
    try {
      final db = await appDatabase.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final nowIso = DateTime.now().toIso8601String();
      final categoryId = _uuid.v4();

      final existing = await getCategories();
      final nextOrder = existing.length + 1;

      final catMap = {
        'id': categoryId,
        'name': name.trim(),
        'icon': icon,
        'sort_order': nextOrder,
        'updated_at': nowMs,
        'is_deleted': 0,
      };

      await db.transaction((txn) async {
        await txn.insert('categories', catMap);
        await txn.insert('crdt_mutations', {
          'id': _uuid.v4(),
          'table_name': 'categories',
          'record_id': categoryId,
          'action': 'INSERT',
          'payload_json': jsonEncode(catMap),
          'hlc_timestamp': nowIso,
          'is_synced': 0,
        });
      });

      return CategoryModel.fromMap(catMap);
    } catch (e) {
      throw DatabaseException('Gagal menambahkan kategori baru: ${e.toString()}');
    }
  }
}
