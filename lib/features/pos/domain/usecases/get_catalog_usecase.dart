import '../entities/category.dart';
import '../entities/product.dart';
import '../repositories/catalog_repository.dart';

class GetCatalogUseCase {
  final CatalogRepository repository;

  GetCatalogUseCase(this.repository);

  Future<List<Category>> getCategories() => repository.getCategories();

  Future<List<Product>> getProducts({String? categoryId, String? searchQuery}) =>
      repository.getProducts(categoryId: categoryId, searchQuery: searchQuery);
}
