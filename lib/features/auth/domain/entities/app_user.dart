import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String id;
  final String username;
  final String fullName;
  final String pinCode;
  final String role; // 'OWNER' atau 'CASHIER'
  final String assignedDevice; // contoh: 'HP-KASIR-1', 'HP-KASIR-2'
  final bool isActive;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.pinCode,
    required this.role,
    required this.assignedDevice,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isOwner => role.toUpperCase() == 'OWNER';

  AppUser copyWith({
    String? id,
    String? username,
    String? fullName,
    String? pinCode,
    String? role,
    String? assignedDevice,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      pinCode: pinCode ?? this.pinCode,
      role: role ?? this.role,
      assignedDevice: assignedDevice ?? this.assignedDevice,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        fullName,
        pinCode,
        role,
        assignedDevice,
        isActive,
        createdAt,
      ];
}
