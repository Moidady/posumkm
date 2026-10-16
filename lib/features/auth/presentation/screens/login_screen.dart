import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_umkm/core/theme/app_colors.dart';
import 'package:pos_umkm/features/auth/domain/entities/app_user.dart';
import 'package:pos_umkm/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:pos_umkm/features/settings/presentation/bloc/settings_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController =
      TextEditingController(text: 'kasir1');
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _deviceController =
      TextEditingController(text: 'HP-KASIR-1');
  bool _obscurePin = true;

  static const List<String> _presetDevices = [
    'HP-KASIR-1',
    'HP-KASIR-2',
    'TABLET-KASIR-3',
    'HP-OWNER',
  ];

  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().loadUsers();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _pinController.dispose();
    _deviceController.dispose();
    super.dispose();
  }

  void _selectQuickUser(AppUser user) {
    setState(() {
      _usernameController.text = user.username;
      _deviceController.text = user.assignedDevice;
      _pinController.clear();
    });
  }

  Future<void> _submitLogin() async {
    final username = _usernameController.text.trim();
    final pin = _pinController.text.trim();
    final device = _deviceController.text.trim();

    if (username.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan Username dan PIN/Password kasir terlebih dahulu.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await context.read<AuthCubit>().login(
          username: username,
          pinCode: pin,
          deviceName: device.isEmpty ? 'HP-KASIR-1' : device,
        );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state.settings;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Brand & Info Multi-HP
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.point_of_sale_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      settings.storeName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Sistem Kasir Multi-HP & Multi-Tablet',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 28),

                          // Pilih Akun Kasir Cepat
                          const Text(
                            '1. Pilih Akun Kasir / HP Anda:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (authState.availableUsers.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: authState.availableUsers
                                  .where((u) => u.isActive)
                                  .map((user) {
                                final isSelected = _usernameController.text
                                        .trim()
                                        .toLowerCase() ==
                                    user.username.toLowerCase();
                                return InkWell(
                                  onTap: () => _selectQuickUser(user),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withAlpha(25)
                                          : AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.cardBorder,
                                        width: isSelected ? 1.8 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          user.isOwner
                                              ? Icons.admin_panel_settings
                                              : Icons.phone_android_rounded,
                                          size: 18,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              user.fullName,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? AppColors.primaryDark
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              '@${user.username} • ${user.assignedDevice}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 18),

                          // Pilih Identitas Perangkat / Terminal HP
                          const Text(
                            '2. Kode Perangkat / HP yang Digunakan:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _presetDevices.map((dev) {
                              final selected =
                                  _deviceController.text.trim().toUpperCase() ==
                                      dev;
                              return ChoiceChip(
                                label: Text(dev,
                                    style: const TextStyle(fontSize: 11)),
                                selected: selected,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  setState(() {
                                    _deviceController.text = dev;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _deviceController,
                            decoration: const InputDecoration(
                              labelText: 'Nama / Kode HP Kasir Ini',
                              hintText: 'Contoh: HP-KASIR-1 atau TABLET-DEPAN',
                              prefixIcon: Icon(Icons.devices_rounded),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Input Username & PIN
                          const Text(
                            '3. Masukkan Kredensial Login Kasir:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _usernameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Username',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  onSubmitted: (_) => _submitLogin(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _pinController,
                                  obscureText: _obscurePin,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'PIN / Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePin
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePin = !_obscurePin;
                                        });
                                      },
                                    ),
                                  ),
                                  onSubmitted: (_) => _submitLogin(),
                                ),
                              ),
                            ],
                          ),

                          if (authState.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.error.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.error),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: AppColors.error, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      authState.errorMessage!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 18),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed:
                                  authState.isLoading ? null : _submitLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.login_rounded),
                              label: Text(
                                authState.isLoading
                                    ? 'Memverifikasi...'
                                    : 'Masuk ke Kasir POS',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Info Box Default Akun Multi-HP
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.info.withAlpha(18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.info.withAlpha(80),
                              ),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        size: 16, color: AppColors.info),
                                    SizedBox(width: 6),
                                    Text(
                                      'Info Login Bawaan (Bisa Diubah oleh Owner):',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.info,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '• HP Kasir 1 : username "kasir1" | PIN: 111111\n'
                                  '• HP Kasir 2 : username "kasir2" | PIN: 222222\n'
                                  '• Tablet / 3 : username "kasir3" | PIN: 333333\n'
                                  '• HP Owner   : username "owner"  | PIN: 123456',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
