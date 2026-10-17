import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/booking_controller.dart';
import 'package:vrs_ui/app/controllers/checkout_controller.dart';

class CheckoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookingController>(() => BookingController(), fenix: true);
    Get.lazyPut<CheckoutController>(() => CheckoutController());
  }
}
