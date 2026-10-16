import 'package:pos_umkm/features/settings/domain/entities/store_settings.dart';
import 'package:pos_umkm/features/settings/domain/repositories/settings_repository.dart';

class ManageStoreSettingsUseCase {
  final SettingsRepository repository;

  ManageStoreSettingsUseCase(this.repository);

  Future<StoreSettings> getSettings() {
    return repository.getStoreSettings();
  }

  Future<StoreSettings> updateSettings(StoreSettings settings) {
    return repository.updateStoreSettings(settings);
  }

  Future<bool> verifyOwnerPin(String inputPin) {
    return repository.verifyOwnerPin(inputPin);
  }
}
