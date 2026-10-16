import 'package:pos_umkm/core/database/app_database.dart';
import 'package:pos_umkm/core/errors/exceptions.dart';
import 'package:pos_umkm/features/pos/data/models/category_model.dart';
import 'package:pos_umkm/features/pos/data/models/product_modifier_model.dart';
import 'package:pos_umkm/features/pos/data/models/product_model.dart';
import 'package:pos_umkm/features/pos/domain/entities/category.dart';
import 'package:pos_umkm/features/pos/domain/entities/product.dart';
import 'package:pos_umkm/features/pos/domain/entities/product_modifier.dart';

abstract class CatalogLocalDataSource {
  Future<List<Category>> getCategories();
  Future<List<Product>> getProducts({String? categoryId, String? searchQuery});
}

class CatalogLocalDataSourceImpl implements CatalogLocalDataSource {
  final AppDatabase appDatabase;

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
  Future<List<Product>> getProducts({String? categoryId, String? searchQuery}) async {
    try {
      final db = await appDatabase.database;

      String whereClause = 'is_deleted = 0 AND is_available = 1';
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
        orderBy: 'name ASC',
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
}
