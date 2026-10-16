import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/checkout/data/repositories/order_repository_impl.dart';
import 'features/checkout/domain/usecases/process_checkout_usecase.dart';
import 'features/checkout/presentation/bloc/checkout_bloc.dart';
import 'features/pos/data/repositories/catalog_repository_impl.dart';
import 'features/pos/domain/usecases/get_catalog_usecase.dart';
import 'features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'features/pos/presentation/bloc/catalog/catalog_bloc.dart';
import 'features/pos/presentation/screens/pos_screen.dart';

class PosUmkmApp extends StatelessWidget {
  const PosUmkmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final catalogRepository = CatalogRepositoryImpl();
    final orderRepository = OrderRepositoryImpl();

    return MultiBlocProvider(
      providers: [
        BlocProvider<CatalogBloc>(
          create: (_) => CatalogBloc(
            getCatalogUseCase: GetCatalogUseCase(catalogRepository),
          ),
        ),
        BlocProvider<CartBloc>(
          create: (_) => CartBloc(),
        ),
        BlocProvider<CheckoutBloc>(
          create: (_) => CheckoutBloc(
            processCheckoutUseCase: ProcessCheckoutUseCase(orderRepository),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'POS UMKM',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const PosScreen(),
      ),
    );
  }
}
