import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/booking_controller.dart';
import 'package:vrs_ui/app/controllers/home_controller.dart';
import 'package:vrs_ui/app/data/providers/home_provider.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeProvider());
    Get.lazyPut<BookingController>(() => BookingController(), fenix: true);
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
  }
}
