import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/booking_controller.dart'; // kBookingStatusTypeId
import 'package:vrs_ui/app/core/utils/auth_service.dart';
import 'package:vrs_ui/app/data/models/booking_model.dart';
import 'package:vrs_ui/app/data/models/option_item.dart';
import 'package:vrs_ui/app/data/models/vehicle_model.dart';
import 'package:vrs_ui/app/data/providers/admin_provider.dart';

class MyBookingsController extends GetxController {
  final api = AdminProvider();

  final bookings = <BookingModel>[].obs;
  final details = <BookingDetailModel>[].obs;
  final vehicles = <VehicleModel>[].obs;
  final statuses = <OptionItem>[].obs;

  final loading = true.obs;
  final filter = 'all'.obs; // all | confirmed | completed | cancelled
  final selectedId = RxnInt();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  List _list(dynamic d) {
    if (d is List) return d;
    if (d is Map) {
      for (final k in const ['results', 'Results', 'items', 'data']) {
        if (d[k] is List) return d[k];
      }
    }
    return [];
  }

  bool _ok(int? c) => c == 200 || c == 201 || c == 204;

  Future<void> load() async {
    final uid = AuthService.userId;
    if (uid == null) {
      Get.offAllNamed('/login');
      return;
    }
    try {
      loading.value = true;
      final res = await Future.wait([
        api.getBookings(),
        api.getBookingDetails(),
        api.getVehicles(),
      ]);

      if (_ok(res[0].statusCode)) {
        bookings.value = _list(res[0].body)
            .map((e) => BookingModel.fromJson(Map<String, dynamic>.from(e)))
            .where((b) => b.userId == uid)
            .toList()
          ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      }
      if (_ok(res[1].statusCode)) {
        details.value = _list(res[1].body)
            .map((e) => BookingDetailModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (_ok(res[2].statusCode)) {
        vehicles.value = _list(res[2].body)
            .map((e) => VehicleModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (statuses.isEmpty) {
        final items = await api.fetchLookupItems();
        statuses.value =
            items.where((e) => e.typeId == kBookingStatusTypeId).toList();
      }
      selectedId.value ??= bookings.isEmpty ? null : bookings.first.id;
    } finally {
      loading.value = false;
    }
  }

  // ---------- counts + filter ----------
  bool _isConfirmed(BookingModel b) =>
      b.approval == Approval.approved && !b.isReturned;
  bool _isCancelled(BookingModel b) => b.approval == Approval.rejected;

  int get allCount => bookings.length;
  int get confirmedCount => bookings.where(_isConfirmed).length;
  int get completedCount => bookings.where((b) => b.isReturned).length;
  int get cancelledCount => bookings.where(_isCancelled).length;
  int get pendingCount =>
      bookings.where((b) => b.approval == Approval.pending).length;

  List<BookingModel> get filtered {
    switch (filter.value) {
      case 'confirmed':
        return bookings.where(_isConfirmed).toList();
      case 'completed':
        return bookings.where((b) => b.isReturned).toList();
      case 'cancelled':
        return bookings.where(_isCancelled).toList();
      default:
        return bookings.toList();
    }
  }

  BookingModel? get selected {
    final list = filtered;
    if (list.isEmpty) return null;
    return list.firstWhereOrNull((b) => b.id == selectedId.value) ?? list.first;
  }

  void setFilter(String f) {
    filter.value = f;
    final list = filtered;
    selectedId.value = list.isEmpty ? null : list.first.id;
  }

  // ---------- helpers ----------
  VehicleModel? vehicleOf(BookingModel b) {
    final ids = details
        .where((d) => d.bookingId == b.id)
        .map((d) => d.vehicleId)
        .toSet();
    return vehicles.firstWhereOrNull((v) => ids.contains(v.id));
  }

  /// Only documents that were actually uploaded.
  List<({String title, String url})> docsOf(BookingModel b) => [
        if ((b.vehicleDocumentUrl ?? '').isNotEmpty)
          (title: 'Vehicle verification document', url: b.vehicleDocumentUrl!),
        if ((b.identityCardUrl ?? '').isNotEmpty)
          (title: 'Khmer Identity Card', url: b.identityCardUrl!),
        if ((b.paymentProofUrl ?? '').isNotEmpty)
          (title: 'Payment Statement', url: b.paymentProofUrl!),
        if ((b.vehicleRegistrationUrl ?? '').isNotEmpty)
          (title: 'Vehicle registration', url: b.vehicleRegistrationUrl!),
      ];

  // ---------- cancel (pending only) ----------
  Future<bool> cancel(BookingModel b) async {
    final st = statuses.firstWhereOrNull(
        (s) => s.name.toLowerCase() == 'cancelled');
    if (st == null) {
      Get.snackbar('Cancel', 'Status "Cancelled" not found in lookup type 1');
      return false;
    }
    final r = await api.changeBookingStatus(b.id!, st.id);
    print('CANCEL ${r.statusCode}: ${r.bodyString}');
    if (!_ok(r.statusCode)) {
      Get.snackbar('Failed', 'HTTP ${r.statusCode}: ${r.bodyString}');
      return false;
    }
    Get.snackbar('Cancelled', 'Booking ${b.bookingNo} was cancelled',
        backgroundColor: const Color(0xFFE6F7EE),
        colorText: const Color(0xFF1E9E5A));
    await load();
    return true;
  }
}