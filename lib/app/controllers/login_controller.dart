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

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  var isPasswordObscured = true.obs;
  var isLoading = false.obs;

  void togglePasswordVisibility() {
    isPasswordObscured.value = !isPasswordObscured.value;
  }

  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      Get.snackbar('Error', 'Please fill in all fields');
      return;
    }

    isLoading.value = true;
    try {
      final response = await authProvider.LoginUser({
        'username': username,
        'password': password,
      });

      final body = response.body;
      final isSuccess =
          response.statusCode == 200 &&
          (body is! Map ||
              body['statusCode'] == null ||
              body['statusCode'] == 200);

      // Extract result map safely to resolve Dart type analysis issues
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
        // Fetch user info and role
        await _loadRole(access, username);
        Get.snackbar('Success', 'Welcome back!');
        final bool hasPermission = AuthService.can('vehicle.view');
        Get.offAllNamed(hasPermission ? '/admin' : '/home');
      } else {
        final errorMsg =
            (body is Map ? body['message'] : null) ??
            response.statusText ??
            'Login failed';
        Get.snackbar('Login Failed', errorMsg.toString());
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to connect: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadRole(String token, String username) async {
    await _box.write('role', 'user'); // safe default
    try {
      final res = await userProvider.getUsers(token);
      print('USER LIST status=${res.statusCode}');
      print('USER LIST body=${res.body}');
      if (res.statusCode != 200 || res.body == null) return;
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
          list = bodyData.values.whereType<Map>().toList();
        }
      }

      print('USERS FOUND count: ${list.length}');

      final me = list.firstWhereOrNull(
        (u) =>
            u is Map &&
            (u['username']?.toString().toLowerCase() ==
                    username.toLowerCase() ||
                u['userName']?.toString().toLowerCase() ==
                    username.toLowerCase()),
      );
      print('ME: $me');

      if (me != null && me is Map) {
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
    print('ROLES AFTER LOGIN: ${AuthService.roles}');
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
