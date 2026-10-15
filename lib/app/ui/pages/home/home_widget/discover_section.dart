import 'package:flutter/material.dart';
import 'package:vrs_ui/app/data/models/vehicle_model.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/vehicle_card.dart';

class DiscoverSection extends StatefulWidget {
  final List<VehicleModel> vehicles;
  final void Function(VehicleModel v) onOpen;
  final int initialCount;

  const DiscoverSection({
    super.key,
    required this.vehicles,
    required this.onOpen,
    this.initialCount = 8,
  });

  @override
  State<DiscoverSection> createState() => _DiscoverSectionState();
}

class _DiscoverSectionState extends State<DiscoverSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final all = widget.vehicles;
    final shown = _showAll ? all : all.take(widget.initialCount).toList();
    final canToggle = all.length > widget.initialCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Text(
                'Discover All Vehicles',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${all.length} available',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (all.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No vehicles available'),
          )
        else
          LayoutBuilder(
            builder: (context, c) {
              const gap = 16.0;
              final w = c.maxWidth;
              final cols = w < 520 ? 1 : (w < 900 ? 2 : (w < 1300 ? 3 : 4));
              final cardW = (w - gap * (cols - 1)) / cols;

              return AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final v in shown)
                      VehicleCard(
                        vehicle: v,
                        width: cardW,
                        onTap: () => widget.onOpen(v),
                        onBook: () => widget.onOpen(v),
                      ),
                  ],
                ),
              );
            },
          ),
        if (canToggle) ...[
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _showAll = !_showAll),
              icon: Icon(
                _showAll
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
              ),
              label: Text(_showAll ? 'Show less' : 'Show all ${all.length} vehicles'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Colors.black87),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}