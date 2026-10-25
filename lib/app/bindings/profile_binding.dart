import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/profile_controller.dart';
import 'package:vrs_ui/app/data/providers/auth_provider.dart';
import 'package:vrs_ui/app/data/providers/user_provider.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthProvider());
    Get.lazyPut(() => UserProvider());
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
