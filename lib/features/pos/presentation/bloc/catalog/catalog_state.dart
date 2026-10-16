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
  final List<Product> allProducts; // Termasuk menu yang sedang habis untuk layar Kelola Menu
  final String selectedCategoryId; // 'all' untuk semua produk
  final String searchQuery;

  const CatalogLoaded({
    required this.categories,
    required this.products,
    this.allProducts = const [],
    this.selectedCategoryId = 'all',
    this.searchQuery = '',
  });

  CatalogLoaded copyWith({
    List<Category>? categories,
    List<Product>? products,
    List<Product>? allProducts,
    String? selectedCategoryId,
    String? searchQuery,
  }) {
    return CatalogLoaded(
      categories: categories ?? this.categories,
      products: products ?? this.products,
      allProducts: allProducts ?? this.allProducts,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        categories,
        products,
        allProducts,
        selectedCategoryId,
        searchQuery,
      ];
}

class CatalogError extends CatalogState {
  final String message;
  const CatalogError(this.message);

  @override
  List<Object?> get props => [message];
}
