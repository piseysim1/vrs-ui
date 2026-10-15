import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/home_controller.dart';
import 'package:vrs_ui/app/core/utils/image_url.dart';
import 'package:vrs_ui/app/data/models/vehicle_model.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/navbar_widget.dart';

class VehicleDetailPage extends GetView<HomeController> {
  const VehicleDetailPage({super.key});

  static const _primary = Color(0xFF003399);

  void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Get.back();
    } else {
      Get.offAllNamed('/home'); // opened directly by URL / refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(Get.parameters['id'] ?? '');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const NavbarWidget(),
      body: Obx(() {
        if (controller.isLoadingVehicles.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final v = controller.vehicleList.firstWhereOrNull((e) => e.id == id);
        if (v == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Vehicle not found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _goBack(context),
                  child: const Text('Back to Fleet'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1700),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width < 650 ? 16 : 40,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () => _goBack(context),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back to Fleet'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blueGrey.shade700,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, c) {
                        final isWide = c.maxWidth >= 900;
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: _image(v)),
                              const SizedBox(width: 24),
                              Expanded(flex: 5, child: _infoCard(v)),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _image(v),
                            const SizedBox(height: 20),
                            _infoCard(v),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _image(VehicleModel v) {
    final url = resolveImageUrl(v.imageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3.2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            url == null
                ? _placeholder()
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, __, ___) => _placeholder(),
                  ),
            if (v.statusName.isNotEmpty)
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, size: 8, color: _primary),
                      const SizedBox(width: 6),
                      Text(
                        v.statusName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.grey.shade200,
    child: const Center(
      child: Icon(Icons.directions_car, size: 80, color: Colors.grey),
    ),
  );
  Widget _infoCard(VehicleModel v) {
    final hasPrice = v.price != null && v.price! > 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  v.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (v.brandName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    v.brandName,
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            v.modelName,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Wrap(
            runSpacing: 14,
            children: [
              _spec(
                Icons.confirmation_number_outlined,
                'Plate',
                v.licensePlate,
              ),
              _spec(Icons.palette_outlined, 'Color', v.colorName),
              _spec(Icons.place_outlined, 'Location', v.locationName),
              _spec(Icons.info_outline, 'Status', v.statusName),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 16),
          if (hasPrice)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${v.price!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    (v.rateTypeName ?? '').isNotEmpty
                        ? '/ ${v.rateTypeName}'
                        : '',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            )
          else
            Text(
              'Price not available',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: go to booking page
                Get.snackbar('Booking', 'Booking page coming soon');
              },
              icon: const Icon(Icons.event_available, size: 20),
              label: const Text('Book Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Free cancellation up to 24 hours before pickup.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _spec(IconData icon, String label, String value) {
    return FractionallySizedBox(
      widthFactor: 0.5,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
                Text(
                  value.isEmpty ? '-' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
