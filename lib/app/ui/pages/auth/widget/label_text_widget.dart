import 'package:flutter/material.dart';

class LabelTextWidget extends StatelessWidget {
  final String label;

  const LabelTextWidget({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF334155),
      ),
    );
  }
}

