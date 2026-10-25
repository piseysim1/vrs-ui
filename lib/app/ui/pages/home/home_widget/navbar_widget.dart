// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:vrs_ui/app/core/utils/auth_service.dart';
// import 'package:vrs_ui/app/ui/pages/profile/widget/user_avatar.dart';

// class NavbarWidget extends StatelessWidget implements PreferredSizeWidget {
//   const NavbarWidget({super.key});

//   static const _primary = Color(0xFF003399);

//   @override
//   Size get preferredSize => const Size.fromHeight(70);

//   @override
//   Widget build(BuildContext context) {
//     final isMobile = MediaQuery.of(context).size.width < 650;
//     final isAdmin = AuthService.can('vehicle.view');
//     final current = Get.currentRoute;

//     return Container(
//       color: Colors.white,
//       padding: EdgeInsets.symmetric(
//         horizontal: isMobile ? 16 : 40,
//         vertical: 15,
//       ),
//       child: Row(
//         children: [
//           InkWell(
//             onTap: () => Get.offAllNamed('/home'),
//             child: const Text(
//               'DriveBlue',
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: _primary,
//               ),
//             ),
//           ),
//           if (!isMobile) ...[
//             const SizedBox(width: 40),
//             _navItem(
//               'Home',
//               isSelected: current == '/home',
//               onTap: () => Get.offAllNamed('/home'),
//             ),
//             _navItem('Bookings', onTap: () {}),
//             if (isAdmin) _navItem('Fleet', onTap: () => Get.toNamed('/admin')),
//             _navItem('About', onTap: () {}),
//           ],
//           const Spacer(),
//           if (isMobile)
//             PopupMenuButton<String>(
//               icon: const Icon(Icons.menu, color: Colors.black54),
//               onSelected: (v) {
//                 if (v == 'home') Get.offAllNamed('/home');
//                 if (v == 'fleet') Get.toNamed('/admin');
//               },
//               itemBuilder: (_) => [
//                 const PopupMenuItem(value: 'home', child: Text('Home')),
//                 const PopupMenuItem(value: 'bookings', child: Text('Bookings')),
//                 if (isAdmin)
//                   const PopupMenuItem(value: 'fleet', child: Text('Fleet')),
//               ],
//             ),
//           IconButton(
//             icon: const Icon(Icons.notifications_none, color: Colors.black54),
//             onPressed: () {},
//           ),
//           const SizedBox(width: 10),
//           Tooltip(
//             message: AuthService.isLoggedIn ? 'My profile' : 'Log in',
//             child: InkWell(
//               customBorder: const CircleBorder(),
//               onTap: () =>
//                   Get.toNamed(AuthService.isLoggedIn ? '/profile' : '/login'),
//               child: Obx(
//                 () => UserAvatar(
//                   url: AuthService.avatar.value ?? AuthService.savedAvatar,
//                   name: AuthService.isLoggedIn ? 'U' : '?',
//                   radius: 18,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _navItem(
//     String title, {
//     bool isSelected = false,
//     VoidCallback? onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(6),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 6),
//         child: Text(
//           title,
//           style: TextStyle(
//             color: isSelected ? _primary : Colors.black38,
//             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//             fontSize: 14,
//           ),
//         ),
//       ),
//     );
//   }
// }
