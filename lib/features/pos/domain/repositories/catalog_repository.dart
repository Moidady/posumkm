import 'package:pos_umkm/features/pos/domain/entities/category.dart';
import 'package:pos_umkm/features/pos/domain/entities/product.dart';

abstract class CatalogRepository {
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
