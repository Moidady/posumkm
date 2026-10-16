import 'package:equatable/equatable.dart';
import 'package:pos_umkm/features/pos/domain/entities/category.dart';
import 'package:pos_umkm/features/pos/domain/entities/product.dart';

abstract class CatalogState extends Equatable {
  const CatalogState();

  @override
  List<Object?> get props => [];
}

class CatalogInitial extends CatalogState {
  const CatalogInitial();
}

class CatalogLoading extends CatalogState {
  const CatalogLoading();
}

class CatalogLoaded extends CatalogState {
  final List<Category> categories;
  final List<Product> products;
  final String selectedCategoryId; // 'all' untuk semua produk
  final String searchQuery;

  const CatalogLoaded({
    required this.categories,
    required this.products,
    this.selectedCategoryId = 'all',
    this.searchQuery = '',
  });

  CatalogLoaded copyWith({
    List<Category>? categories,
    List<Product>? products,
    String? selectedCategoryId,
    String? searchQuery,
  }) {
    return CatalogLoaded(
      categories: categories ?? this.categories,
      products: products ?? this.products,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [categories, products, selectedCategoryId, searchQuery];
}

class CatalogError extends CatalogState {
  final String message;
  const CatalogError(this.message);

  @override
  List<Object?> get props => [message];
}
