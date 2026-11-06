import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vrs_ui/app/core/utils/auth_service.dart';
import 'package:vrs_ui/app/data/providers/auth_provider.dart';
import 'package:vrs_ui/app/data/providers/user_provider.dart';

class LoginController extends GetxController {
  final AuthProvider authProvider = Get.find<AuthProvider>();
  final UserProvider userProvider = Get.isRegistered<UserProvider>()
      ? Get.find<UserProvider>()
      : Get.put(UserProvider());

  final _box = GetStorage();

  late final TextEditingController usernameController;
  late final TextEditingController passwordController;

  var isPasswordObscured = true.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
  }

  void togglePasswordVisibility() {
    isPasswordObscured.value = !isPasswordObscured.value;
  }

  // --- Reusable Custom Snackbar Helper ---
  void _showCustomSnackbar({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    if (isClosed) return;
    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFFFFFFF),
      titleText: const SizedBox.shrink(),
      messageText: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      borderRadius: 24,
      duration: const Duration(seconds: 3),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Future<void> login() async {
    if (isLoading.value) return;

    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showCustomSnackbar(
        title: 'Error',
        message: 'Please fill in all fields',
        icon: Icons.error_outline_rounded,
        iconColor: const Color(0xFFDC2626),
        iconBgColor: const Color(0xFFFEE2E2),
      );
      return;
    }

    isLoading.value = true;
    try {
      final response = await authProvider.LoginUser({
        'username': username,
        'password': password,
      });

      if (isClosed) return;

      final body = response.body;
      final isSuccess =
          response.statusCode == 200 &&
          (body is! Map ||
              body['statusCode'] == null ||
              body['statusCode'] == 200);
      final Map<String, dynamic>? result =
          (body is Map && body['result'] is Map)
          ? Map<String, dynamic>.from(body['result'])
          : null;

      final String? access = result?['accessToken']?.toString();
      final String? refresh = result?['refreshToken']?.toString();

      if (isSuccess && access != null && access.isNotEmpty) {
        await _box.write('token', access);
        if (refresh != null) {
          await _box.write('refreshToken', refresh);
        }
        await _loadRole(access, username);

        if (isClosed) return;

        _showCustomSnackbar(
          title: 'Success',
          message: 'Welcome back! Successfully logged in.',
          icon: Icons.verified_rounded,
          iconColor: const Color(0xFF0284C7),
          iconBgColor: const Color(0xFFE0F2FE),
        );

        final bool hasPermission = AuthService.can('vehicle.view');
        Get.offAllNamed(hasPermission ? '/admin' : '/home');
      } else {
        final errorMsg =
            (body is Map ? body['message'] : null) ??
            response.statusText ??
            'Login failed';

        _showCustomSnackbar(
          title: 'Login Failed',
          message: errorMsg.toString(),
          icon: Icons.error_outline_rounded,
          iconColor: const Color(0xFFDC2626),
          iconBgColor: const Color(0xFFFEE2E2),
        );
      }
    } catch (e) {
      if (isClosed) return;
      _showCustomSnackbar(
        title: 'Error',
        message: 'Failed to connect: ${e.toString()}',
        icon: Icons.wifi_off_rounded,
        iconColor: const Color(0xFFD97706),
        iconBgColor: const Color(0xFFFEF3C7),
      );
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  Future<void> _loadRole(String token, String username) async {
    await _box.write('role', 'user');
    try {
      final res = await userProvider.getUsers(token);
      if (isClosed || res.statusCode != 200 || res.body == null) return;
      
      dynamic bodyData = res.body;
      List list = [];

      if (bodyData is List) {
        list = bodyData;
      } else if (bodyData is Map) {
        final rawList =
            bodyData['results'] ??
            bodyData['Results'] ??
            bodyData['data'] ??
            bodyData['items'] ??
            bodyData['values'];

        if (rawList is List) {
          list = rawList;
        } else {
          list = bodyData.values.whereType().toList();
        }
      }

      final me = list.firstWhereOrNull(
        (u) =>
            u is Map &&
            (u['username']?.toString().toLowerCase() ==
                    username.toLowerCase() ||
                u['userName']?.toString().toLowerCase() ==
                    username.toLowerCase()),
      );

      if (me != null && me is Map && !isClosed) {
        final roleName = me['roleName'] ?? me['role'] ?? me['roleNames'];
        await _box.write(
          'role',
          roleName is List
              ? roleName.first.toString()
              : (roleName?.toString() ?? 'user'),
        );
        await _box.write('userId', me['id'] ?? me['userId']);
        await _box.write('fullName', me['fullName'] ?? me['name']);
      }
    } catch (e) {
      print('ROLE LOOKUP FAILED: $e');
    }
  }

  void navigateToForgotPassword() => Get.toNamed('/forgot-password');
  void navigateToRegister() => Get.toNamed('/Register');

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}