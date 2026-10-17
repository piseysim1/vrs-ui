import 'package:flutter/material.dart';
import 'package:vrs_ui/app/core/utils/image_url.dart';
import 'package:vrs_ui/app/data/models/vehicle_model.dart';

class VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback? onTap;
  final VoidCallback? onBook;
  final double? width;
  final int? rank;

  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.onBook,
    this.width = 260,
    this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final url = resolveImageUrl(vehicle.imageUrl);
    final hasPrice = vehicle.price != null && vehicle.price! > 0;

    final status = vehicle.statusName.trim().toLowerCase();
    final isAvailable = status == 'available';
    final isRented = status == 'rented' || status == 'rent';

    // Badge colors
    final Color badgeBg = isAvailable
        ? const Color(0xFFE6F6EC)
        : isRented
        ? const Color(0xFFFDE8E8)
        : Colors.grey.shade200;
    final Color badgeFg = isAvailable
        ? const Color(0xFF1B8A3E)
        : isRented
        ? const Color(0xFFD32F2F)
        : Colors.black87;

    // Button
    final String buttonText = isAvailable
        ? 'Book Now'
        : isRented
        ? 'Rented'
        : 'Unavailable';
    final VoidCallback? buttonAction = isAvailable ? onBook : null;

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: url == null
                            ? _placeholder()
                            : Image.network(
                                url,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                loadingBuilder: (context, child, progress) =>
                                    progress == null
                                    ? child
                                    : const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                errorBuilder: (context, error, stack) {
                                  debugPrint('IMAGE ERROR ($url): $error');
                                  return _placeholder();
                                },
                              ),
                      ),
                    ),

                    // Status badge
                    if (vehicle.statusName.isNotEmpty)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: badgeFg,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                vehicle.statusName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: badgeFg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Rank badge
                    if (rank != null)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(221, 225, 4, 4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '#$rank',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              vehicle.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (hasPrice) ...[
                            const SizedBox(width: 8),
                            Text(
                              '\$${vehicle.price!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            vehicle.licensePlate,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          if (hasPrice &&
                              (vehicle.rateTypeName ?? '').isNotEmpty)
                            Text(
                              '/ ${vehicle.rateTypeName}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _spec(
                              Icons.palette_outlined,
                              vehicle.colorName,
                            ),
                          ),
                          Expanded(
                            child: _spec(
                              Icons.place_outlined,
                              vehicle.locationName,
                            ),
                          ),
                        ],
                      ),

                      // Action button (changes with status)
                      if (onBook != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: isAvailable
                              ? ElevatedButton(
                                  onPressed: buttonAction,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black87,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 11,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: Text(buttonText),
                                )
                              : OutlinedButton(
                                  onPressed: null, // disabled
                                  style: OutlinedButton.styleFrom(
                                    disabledForegroundColor: Colors.grey,
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 11,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: Text(buttonText),
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.grey.shade100,
    child: const Center(
      child: Icon(Icons.directions_car, size: 40, color: Colors.grey),
    ),
  );

  Widget _spec(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 14, color: Colors.grey),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          text.isEmpty ? '-' : text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ),
    ],
  );
}
