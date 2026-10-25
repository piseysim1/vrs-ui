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

  // --- Helper Methods for Custom Snackbars ---
  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.error_outline, color: Colors.white),
      duration: const Duration(seconds: 3),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      duration: const Duration(seconds: 3),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }
  // -------------------------------------------

  Future<void> register() async {
    if (!agreeToTerms.value) {
      _showErrorSnackbar('Error', 'Please accept the Terms & Conditions');
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
        _showSuccessSnackbar('Success', successMsg);
        Get.offAllNamed('/login');
      } else {
        final errorMsg =
            response.body?['message'] ??
            response.statusText ??
            'Registration failed';
        _showErrorSnackbar('Registration Failed', errorMsg);
      }
    } catch (e) {
      _showErrorSnackbar('Error', 'Failed to create account');
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
