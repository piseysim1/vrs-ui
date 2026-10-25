import 'package:flutter/material.dart';

class OurServicesSection extends StatelessWidget {
  const OurServicesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> services = [
      {
        'icon': Icons.drive_eta,
        'title': 'Self-Drive Rental',
        'description':
            'Explore at your own pace with our wide selection of clean, insured, and reliable vehicles.',
      },
      {
        'icon': Icons.airline_seat_recline_normal,
        'title': 'Chauffeur Service',
        'description':
            'Sit back and relax with our professional, experienced, and courteous drivers.',
      },
      {
        'icon': Icons.flight_land,
        'title': 'Airport Transfers',
        'description':
            'Punctual pick-ups and drop-offs to ensure a stress-free start or end to your trip.',
      },
      {
        'icon': Icons.calendar_month,
        'title': 'Long-Term Lease',
        'description':
            'Cost-effective monthly rental packages designed for businesses and extended stays.',
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'OUR SERVICES',
                style: TextStyle(
                  color: Color.fromARGB(255, 5, 198, 114),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Designed for Your Mobility Needs',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We offer a complete range of flexible car rental services to make your journey smooth and safe.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 900
                      ? 4
                      : constraints.maxWidth > 600
                      ? 2
                      : 1;

                  return GridView.builder(
                    itemCount: services.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.1,
                    ),
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(30.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(
                                  255,
                                  82,
                                  255,
                                  140,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                service['icon'],
                                color: const Color.fromARGB(255, 5, 198, 114),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              service['title'],
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              service['description'],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
