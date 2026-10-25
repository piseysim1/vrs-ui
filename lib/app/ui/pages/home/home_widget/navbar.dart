import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/home_controller.dart';
import 'package:vrs_ui/app/core/utils/auth_service.dart';
import 'package:vrs_ui/app/ui/pages/profile/widget/user_avatar.dart';

class NavbarWidget extends StatelessWidget implements PreferredSizeWidget {
  const NavbarWidget({super.key});

  static const _ink = Color(0xFF111111);

  @override
  Size get preferredSize => const Size.fromHeight(88);

  void _openBrand(int id) {
    final route = '/brand/$id';
    if (Get.currentRoute.startsWith('/brand/')) {
      Get.offNamed(route);
    } else {
      Get.toNamed(route);
    }
  }

  void _goToAbout() {
    if (Get.currentRoute == '/home') {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().scrollToAbout();
      }
    } else {
      HomeController.pendingAbout = true;
      Get.offAllNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 650;
    final isAdmin = AuthService.can('vehicle.view');
    final current = Get.currentRoute;

    return ColoredBox(
      color: const Color(0xFFF7F8FA),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 12 : 40,
          12,
          isMobile ? 12 : 40,
          8,
        ),
        child: Container(
          height: 68,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Logo
              InkWell(
                onTap: () => Get.offAllNamed('/home'),
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _ink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_car_filled,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'DRIVEBLUE',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation pill bar: only 'Fleet' for Admin, standard menu for regular users
              if (!isMobile || isAdmin) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isAdmin) ...[
                        _pill(
                          'Home',
                          selected: current == '/home',
                          onTap: () => Get.offAllNamed('/home'),
                        ),
                        _brandsMenu(
                          selected: current.startsWith('/brand'),
                          isMobile: false,
                        ),
                        _pill(
                          'History Bookings',
                          onTap: () => Get.offAllNamed('/my-bookings'),
                        ),
                        _pill('About Us', onTap: _goToAbout),
                      ],
                      if (isAdmin)
                        _pill(
                          'Fleet',
                          selected: current.startsWith('/admin'),
                          onTap: () => Get.toNamed('/admin'),
                        ),
                    ],
                  ),
                ),
              ],
              const Spacer(),

              if (isMobile && !isAdmin)
                _brandsMenu(
                  selected: current.startsWith('/brand'),
                  isMobile: true,
                ),
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.black54,
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 4),

              // Profile avatar: /profile when logged in, /login otherwise
              Obx(
                () => Tooltip(
                  message: AuthService.isLoggedIn ? 'My profile' : 'Log in',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Get.toNamed(
                      AuthService.isLoggedIn ? '/profile' : '/login',
                    ),
                    child: UserAvatar(
                      url: AuthService.avatar.value ?? AuthService.savedAvatar,
                      name: AuthService.isLoggedIn ? 'U' : '?',
                      radius: 19,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Brands dropdown: opens the brand page
  Widget _brandsMenu({required bool selected, required bool isMobile}) {
    if (!Get.isRegistered<HomeController>()) return const SizedBox.shrink();
    final c = Get.find<HomeController>();

    return Obx(() {
      final brands = c.brandList.toList();

      return PopupMenuButton<int>(
        tooltip: 'Brands',
        offset: const Offset(0, 52),
        color: Colors.white,
        elevation: 10,
        constraints: const BoxConstraints(minWidth: 220, maxHeight: 420),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: _openBrand,
        itemBuilder: (_) => brands
            .map(
              (b) => PopupMenuItem<int>(
                value: b.id ?? -1,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4F4F5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        c.getBrandIcon(b.name),
                        size: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      b.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        child: isMobile
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.grid_view_rounded, color: Colors.black54),
              )
            : _pillChild('Brands', selected: selected, arrow: true),
      );
    });
  }

  Widget _pill(String title, {bool selected = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: _pillChild(title, selected: selected),
    );
  }

  Widget _pillChild(String title, {bool selected = false, bool arrow = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? _ink : Colors.transparent,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : Colors.black54,
            ),
          ),
          if (arrow) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: selected ? Colors.white : Colors.black54,
            ),
          ],
        ],
      ),
    );
  }
}
