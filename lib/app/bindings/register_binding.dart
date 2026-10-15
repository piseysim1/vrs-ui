import 'package:get/get.dart';
import 'package:vrs_ui/app/data/providers/auth_provider.dart';

import '../controllers/register_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthProvider());
    Get.lazyPut<RegisterController>(() => RegisterController());
  }
}
