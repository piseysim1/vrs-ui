import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/register_controller.dart';
import 'package:vrs_ui/app/ui/pages/auth/widget/auth_footer_link.dart';
import 'package:vrs_ui/app/ui/pages/auth/widget/input_dec_widget.dart';
import 'package:vrs_ui/app/ui/pages/auth/widget/label_text_widget.dart';

class RegisterPage extends GetView<RegisterController> {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'DriveBlue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF003399),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'join to manage your fleet efficiently',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
                const SizedBox(height: 24),
                const Divider(color: Color(0xFFE2E8F0), thickness: 1),
                const SizedBox(height: 24),
                const LabelTextWidget(label: 'User Name'),
                const SizedBox(height: 8),
                InputDecorationWidget(
                  controller: controller.userNameController,
                  hintText: 'pisey',
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 24),
                const LabelTextWidget(label: 'Full Name'),
                const SizedBox(height: 8),
                InputDecorationWidget(
                  controller: controller.fullNameController,
                  hintText: 'sok pisey',
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                const LabelTextWidget(label: 'Email'),
                const SizedBox(height: 8),
                InputDecorationWidget(
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  hintText: '***@example.com',
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                const LabelTextWidget(label: 'Phone Number'),
                const SizedBox(height: 8),
                InputDecorationWidget(
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                  hintText: '+855 *** *** ***',
                  prefixIcon: Icons.phone_outlined,
                ),
                const SizedBox(height: 16),
                const LabelTextWidget(label: 'Password'),
                const SizedBox(height: 8),
                Obx(
                  () => InputDecorationWidget(
                    controller: controller.passwordController,
                    hintText: 'Enter password',
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
                const SizedBox(height: 20),
                Obx(
                  () => Row(
                    children: [
                      Checkbox(
                        value: controller.agreeToTerms.value,
                        onChanged: controller.toggleAgreeToTerms,
                        activeColor: const Color(0xFF003399),
                      ),
                      const Expanded(
                        child: Text(
                          'I agree to the Terms & Conditions',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Register Button
                ElevatedButton(
                  onPressed: controller.register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003399),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Register  →',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                AuthFooterLink(
                  text: 'Already have an account? ',
                  actionText: 'Log in here \u2192',
                  onTap: () {
                    Get.toNamed('/login');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
