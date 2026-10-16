import 'package:equatable/equatable.dart';

class StoreSettings extends Equatable {
  final String id;
  final String storeName;
  final String address;
  final String phoneNumber;
  final String ownerWhatsappNumber;
  final String ownerPinHash;

  const StoreSettings({
    required this.id,
    required this.storeName,
    required this.address,
    required this.phoneNumber,
    required this.ownerWhatsappNumber,
    required this.ownerPinHash,
  });

  StoreSettings copyWith({
    String? id,
    String? storeName,
    String? address,
    String? phoneNumber,
    String? ownerWhatsappNumber,
    String? ownerPinHash,
  }) {
    return StoreSettings(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      ownerWhatsappNumber: ownerWhatsappNumber ?? this.ownerWhatsappNumber,
      ownerPinHash: ownerPinHash ?? this.ownerPinHash,
    );
  }

  @override
  List<Object?> get props => [
        id,
        storeName,
        address,
        phoneNumber,
        ownerWhatsappNumber,
        ownerPinHash,
      ];
}
