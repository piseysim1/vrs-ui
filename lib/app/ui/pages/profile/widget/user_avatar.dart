import 'package:flutter/material.dart';
import 'package:vrs_ui/app/core/utils/image_url.dart';

class UserAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final double radius;

  const UserAvatar({super.key, this.url, required this.name, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    final full = resolveImageUrl(url);
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    Widget fallback() => Container(
      color: const Color(0xFF003399),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.9,
        ),
      ),
    );

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: full == null
            ? fallback()
            : Image.network(
                full,
                fit: BoxFit.cover,
                errorBuilder: (_, e, __) {
                  debugPrint('AVATAR ERROR ($full): $e');
                  return fallback();
                },
              ),
      ),
    );
  }
}
