import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_umkm/features/settings/domain/entities/store_settings.dart';
import 'package:pos_umkm/features/settings/domain/usecases/manage_store_settings_usecase.dart';

abstract class SettingsState extends Equatable {
  final StoreSettings settings;

  const SettingsState({required this.settings});

  @override
  List<Object?> get props => [settings];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial()
      : super(
          settings: const StoreSettings(
            id: 'default-store',
            storeName: 'Kedai Pos UMKM',
            address: 'Jl. Kuliner No. 12, Foodcourt Stand B-04',
            phoneNumber: '0812-3456-7890',
            ownerWhatsappNumber: '081234567890',
            ownerPinHash: '123456',
          ),
        );
}

class SettingsLoaded extends SettingsState {
  final String? successMessage;
  final String? errorMessage;

  const SettingsLoaded({
    required super.settings,
    this.successMessage,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [settings, successMessage, errorMessage];
}

class SettingsCubit extends Cubit<SettingsState> {
  final ManageStoreSettingsUseCase manageStoreSettingsUseCase;

  SettingsCubit({required this.manageStoreSettingsUseCase})
      : super(const SettingsInitial());

  Future<void> loadSettings() async {
    try {
      final loaded = await manageStoreSettingsUseCase.getSettings();
      emit(SettingsLoaded(settings: loaded));
    } catch (e) {
      emit(SettingsLoaded(
        settings: state.settings,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<bool> saveSettings(StoreSettings updated) async {
    if (updated.storeName.trim().isEmpty) {
      emit(SettingsLoaded(
        settings: state.settings,
        errorMessage: 'Nama toko tidak boleh kosong.',
      ));
      return false;
    }

    if (updated.ownerWhatsappNumber.trim().isEmpty) {
      emit(SettingsLoaded(
        settings: state.settings,
        errorMessage: 'Nomor WhatsApp Owner belum diatur di menu Pengaturan Toko.',
      ));
      return false;
    }

    try {
      final saved = await manageStoreSettingsUseCase.updateSettings(updated);
      emit(SettingsLoaded(
        settings: saved,
        successMessage: 'Pengaturan toko berhasil disimpan!',
      ));
      return true;
    } catch (e) {
      emit(SettingsLoaded(
        settings: state.settings,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  Future<bool> verifyPin(String inputPin) {
    return manageStoreSettingsUseCase.verifyOwnerPin(inputPin);
  }
}
