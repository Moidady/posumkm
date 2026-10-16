import 'package:pos_umkm/core/database/app_database.dart';
import 'package:pos_umkm/core/errors/exceptions.dart';
import 'package:pos_umkm/features/auth/domain/entities/app_user.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:uuid/uuid.dart';

class AuthLocalDataSource {
  final AppDatabase appDatabase;
  static const _uuid = Uuid();

  AuthLocalDataSource({AppDatabase? database})
      : appDatabase = database ?? AppDatabase.instance;

  Future<List<AppUser>> getAllUsers() async {
    final db = await appDatabase.database;
    final rows = await db.query(
      'users',
      orderBy: "CASE WHEN role = 'OWNER' THEN 0 ELSE 1 END, username ASC",
    );
    return rows.map(_mapToUser).toList();
  }

  Future<AppUser> authenticate({
    required String username,
    required String pinCode,
    required String deviceName,
  }) async {
    final db = await appDatabase.database;
    final cleanUsername = username.trim().toLowerCase();
    final cleanPin = pinCode.trim();

    final rows = await db.query(
      'users',
      where: 'LOWER(username) = ? AND pin_code = ?',
      whereArgs: [cleanUsername, cleanPin],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw const DatabaseException(
        'Username atau PIN/Password salah. Silakan periksa kembali.',
      );
    }

    final user = _mapToUser(rows.first);
    if (!user.isActive) {
      throw const DatabaseException(
        'Akun kasir ini sedang dinonaktifkan oleh Owner.',
      );
    }

    final targetDevice = deviceName.trim().isEmpty
        ? user.assignedDevice
        : deviceName.trim().toUpperCase();

    return user.copyWith(assignedDevice: targetDevice);
  }

  Future<AppUser> saveUser({
    String? id,
    required String username,
    required String fullName,
    required String pinCode,
    required String role,
    required String assignedDevice,
    bool isActive = true,
  }) async {
    final db = await appDatabase.database;
    final userId = id ?? _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final cleanUsername = username.trim().toLowerCase();

    await db.insert(
      'users',
      {
        'id': userId,
        'username': cleanUsername,
        'full_name': fullName.trim(),
        'pin_code': pinCode.trim(),
        'role': role.toUpperCase(),
        'assigned_device': assignedDevice.trim().toUpperCase(),
        'is_active': isActive ? 1 : 0,
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return AppUser(
      id: userId,
      username: cleanUsername,
      fullName: fullName.trim(),
      pinCode: pinCode.trim(),
      role: role.toUpperCase(),
      assignedDevice: assignedDevice.trim().toUpperCase(),
      isActive: isActive,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
    );
  }

  Future<void> deleteUser(String userId) async {
    final db = await appDatabase.database;
    await db.delete(
      'users',
      where: "id = ? AND role != 'OWNER'",
      whereArgs: [userId],
    );
  }

  AppUser _mapToUser(Map<String, dynamic> row) {
    return AppUser(
      id: row['id'] as String,
      username: row['username'] as String,
      fullName: row['full_name'] as String,
      pinCode: row['pin_code'] as String,
      role: row['role'] as String? ?? 'CASHIER',
      assignedDevice: row['assigned_device'] as String? ?? 'HP-KASIR-1',
      isActive: (row['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
