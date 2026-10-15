import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AuthFooterLink extends StatelessWidget {
  final String text;
  final String actionText;
  final VoidCallback onTap;

  const AuthFooterLink({
    super.key,
    required this.text,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Color(0xFF64748B), 
            fontSize: 14,
          ),
          children: [
            TextSpan(
              text: actionText,
              style: const TextStyle(
                color: Color(0xFF003399),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()..onTap = onTap,
            ),
          ],
        ),
      ),
    );
  }
}
