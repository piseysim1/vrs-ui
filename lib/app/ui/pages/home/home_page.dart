import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/home_controller.dart';
import 'package:vrs_ui/app/core/utils/image_url.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/brand_card.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/brand_slider.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/discover_section.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/footer_section.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/hero_banner.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/navbar_widget.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/search_bar_section.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/trending_section.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    final isMobile = MediaQuery.of(context).size.width < 650;
    final scroll = ScrollController(); // add this

    void openVehicle(v) => Get.toNamed('/vehicle/${v.id}');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const NavbarWidget(),

      body: SingleChildScrollView(
        controller: scroll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SearchBarSection(),
                  const SizedBox(height: 30),

                  // ── Hero slideshow (real cars from your data) ──
                  Obx(() {
                    final loading = controller.isLoadingVehicles.value;
                    final all = controller.vehicleList.toList();
                    final withImage = all
                        .where((v) => resolveImageUrl(v.imageUrl) != null)
                        .toList();
                    final source = withImage.isNotEmpty ? withImage : all;

                    return HeroBanner(
                      vehicles: source.take(5).toList(),
                      loading: loading,
                      onBook: openVehicle,
                    );
                  }),
                  const SizedBox(height: 30),

                  // ── Browse by brand ──
                  // const Text(
                  //   'Browse by Brand',
                  //   style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  // ),
                  // const SizedBox(height: 16),
                  // Obx(() {
                  //   final selectedId = controller.selectedBrandId.value;

                  //   if (controller.isLoadingBrands.value) {
                  //     return const Center(
                  //       child: Padding(
                  //         padding: EdgeInsets.all(20.0),
                  //         child: CircularProgressIndicator(),
                  //       ),
                  //     );
                  //   }
                  //   if (controller.brandList.isEmpty) {
                  //     return const Text('No brands available');
                  //   }
                  //   return BrandSlider(
                  //     itemCount: controller.brandList.length,
                  //     itemBuilder: (context, index) {
                  //       final brand = controller.brandList[index];
                  //       final isSelected = selectedId == brand.id;
                  //       return BrandCard(
                  //         icon: controller.getBrandIcon(brand.name),
                  //         title: brand.name,
                  //         subtitle: brand.note ?? 'Quality ride',
                  //         isSelected: isSelected,
                  //         onTap: () {
                  //           controller.selectedBrandId.value = isSelected
                  //               ? -1
                  //               : (brand.id ?? -1);
                  //         },
                  //       );
                  //     },
                  //   );
                  // }),

                  // const SizedBox(height: 40),

                  // ── Trending cars ──
                  Obx(() {
                    if (controller.isLoadingVehicles.value) {
                      return const SizedBox.shrink();
                    }
                    return TrendingSection(
                      vehicles: controller.vehicleList.take(8).toList(),
                      onOpen: openVehicle,
                    );
                  }),
                  const SizedBox(height: 40),

                  // ── Discover all vehicles ──
                  Obx(() {
                    if (controller.isLoadingVehicles.value) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return DiscoverSection(
                      vehicles: controller.filteredVehicles.toList(),
                      onOpen: openVehicle,
                    );
                  }),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            const FooterSection(),
          ],
        ),
      ),
    );
  }
}
