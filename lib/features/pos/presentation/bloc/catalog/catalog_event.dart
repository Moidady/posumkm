import 'package:equatable/equatable.dart';

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
