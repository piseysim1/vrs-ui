import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/login_controller.dart';
import 'package:vrs_ui/app/ui/pages/auth/widget/auth_footer_link.dart';
import 'package:vrs_ui/app/ui/pages/auth/widget/input_dec_widget.dart';
import 'package:vrs_ui/app/ui/pages/auth/widget/label_text_widget.dart';
import 'package:vrs_ui/app/ui/pages/auth/widget/primarybutton.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is active and ready
    Get.put(LoginController());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(36.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Logo + Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.directions_car_filled_outlined,
                        size: 34,
                        color: Color(0xFF003399),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'DriveBlue',
                        style: TextStyle(
                          color: Color(0xFF003399),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Enhanced Styling for "Welcome Back"
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF003399), Color(0xFF2563EB)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to manage your fleet and rentals.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const LabelTextWidget(label: 'Username'),
                  const SizedBox(height: 8),
                  InputDecorationWidget(
                    controller: controller.usernameController,
                    keyboardType: TextInputType.text,
                    hintText: 'Enter your username',
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const LabelTextWidget(label: 'Password'),
                      GestureDetector(
                        onTap: controller.navigateToForgotPassword,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color(0xFF003399),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => InputDecorationWidget(
                      controller: controller.passwordController,
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      obscureText: controller.isPasswordObscured.value,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordObscured.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF64748B),
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Obx(
                    () => PrimaryButton(
                      text: controller.isLoading.value
                          ? 'Signing In...'
                          : 'Sign In ',
                      onPressed: () {
                        controller.login();
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  AuthFooterLink(
                    text: 'New to DriveBlue?',
                    actionText: ' Don\'t have account yet?',
                    onTap: () {
                      Get.toNamed('/register');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}