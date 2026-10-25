import 'package:flutter/material.dart';

class FeaturesBannerWidget extends StatefulWidget {
  const FeaturesBannerWidget({super.key});

  @override
  State<FeaturesBannerWidget> createState() => _FeaturesBannerWidgetState();
}

class _FeaturesBannerWidgetState extends State<FeaturesBannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const Color _primary = Color(0xFF0F172A);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _accent = Color(0xFF2563EB);

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.verified_user_outlined,
      'title': 'Trusted Dealership',
      'subtitle': '100% Genuine & Verified Cars',
    },
    {
      'icon': Icons.local_offer_outlined,
      'title': 'Best Prices',
      'subtitle': 'Competitive Market Rates',
    },
    {
      'icon': Icons.support_agent_outlined,
      'title': 'Expert Support',
      'subtitle': 'Always Here to Help',
    },
    {
      'icon': Icons.swap_horiz_rounded,
      'title': 'Easy Trade-In',
      'subtitle': 'Upgrade with Confidence',
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward(); // Starts animation automatically on load
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          // Responsive grid layout calculation
          int crossAxisCount = width > 900 ? 4 : (width > 550 ? 2 : 1);
          double itemWidth =
              (width - ((crossAxisCount - 1) * 16)) / crossAxisCount;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: List.generate(_features.length, (index) {
              // Staggered interval for each item card (makes them appear sequentially)
              final double startDelay = (index * 0.15);
              final double endDelay = startDelay + 0.5;

              final animation = CurvedAnimation(
                parent: _controller,
                curve: Interval(
                  startDelay.clamp(0.0, 1.0),
                  endDelay.clamp(0.0, 1.0),
                  curve: Curves.easeOutCubic,
                ),
              );

              return SizedBox(
                width: itemWidth > 0 ? itemWidth : width,
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: animation.value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - animation.value)),
                        child: child,
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      // Icon Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        child: Icon(
                          _features[index]['icon'] as IconData,
                          size: 24,
                          color: _accent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Title and Subtitle Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _features[index]['title'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _features[index]['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
