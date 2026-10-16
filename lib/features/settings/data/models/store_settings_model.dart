import 'package:pos_umkm/features/settings/domain/entities/store_settings.dart';

class StoreSettingsModel extends StoreSettings {
  const StoreSettingsModel({
    required super.id,
    required super.storeName,
    required super.address,
    required super.phoneNumber,
    required super.ownerWhatsappNumber,
    required super.ownerPinHash,
  });

  factory StoreSettingsModel.fromMap(Map<String, dynamic> map) {
    return StoreSettingsModel(
      id: map['id'] as String? ?? 'default-store',
      storeName: map['store_name'] as String? ?? 'Kedai Pos UMKM',
      address: map['address'] as String? ?? 'Jl. Kuliner No. 12',
      phoneNumber: map['phone_number'] as String? ?? '0812-3456-7890',
      ownerWhatsappNumber: map['owner_whatsapp_number'] as String? ?? '081234567890',
      ownerPinHash: map['owner_pin_hash'] as String? ?? '123456',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_name': storeName,
      'address': address,
      'phone_number': phoneNumber,
      'owner_whatsapp_number': ownerWhatsappNumber,
      'owner_pin_hash': ownerPinHash,
    };
  }
}
