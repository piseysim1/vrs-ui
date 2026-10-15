import 'package:flutter/material.dart';
import 'package:vrs_ui/app/data/models/vehicle_model.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/vehicle_card.dart';

class TrendingSection extends StatelessWidget {
  final List<VehicleModel> vehicles;
  final void Function(VehicleModel v) onOpen;

  const TrendingSection({
    super.key,
    required this.vehicles,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final list = vehicles.take(5).toList();
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons.local_fire_department_outlined,
              size: 24,
              color: Colors.black87,
            ),
            SizedBox(width: 8),
            Text(
              'Trending Cars',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Most popular rides right now',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            const gap = 16.0;
            final w = c.maxWidth;
            final cols = w >= 1250 ? 5 : (w >= 900 ? 3 : (w >= 560 ? 2 : 1));
            final cardW = (w - gap * (cols - 1)) / cols;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (int i = 0; i < list.length; i++)
                  VehicleCard(
                    vehicle: list[i],
                    width: cardW,
                    rank: i + 1,
                    onTap: () => onOpen(list[i]),
                    onBook: () => onOpen(list[i]),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
