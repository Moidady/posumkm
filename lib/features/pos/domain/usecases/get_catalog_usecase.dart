import 'package:pos_umkm/features/pos/domain/entities/category.dart';
import 'package:pos_umkm/features/pos/domain/entities/product.dart';
import 'package:pos_umkm/features/pos/domain/repositories/catalog_repository.dart';

class GetCatalogUseCase {
  final CatalogRepository repository;

  GetCatalogUseCase(this.repository);

  Future<List<Category>> getCategories() => repository.getCategories();

  Future<List<Product>> getProducts({
    String? categoryId,
    String? searchQuery,
    bool includeUnavailable = false,
  }) =>
      repository.getProducts(
        categoryId: categoryId,
        searchQuery: searchQuery,
        includeUnavailable: includeUnavailable,
      );

  Future<void> saveProduct(Product product) => repository.saveProduct(product);

  Future<void> toggleProductAvailability(String productId, bool isAvailable) =>
      repository.toggleProductAvailability(productId, isAvailable);

  Future<void> deleteProduct(String productId) =>
      repository.deleteProduct(productId);

  Future<Category> addCategory({required String name, String icon = 'fastfood'}) =>
      repository.addCategory(name: name, icon: icon);
}
