import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/home_controller.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/footer_section.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/navbar_widget.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/vehicle_card.dart';

class BrandPage extends StatefulWidget {
  const BrandPage({super.key});

  @override
  State<BrandPage> createState() => _BrandPageState();
}

class _BrandPageState extends State<BrandPage> {
  final HomeController c = Get.isRegistered<HomeController>()
      ? Get.find<HomeController>()
      : Get.put(HomeController());

  final RxString _model = ''.obs; // '' = all models
  late final int? _id = int.tryParse(Get.parameters['id'] ?? '');

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 650;
    final h = isMobile ? 16.0 : 40.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const NavbarWidget(),
      body: Obx(() {
        if (c.isLoadingVehicles.value || c.isLoadingBrands.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final brand = c.brandList.firstWhereOrNull((b) => b.id == _id);
        if (brand == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Brand not found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Get.offAllNamed('/home'),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          );
        }

        final all = c.vehicleList
            .where((v) => v.brandName.toLowerCase() == brand.name.toLowerCase())
            .toList();

        final models = <String>{
          for (final v in all)
            if (v.modelName.isNotEmpty) v.modelName,
        }.toList()..sort();

        final selected = _model.value;
        final shown = selected.isEmpty
            ? all
            : all.where((v) => v.modelName == selected).toList();

        return SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1700),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: h, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Get.back();
                            } else {
                              Get.offAllNamed('/home');
                            }
                          },
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Back'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blueGrey.shade700,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Brand header
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isMobile ? 20 : 32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: isMobile ? 56 : 76,
                                height: isMobile ? 56 : 76,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF111111),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  c.getBrandIcon(brand.name),
                                  color: Colors.white,
                                  size: isMobile ? 26 : 36,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      brand.name,
                                      style: TextStyle(
                                        fontSize: isMobile ? 26 : 40,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if ((brand.note ?? '').isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          brand.note!,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F4F5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${all.length} vehicles',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Model filter chips
                        if (models.isNotEmpty) ...[
                          const Text(
                            'Models',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _chip(
                                'All',
                                selected.isEmpty,
                                () => _model.value = '',
                              ),
                              for (final m in models)
                                _chip(m, selected == m, () => _model.value = m),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Vehicles grid
                        if (shown.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text('No vehicles for this brand yet'),
                            ),
                          )
                        else
                          LayoutBuilder(
                            builder: (context, box) {
                              const gap = 16.0;
                              final w = box.maxWidth;
                              final cols = w < 520
                                  ? 1
                                  : (w < 900 ? 2 : (w < 1300 ? 3 : 4));
                              final cardW = (w - gap * (cols - 1)) / cols;

                              return Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: [
                                  for (final v in shown)
                                    VehicleCard(
                                      vehicle: v,
                                      width: cardW,
                                      onTap: () =>
                                          Get.toNamed('/vehicle/${v.id}'),
                                      onBook: () =>
                                          Get.toNamed('/vehicle/${v.id}'),
                                    ),
                                ],
                              );
                            },
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const FooterSection(),
            ],
          ),
        );
      }),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: Colors.black87,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? Colors.black87 : Colors.grey.shade300),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );
  }
}
