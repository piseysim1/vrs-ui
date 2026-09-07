import 'package:get/get.dart';
import 'package:vrs_ui/app/ui/screens/auth/register_page.dart';

import '../bindings/auth_binding.dart';


part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.AUTH;

  static final routes = [
    GetPage(
      name: _Paths.AUTH,
      page: () => const RegisterPage(),
      binding: AuthBinding(),
    ),
  ];
}
