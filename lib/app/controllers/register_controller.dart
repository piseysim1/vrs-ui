import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/data/providers/auth_provider.dart';

class RegisterController extends GetxController {
  final AuthProvider authProvider = Get.find();

  final userNameController = TextEditingController();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final isPasswordObscured = true.obs;
  var agreeToTerms = false.obs;
  var isLoading = false.obs;

  void togglePasswordVisibility() {
    isPasswordObscured.value = !isPasswordObscured.value;
  }

  void toggleAgreeToTerms(bool? value) {
    agreeToTerms.value = value ?? false;
  }

  Future<void> register() async {
    if (!agreeToTerms.value) {
      Get.snackbar('Error', 'Please accept the Terms & Conditions');
      return;
    }
    isLoading.value = true;
    final Map payload = {
      'username': userNameController.text.trim(),
      'fullName': fullNameController.text.trim(),
      'email': emailController.text.trim(),
      'phoneNumber': phoneController.text.trim(),
      'password': passwordController.text.trim(),
      'profile': '', // Placeholder for profile image
    };

    try {
      final response = await authProvider.registerUser(payload);
      final isSuccess =
          response.statusCode == 200 ||
          (response.body != null && response.body['statusCode'] == 200);
      if (isSuccess) {
        final successMsg =
            response.body?['result'] ?? 'Registered successfully';
        Get.snackbar('Success', successMsg);
        Get.offAllNamed('/login');
      } else {
        final errorMsg =
            response.body?['message'] ??
            response.statusText ??
            'Registration failed';
        Get.snackbar('Registration Failed', errorMsg);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to create account');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    userNameController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
