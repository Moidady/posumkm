import 'package:equatable/equatable.dart';
import 'package:pos_umkm/features/pos/domain/entities/product.dart';

abstract class CatalogEvent extends Equatable {
  const CatalogEvent();

  @override
  List<Object?> get props => [];
}

class LoadCatalogEvent extends CatalogEvent {
  const LoadCatalogEvent();
}

class SelectCategoryEvent extends CatalogEvent {
  final String categoryId;
  const SelectCategoryEvent(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class SearchProductEvent extends CatalogEvent {
  final String query;
  const SearchProductEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class SaveProductEvent extends CatalogEvent {
  final Product product;
  const SaveProductEvent(this.product);

  @override
  List<Object?> get props => [product];
}

class ToggleProductAvailabilityEvent extends CatalogEvent {
  final String productId;
  final bool isAvailable;

  const ToggleProductAvailabilityEvent({
    required this.productId,
    required this.isAvailable,
  });

  @override
  List<Object?> get props => [productId, isAvailable];
}

class DeleteProductEvent extends CatalogEvent {
  final String productId;
  const DeleteProductEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

class AddCategoryEvent extends CatalogEvent {
  final String categoryName;
  const AddCategoryEvent(this.categoryName);

  @override
  List<Object?> get props => [categoryName];
}
