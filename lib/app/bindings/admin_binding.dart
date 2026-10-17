import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/admin_controller.dart';
import 'package:vrs_ui/app/controllers/booking_controller.dart';
import 'package:vrs_ui/app/controllers/checkout_controller.dart';

class AdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CheckoutController>(() => CheckoutController());
    Get.lazyPut<BookingController>(() => BookingController(), fenix: true);
    Get.lazyPut<AdminController>(() => AdminController());
  }
}
