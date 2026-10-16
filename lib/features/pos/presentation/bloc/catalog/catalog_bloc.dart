import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_umkm/features/pos/domain/usecases/get_catalog_usecase.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/catalog/catalog_event.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/catalog/catalog_state.dart';

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final GetCatalogUseCase getCatalogUseCase;

  CatalogBloc({required this.getCatalogUseCase}) : super(const CatalogInitial()) {
    on<LoadCatalogEvent>(_onLoadCatalog);
    on<SelectCategoryEvent>(_onSelectCategory);
    on<SearchProductEvent>(_onSearchProduct);
  }

  Future<void> _onLoadCatalog(
    LoadCatalogEvent event,
    Emitter<CatalogState> emit,
  ) async {
    emit(const CatalogLoading());
    try {
      final categories = await getCatalogUseCase.getCategories();
      final products = await getCatalogUseCase.getProducts();
      emit(CatalogLoaded(
        categories: categories,
        products: products,
        selectedCategoryId: 'all',
      ));
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> _onSelectCategory(
    SelectCategoryEvent event,
    Emitter<CatalogState> emit,
  ) async {
    final currentState = state;
    if (currentState is CatalogLoaded) {
      emit(const CatalogLoading());
      try {
        final products = await getCatalogUseCase.getProducts(
          categoryId: event.categoryId == 'all' ? null : event.categoryId,
          searchQuery: currentState.searchQuery.isEmpty ? null : currentState.searchQuery,
        );
        emit(currentState.copyWith(
          selectedCategoryId: event.categoryId,
          products: products,
        ));
      } catch (e) {
        emit(CatalogError(e.toString()));
      }
    }
  }

  Future<void> _onSearchProduct(
    SearchProductEvent event,
    Emitter<CatalogState> emit,
  ) async {
    final currentState = state;
    if (currentState is CatalogLoaded) {
      try {
        final products = await getCatalogUseCase.getProducts(
          categoryId: currentState.selectedCategoryId == 'all'
              ? null
              : currentState.selectedCategoryId,
          searchQuery: event.query.isEmpty ? null : event.query,
        );
        emit(currentState.copyWith(
          searchQuery: event.query,
          products: products,
        ));
      } catch (e) {
        emit(CatalogError(e.toString()));
      }
    }
  }
}
