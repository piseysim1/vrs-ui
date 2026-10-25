import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/home_controller.dart';

class FooterSection extends StatelessWidget {
  final VoidCallback? onBackToTop;
  const FooterSection({super.key, this.onBackToTop});

  static const _ink = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 650;
    final h = isMobile ? 16.0 : 40.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(h, 20, h, 24),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 24 : 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 900;
                final about = _about();
                final cols = [
                  _column('INFO & SUPPORT', [
                    'About Us',
                    'Contact Us',
                    'How to Book',
                    'FAQ',
                    'Blog',
                  ]),
                  _column('LEGAL & POLICIES', [
                    'Terms & Conditions',
                    'Privacy Policy',
                    'Cancellation Policy',
                    'Cookie Policy',
                  ]),
                  _contact(),
                ];

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: about),
                      for (final col in cols) Expanded(flex: 2, child: col),
                    ],
                  );
                }
                return Wrap(
                  spacing: 40,
                  runSpacing: 32,
                  children: [
                    SizedBox(width: c.maxWidth, child: about),
                    for (final col in cols)
                      SizedBox(
                        width: c.maxWidth < 560
                            ? c.maxWidth
                            : (c.maxWidth - 40) / 2,
                        child: col,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 36),
            _brandsRow(),
            const SizedBox(height: 28),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 14,
              spacing: 16,
              children: [
                const Text(
                  '© 2026 DriveBlue  |  Vehicle Rental Services',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final p in ['ABA PAY', 'KHQR', 'VISA', 'MASTERCARD'])
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          p,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    if (onBackToTop != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onBackToTop,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _about() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.directions_car_filled,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'DRIVEBLUE',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Let's hit the road together!",
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            for (final i in [
              Icons.facebook,
              Icons.camera_alt_outlined,
              Icons.chat_bubble_outline_rounded,
              Icons.send_outlined,
            ])
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(i, size: 20, color: Colors.black87),
              ),
          ],
        ),
      ],
    );
  }

  Widget _column(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        for (final l in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {},
              child: Text(
                l.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _contact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'TALK TO US',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 16),
        Text(
          'Need help? Contact us on Telegram.',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        SizedBox(height: 6),
        // TODO: put your real phone, email and address here
        Text(
          '+855 969821152',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 14),
        Row(
          children: [
            Icon(Icons.mail_outline_rounded, size: 18),
            SizedBox(width: 8),
            Text('support@driveblue.com', style: TextStyle(fontSize: 14)),
          ],
        ),
        SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.place_outlined, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Phnom Penh, Cambodia (Pickup & Return)',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _brandsRow() {
    if (!Get.isRegistered<HomeController>()) return const SizedBox.shrink();
    final c = Get.find<HomeController>();

    return Obx(() {
      final brands = c.brandList.toList();
      if (brands.isEmpty) return const SizedBox.shrink();

      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 10,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: Text(
              'Brands:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          for (int i = 0; i < brands.length; i++) ...[
            InkWell(
              onTap: () => Get.toNamed('/brand/${brands[i].id}'),
              child: Text(
                brands[i].name,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
            if (i != brands.length - 1)
              Container(
                width: 1,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.grey.shade400,
              ),
          ],
        ],
      );
    });
  }
}
