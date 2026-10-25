import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/booking_controller.dart';
import 'package:vrs_ui/app/core/utils/auth_service.dart';
import 'package:vrs_ui/app/data/models/booking_summary_model.dart';
import 'package:vrs_ui/app/data/models/option_item.dart';
import 'package:vrs_ui/app/data/models/payment_method_model.dart';
import 'package:vrs_ui/app/data/models/vehicle_model.dart';
import 'package:vrs_ui/app/data/providers/admin_provider.dart';
import 'package:vrs_ui/app/data/providers/file_provider.dart';

class PickedDoc {
  final String name;
  final Uint8List bytes;
  PickedDoc(this.name, this.bytes);
}

class CheckoutController extends GetxController {
  static const taxRate = 0.10;
  static const _fallbackMethods = [PaymentMethodModel(id: 1, name: 'Cash')];
  final api = AdminProvider();
  final vehicle = Rxn<VehicleModel>();
  final locations = <OptionItem>[].obs;
  final methods = <PaymentMethodModel>[].obs;
  final loading = true.obs;
  final saving = false.obs;

  final locationId = Rxn<int>();
  final paymentId = Rxn<int>();

  final start = DateTime.now().add(const Duration(days: 1)).obs;
  final end = DateTime.now().add(const Duration(days: 3)).obs;

  final docs = <String, PickedDoc>{}.obs;
  bool get isAdmin {
    if (AuthService.can('vehicle.view')) return true;
    const adminRoles = {'admin', 'administrator', 'superadmin'};
    return AuthService.roles.any(adminRoles.contains);
  }

  BookingSummary? lastSummary;

  PaymentMethodModel? get selectedMethod =>
      methods.firstWhereOrNull((m) => m.id == paymentId.value);

  List _list(dynamic d) {
    if (d is List) return d;
    if (d is Map) {
      for (final k in const ['results', 'Results', 'items', 'data']) {
        if (d[k] is List) return d[k];
      }
    }
    return [];
  }

  @override
  void onInit() {
    super.onInit();
    _load(int.tryParse(Get.parameters['id'] ?? ''));
  }

  Future<void> _load(int? id) async {
    try {
      loading.value = true;
      final res = await Future.wait([
        api.getVehicles(),
        api.getLocations(),
        api.getPaymentMethods(),
      ]);

      if (res[0].statusCode == 200) {
        final all = _list(res[0].body)
            .map((e) => VehicleModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        vehicle.value = all.firstWhereOrNull((v) => v.id == id);
      }
      if (res[1].statusCode == 200) {
        locations.value = _list(res[1].body)
            .map((e) => OptionItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      var pm = <PaymentMethodModel>[];
      if (res[2].statusCode == 200) {
        pm =
            _list(res[2].body)
                .map(
                  (e) =>
                      PaymentMethodModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
              ..sort((a, b) => a.ordering.compareTo(b.ordering));
      }
      methods.value = pm.isNotEmpty ? pm : _fallbackMethods;
      paymentId.value = methods.first.id;

      locationId.value =
          vehicle.value?.locationId ??
          (locations.isNotEmpty ? locations.first.id : null);
    } finally {
      loading.value = false;
    }
  }

  double get dailyRate => vehicle.value?.dayPrice ?? vehicle.value?.price ?? 0;

  int get days {
    final h = end.value.difference(start.value).inHours;
    return h <= 24 ? 1 : (h / 24).ceil();
  }

  double get subtotal => dailyRate * days;
  double get tax => subtotal * taxRate;
  double get total => subtotal + tax;

  bool get datesValid => end.value.isAfter(start.value);
  int _maxBookingId(BookingController bc) =>
      bc.bookings.fold<int>(0, (m, b) => (b.id ?? 0) > m ? b.id! : m);

  Future<bool> submit() async {
    if (isAdmin) {
      Get.snackbar('Not allowed', "Admin accounts can't book a vehicle");
      return false;
    }

    final v = vehicle.value;
    if (v == null) return false;
    if (!datesValid) {
      Get.snackbar('Dates', 'Return time must be after pick-up time');
      return false;
    }
    final uid = AuthService.userId;
    if (uid == null) {
      Get.snackbar('Login required', 'Please log in to book');
      return false;
    }

    saving.value = true;
    try {
      final urls = <String, String>{};
      final files = FileProvider();
      for (final e in docs.entries) {
        final url = await files.uploadImage(e.value.bytes, e.value.name);
        if (url == null) {
          Get.snackbar('Upload failed', 'Could not upload ${e.value.name}');
          return false;
        }
        urls[e.key] = url;
      }

      final bc = Get.find<BookingController>();
      final landing = bc.sources.firstWhereOrNull((s) {
        final n = s.name.toLowerCase();
        return n.contains('landing') || n.contains('online');
      });

      final idsBefore = _maxBookingId(bc);

      final ok = await bc.createBooking(
        userId: uid,
        sourceId: landing?.id,
        start: start.value,
        end: end.value,
        vehicles: [v],
        taxRate: taxRate,
        extra: {
          'locationId': locationId.value,
          'paymentMethodId': paymentId.value,
          'vehicleDocumentUrl': urls['vehicleDoc'],
          'identityCardUrl': urls['idCard'],
          'paymentProofUrl': urls['paymentProof'],
          'vehicleRegistrationUrl': urls['registration'],
        },
      );

      if (ok) lastSummary = await _buildSummary(bc, v, idsBefore, uid);
      return ok;
    } finally {
      saving.value = false;
    }
  }

  Future<BookingSummary> _buildSummary(
    BookingController bc,
    VehicleModel v,
    int idsBefore,
    int uid,
  ) async {
    var ref = '';
    try {
      await bc.load();
      final mine =
          bc.bookings
              .where((b) => b.userId == uid && (b.id ?? 0) > idsBefore)
              .toList()
            ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      if (mine.isNotEmpty) ref = mine.first.bookingNo;
    } catch (_) {}

    final loc = locations
        .firstWhereOrNull((l) => l.id == locationId.value)
        ?.name;

    return BookingSummary(
      reference: ref,
      vehicleName: v.displayName,
      brandName: v.brandName,
      imageUrl: v.imageUrl,
      locationName: loc ?? v.locationName,
      start: start.value,
      end: end.value,
      total: total,
    );
  }
}
