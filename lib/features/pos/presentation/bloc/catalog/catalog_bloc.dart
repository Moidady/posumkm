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
    on<SaveProductEvent>(_onSaveProduct);
    on<ToggleProductAvailabilityEvent>(_onToggleAvailability);
    on<DeleteProductEvent>(_onDeleteProduct);
    on<AddCategoryEvent>(_onAddCategory);
  }

  Future<void> _onLoadCatalog(
    LoadCatalogEvent event,
    Emitter<CatalogState> emit,
  ) async {
    emit(const CatalogLoading());
    try {
      final categories = await getCatalogUseCase.getCategories();
      final products = await getCatalogUseCase.getProducts();
      final allProducts = await getCatalogUseCase.getProducts(includeUnavailable: true);
      emit(CatalogLoaded(
        categories: categories,
        products: products,
        allProducts: allProducts,
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

  Future<void> _onSaveProduct(
    SaveProductEvent event,
    Emitter<CatalogState> emit,
  ) async {
    try {
      await getCatalogUseCase.saveProduct(event.product);
      await _reloadCurrentCatalog(emit);
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> _onToggleAvailability(
    ToggleProductAvailabilityEvent event,
    Emitter<CatalogState> emit,
  ) async {
    try {
      await getCatalogUseCase.toggleProductAvailability(
        event.productId,
        event.isAvailable,
      );
      await _reloadCurrentCatalog(emit);
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProductEvent event,
    Emitter<CatalogState> emit,
  ) async {
    try {
      await getCatalogUseCase.deleteProduct(event.productId);
      await _reloadCurrentCatalog(emit);
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> _onAddCategory(
    AddCategoryEvent event,
    Emitter<CatalogState> emit,
  ) async {
    try {
      await getCatalogUseCase.addCategory(name: event.categoryName);
      await _reloadCurrentCatalog(emit);
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> _reloadCurrentCatalog(Emitter<CatalogState> emit) async {
    final currentState = state;
    final selectedCat = currentState is CatalogLoaded ? currentState.selectedCategoryId : 'all';
    final query = currentState is CatalogLoaded ? currentState.searchQuery : '';

    final categories = await getCatalogUseCase.getCategories();
    final products = await getCatalogUseCase.getProducts(
      categoryId: selectedCat == 'all' ? null : selectedCat,
      searchQuery: query.isEmpty ? null : query,
    );
    final allProducts = await getCatalogUseCase.getProducts(includeUnavailable: true);

    emit(CatalogLoaded(
      categories: categories,
      products: products,
      allProducts: allProducts,
      selectedCategoryId: selectedCat,
      searchQuery: query,
    ));
  }
}
