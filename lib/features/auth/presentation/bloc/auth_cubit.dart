import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_umkm/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:pos_umkm/features/auth/domain/entities/app_user.dart';

class AuthState extends Equatable {
  final AppUser? currentUser;
  final String activeDeviceName;
  final List<AppUser> availableUsers;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.currentUser,
    this.activeDeviceName = 'HP-KASIR-1',
    this.availableUsers = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => currentUser != null;

  AuthState copyWith({
    AppUser? currentUser,
    bool clearCurrentUser = false,
    String? activeDeviceName,
    List<AppUser>? availableUsers,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      currentUser: clearCurrentUser ? null : (currentUser ?? this.currentUser),
      activeDeviceName: activeDeviceName ?? this.activeDeviceName,
      availableUsers: availableUsers ?? this.availableUsers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        currentUser,
        activeDeviceName,
        availableUsers,
        isLoading,
        errorMessage,
      ];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthLocalDataSource dataSource;

  AuthCubit({AuthLocalDataSource? authDataSource})
      : dataSource = authDataSource ?? AuthLocalDataSource(),
        super(const AuthState());

  Future<void> loadUsers() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final users = await dataSource.getAllUsers();
      emit(state.copyWith(
        availableUsers: users,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<bool> login({
    required String username,
    required String pinCode,
    required String deviceName,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = await dataSource.authenticate(
        username: username,
        pinCode: pinCode,
        deviceName: deviceName,
      );
      final users = await dataSource.getAllUsers();
      emit(state.copyWith(
        currentUser: user,
        activeDeviceName: user.assignedDevice,
        availableUsers: users,
        isLoading: false,
        clearError: true,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('DatabaseException: ', ''),
      ));
      return false;
    }
  }

  void logout() {
    emit(state.copyWith(
      clearCurrentUser: true,
      clearError: true,
    ));
  }

  Future<void> saveCashierAccount({
    String? id,
    required String username,
    required String fullName,
    required String pinCode,
    required String role,
    required String assignedDevice,
    bool isActive = true,
  }) async {
    final saved = await dataSource.saveUser(
      id: id,
      username: username,
      fullName: fullName,
      pinCode: pinCode,
      role: role,
      assignedDevice: assignedDevice,
      isActive: isActive,
    );
    final users = await dataSource.getAllUsers();
    final updatedCurrent = state.currentUser?.id == saved.id ? saved : state.currentUser;
    emit(state.copyWith(
      availableUsers: users,
      currentUser: updatedCurrent,
      clearError: true,
    ));
  }

  Future<void> deleteCashierAccount(String userId) async {
    await dataSource.deleteUser(userId);
    final users = await dataSource.getAllUsers();
    emit(state.copyWith(availableUsers: users));
  }
}
