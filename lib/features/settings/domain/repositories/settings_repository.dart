import 'package:pos_umkm/features/settings/domain/entities/store_settings.dart';

abstract class SettingsRepository {
  Future<StoreSettings> getStoreSettings();
  Future<StoreSettings> updateStoreSettings(StoreSettings settings);
  Future<bool> verifyOwnerPin(String inputPin);
}
