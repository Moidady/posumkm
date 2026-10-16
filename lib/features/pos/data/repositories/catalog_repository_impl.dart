import 'package:pos_umkm/features/pos/data/datasources/local/catalog_local_datasource.dart';
import 'package:pos_umkm/features/pos/domain/entities/category.dart';
import 'package:pos_umkm/features/pos/domain/entities/product.dart';
import 'package:pos_umkm/features/pos/domain/repositories/catalog_repository.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogLocalDataSource localDataSource;

  CatalogRepositoryImpl({CatalogLocalDataSource? dataSource})
      : localDataSource = dataSource ?? CatalogLocalDataSourceImpl();

  @override
  Future<List<Category>> getCategories() => localDataSource.getCategories();

  @override
  Future<List<Product>> getProducts({String? categoryId, String? searchQuery}) =>
      localDataSource.getProducts(categoryId: categoryId, searchQuery: searchQuery);
}
