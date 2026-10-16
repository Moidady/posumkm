import 'package:pos_umkm/features/settings/data/datasources/local/settings_local_datasource.dart';
import 'package:pos_umkm/features/settings/domain/entities/store_settings.dart';
import 'package:pos_umkm/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl({SettingsLocalDataSource? localDataSource})
      : localDataSource = localDataSource ?? SettingsLocalDataSourceImpl();

  @override
  Future<StoreSettings> getStoreSettings() {
    return localDataSource.getStoreSettings();
  }

  @override
  Future<StoreSettings> updateStoreSettings(StoreSettings settings) {
    return localDataSource.updateStoreSettings(settings);
  }

  @override
  Future<bool> verifyOwnerPin(String inputPin) {
    return localDataSource.verifyOwnerPin(inputPin);
  }
}
