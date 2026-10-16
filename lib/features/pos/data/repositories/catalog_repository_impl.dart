import 'package:pos_umkm/features/pos/data/datasources/local/catalog_local_datasource.dart';
import 'package:pos_umkm/features/pos/domain/entities/category.dart';
import 'package:pos_umkm/features/pos/domain/entities/product.dart';
import 'package:pos_umkm/features/pos/domain/repositories/catalog_repository.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogLocalDataSource localDataSource;

  CatalogRepositoryImpl({CatalogLocalDataSource? localDataSource})
      : localDataSource = localDataSource ?? CatalogLocalDataSourceImpl();

  @override
  Future<List<Category>> getCategories() {
    return localDataSource.getCategories();
  }

  @override
  Future<List<Product>> getProducts({
    String? categoryId,
    String? searchQuery,
    bool includeUnavailable = false,
  }) {
    return localDataSource.getProducts(
      categoryId: categoryId,
      searchQuery: searchQuery,
      includeUnavailable: includeUnavailable,
    );
  }

  @override
  Future<void> saveProduct(Product product) {
    return localDataSource.saveProduct(product);
  }

  @override
  Future<void> toggleProductAvailability(String productId, bool isAvailable) {
    return localDataSource.toggleProductAvailability(productId, isAvailable);
  }

  @override
  Future<void> deleteProduct(String productId) {
    return localDataSource.deleteProduct(productId);
  }

  @override
  Future<Category> addCategory({required String name, String icon = 'fastfood'}) {
    return localDataSource.addCategory(name: name, icon: icon);
  }
}
