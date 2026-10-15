import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/login_controller.dart';
import 'package:vrs_ui/app/data/providers/auth_provider.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthProvider>(() => AuthProvider());
    Get.lazyPut<LoginController>(() => LoginController());
  }
}
