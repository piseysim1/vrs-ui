import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/my_bookings_controller.dart';

class MyBookingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyBookingsController>(() => MyBookingsController());
  }
}
