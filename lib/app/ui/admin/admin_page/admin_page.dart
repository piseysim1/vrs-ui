import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/admin_controller.dart';
import 'package:vrs_ui/app/core/utils/auth_service.dart';
import 'package:vrs_ui/app/ui/admin/admin_booking_page/admin_bookings_page.dart';
import 'package:vrs_ui/app/ui/admin/admin_brand_page/admin_brand_page.dart';
import 'package:vrs_ui/app/ui/admin/admin_customer_page/admin_customer_page.dart';
import 'package:vrs_ui/app/ui/admin/admin_dashboard_page.dart';
import 'package:vrs_ui/app/ui/admin/admin_location_page/admin_location_page.dart';
import 'package:vrs_ui/app/ui/admin/vehicle_page/admin_vehicles_page.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/navbar_widget.dart';

class _MenuItem {
  final String title;
  final IconData icon;
  const _MenuItem(this.title, this.icon);
}

class AdminPage extends GetView<AdminController> {
  const AdminPage({super.key});

  static const _primary = Color(0xFF003399);

  static const _menu = <_MenuItem>[
    _MenuItem('Dashboard', Icons.dashboard_outlined),
    _MenuItem('Bookings', Icons.calendar_month_outlined),
    _MenuItem('Vehicle', Icons.directions_car_filled_outlined),
    _MenuItem('Brand', Icons.sell_outlined),
    _MenuItem('Location', Icons.place_outlined),
    _MenuItem('Customers', Icons.people_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 1000;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: const NavbarWidget(),
          drawer: wide ? null : Drawer(child: _sidebar(closeDrawer: true)),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide) SizedBox(width: 230, child: _sidebar()),
              Expanded(
                child: Obx(() {
                  final i = controller.menuIndex.value;
                  if (i == 0) return const AdminDashboardPage();
                  if (i == 1) return const AdminBookingsPage();
                  if (i == 2) return const AdminVehiclesPage();
                  if (i == 3) return const AdminBrandPage();
                  if (i == 4) return const AdminLocationPage();
                  if (i == 5) return const AdminCustomerPage();
                  return Center(
                    child: Text(
                      '${_menu[i].title} page coming soon',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sidebar({bool closeDrawer = false}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Obx(
            () => Column(
              children: List.generate(_menu.length, (i) {
                final sel = controller.menuIndex.value == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      controller.menuIndex.value = i;
                      if (closeDrawer) Get.back();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFFEAF0FF) : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _menu[i].icon,
                            size: 20,
                            color: sel ? _primary : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _menu[i].title,
                            style: TextStyle(
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: sel ? _primary : Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            dense: true,
            leading: const Icon(Icons.home_outlined),
            title: const Text('Back to website'),
            onTap: () => Get.offAllNamed('/home'),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () {
              AuthService.clear();
              Get.offAllNamed('/login');
            },
          ),
        ],
      ),
    );
  }
}
