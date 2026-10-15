import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/admin_controller.dart';

class AdminDashboardPage extends GetView<AdminController> {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final list = controller.vehicles;
      final byStatus = <String, int>{};
      for (final v in list) {
        final s = v.statusName.isEmpty ? 'Unknown' : v.statusName;
        byStatus[s] = (byStatus[s] ?? 0) + 1;
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Overview of your fleet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _stat(
                  'Total Vehicles',
                  '${list.length}',
                  Icons.directions_car,
                  const Color(0xFF003399),
                ),
                _stat(
                  'Brands',
                  '${controller.brands.length}',
                  Icons.sell_outlined,
                  Colors.orange,
                ),
                _stat(
                  'Locations',
                  '${controller.locations.length}',
                  Icons.place_outlined,
                  Colors.teal,
                ),
                ...byStatus.entries.map(
                  (e) => _stat(
                    e.key,
                    '${e.value}',
                    Icons.info_outline,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _stat(String label, String value, IconData icon, Color color) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
