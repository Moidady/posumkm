import '../entities/category.dart';
import '../entities/product.dart';

abstract class CatalogRepository {
  Future<List<Category>> getCategories();
  Future<List<Product>> getProducts({String? categoryId, String? searchQuery});
}
