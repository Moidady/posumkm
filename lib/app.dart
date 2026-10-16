import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_umkm/core/theme/app_theme.dart';
import 'package:pos_umkm/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:pos_umkm/features/auth/presentation/screens/login_screen.dart';
import 'package:pos_umkm/features/checkout/data/repositories/order_repository_impl.dart';
import 'package:pos_umkm/features/checkout/domain/usecases/process_checkout_usecase.dart';
import 'package:pos_umkm/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:pos_umkm/features/pos/data/repositories/catalog_repository_impl.dart';
import 'package:pos_umkm/features/pos/domain/usecases/get_catalog_usecase.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/catalog/catalog_bloc.dart';
import 'package:pos_umkm/features/pos/presentation/screens/pos_screen.dart';
import 'package:pos_umkm/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:pos_umkm/features/settings/domain/usecases/manage_store_settings_usecase.dart';
import 'package:pos_umkm/features/settings/presentation/bloc/settings_cubit.dart';

class PosUmkmApp extends StatelessWidget {
  const PosUmkmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final catalogRepository = CatalogRepositoryImpl();
    final orderRepository = OrderRepositoryImpl();
    final settingsRepository = SettingsRepositoryImpl();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit()..loadUsers(),
        ),
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
        BlocProvider<SettingsCubit>(
          create: (_) => SettingsCubit(
            manageStoreSettingsUseCase:
                ManageStoreSettingsUseCase(settingsRepository),
          )..loadSettings(),
        ),
      ],
      child: MaterialApp(
        title: 'POS UMKM',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            if (!authState.isAuthenticated) {
              return const LoginScreen();
            }
            return const PosScreen();
          },
        ),
      ),
    );
  }
}
