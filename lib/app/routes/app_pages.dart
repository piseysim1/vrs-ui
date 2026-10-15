import 'package:get/get.dart';
import 'package:vrs_ui/app/bindings/admin_binding.dart';
import 'package:vrs_ui/app/bindings/home_binding.dart';
import 'package:vrs_ui/app/bindings/login_binding.dart';
import 'package:vrs_ui/app/core/utils/admin_middleware.dart';
import 'package:vrs_ui/app/ui/admin/admin_page/admin_page.dart';
import 'package:vrs_ui/app/ui/pages/auth/login_page.dart';
import 'package:vrs_ui/app/ui/pages/auth/register_page.dart';
import 'package:vrs_ui/app/ui/pages/home/brand/brand_page.dart';
import 'package:vrs_ui/app/ui/pages/home/home_page.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/vehicle_detail.dart';
import '../bindings/register_binding.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.Register;

  static final routes = [
    GetPage(
      name: _Paths.Register,
      page: () => const RegisterPage(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: _Paths.Login,
      page: () => LoginPage(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.Home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.VehicleDetail,
      page: () => const VehicleDetailPage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: '/brand/:id',
      page: () => const BrandPage(),
      binding: HomeBinding(),
      // binding: <same binding as '/vehicle/:id', if it has one>,
    ),
    GetPage(
      name: _Paths.Admin,
      page: () => const AdminPage(),
      binding: AdminBinding(),
      middlewares: [AdminMiddleware()],
    ),
  ];
}
