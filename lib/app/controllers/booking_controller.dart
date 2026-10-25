import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/admin_controller.dart'; // statusKindOf, kStatusTypeId
import 'package:vrs_ui/app/core/utils/auth_service.dart';
import 'package:vrs_ui/app/data/models/booking_model.dart';
import 'package:vrs_ui/app/data/models/option_item.dart';
import 'package:vrs_ui/app/data/models/vehicle_model.dart';
import 'package:vrs_ui/app/data/providers/admin_provider.dart';

const kBusinessSourceTypeId = 5;
const kBookingStatusTypeId = 1;

class BookingController extends GetxController {
  final api = AdminProvider();
  static const pageSize = 8;

  final bookings = <BookingModel>[].obs;
  final details = <BookingDetailModel>[].obs;
  final users = <OptionItem>[].obs;
  final sources = <OptionItem>[].obs;
  final statuses = <OptionItem>[].obs; // booking statuses (lookup type 1)
  final vehicles = <VehicleModel>[].obs;
  final vehicleStatuses =
      <OptionItem>[].obs; // vehicle statuses (lookup type 3)
  final _userInfo = <int, Map<String, dynamic>>{};

  final isLoading = false.obs;
  final search = ''.obs;
  final filter = 'all'.obs; // all | pending | approved | rejected
  final page = 0.obs;

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
    try {
      isLoading.value = true;
      final res = await Future.wait([
        api.getBookings(), // 0
        api.getBookingDetails(), // 1
        api.getUsers(), // 2
        api.getVehicles(), // 3
      ]);

      if (_ok(res[0].statusCode)) {
        bookings.value = _list(res[0].body)
            .map((e) => BookingModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        Get.snackbar(
          'Bookings',
          'HTTP ${res[0].statusCode}: ${res[0].bodyString}',
        );
      }

      if (_ok(res[1].statusCode)) {
        details.value = _list(res[1].body)
            .map(
              (e) => BookingDetailModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      }

      if (_ok(res[2].statusCode)) {
        final list = _list(res[2].body);
        _userInfo.clear();
        for (final e in list) {
          final m = Map<String, dynamic>.from(e);
          _userInfo[(m['id'] as num?)?.toInt() ?? 0] = m;
        }
        users.value = list
            .map(
              (e) => OptionItem(
                id: e['id'] ?? 0,
                name: (e['fullName'] ?? e['username'] ?? '').toString(),
              ),
            )
            .toList();
      }

      if (_ok(res[3].statusCode)) {
        vehicles.value = _list(res[3].body)
            .map((e) => VehicleModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      if (sources.isEmpty || statuses.isEmpty || vehicleStatuses.isEmpty) {
        final items = await api.fetchLookupItems();
        sources.value = items
            .where((e) => e.typeId == kBusinessSourceTypeId)
            .toList();
        statuses.value = items
            .where((e) => e.typeId == kBookingStatusTypeId)
            .toList();
        vehicleStatuses.value = items
            .where((e) => e.typeId == kStatusTypeId)
            .toList();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load bookings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------- stats ----------------
  int get totalCount => bookings.length;

  double get revenue => bookings
      .where((b) => b.approval != Approval.rejected)
      .fold(0.0, (s, b) => s + b.total);

  /// approved, dates running now, car not returned yet
  int get activeCount => bookings.where((b) => b.isRunning).length;

  /// approved, not started yet
  int get upcomingCount => bookings
      .where(
        (b) =>
            b.approval == Approval.approved &&
            !b.isReturned &&
            b.state == BookingState.upcoming,
      )
      .length;

  int get overdueCount => bookings.where((b) => b.isOverdue).length;

  int _ap(Approval a) => bookings.where((b) => b.approval == a).length;
  int get pendingCount => _ap(Approval.pending);
  int get approvedCount => _ap(Approval.approved);
  int get rejectedCount => _ap(Approval.rejected);

  Map<String, int> get bySource {
    final m = <String, int>{};
    for (final b in bookings) {
      final k = b.businessSourceName.isEmpty ? 'Other' : b.businessSourceName;
      m[k] = (m[k] ?? 0) + 1;
    }
    return m;
  }

  // ---------------- list ----------------
  List<BookingModel> get filtered {
    final q = search.value.trim().toLowerCase();
    return bookings.where((b) {
      if (filter.value != 'all' && b.approval.name != filter.value) {
        return false;
      }
      return q.isEmpty ||
          b.bookingNo.toLowerCase().contains(q) ||
          b.username.toLowerCase().contains(q) ||
          b.businessSourceName.toLowerCase().contains(q);
    }).toList()..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
  }

  int get pageCount =>
      (filtered.length / pageSize).ceil().clamp(1, 9999).toInt();

  List<BookingModel> get pageItems {
    final l = filtered;
    final s = (page.value * pageSize).clamp(0, l.length).toInt();
    final e = (s + pageSize).clamp(0, l.length).toInt();
    return l.sublist(s, e);
  }

  void setSearch(String v) {
    search.value = v;
    page.value = 0;
  }

  void setFilter(String v) {
    filter.value = v;
    page.value = 0;
  }

  List<BookingDetailModel> linesOf(int? bookingId) =>
      details.where((d) => d.bookingId == bookingId).toList();

  // ---------------- table helpers ----------------
  String emailOf(int? uid) => '${_userInfo[uid]?['email'] ?? ''}';

  List<VehicleModel> vehiclesOf(BookingModel b) {
    final ids = linesOf(b.id).map((d) => d.vehicleId).toSet();
    return vehicles.where((v) => ids.contains(v.id)).toList();
  }

  int _vStatusId(String name, int fallback) =>
      vehicleStatuses
          .firstWhereOrNull((s) => s.name.toLowerCase() == name)
          ?.id ??
      fallback;

  // ---------------- approve / reject / return ----------------
  /// [name] = Approved | Rejected | Completed
  Future<bool> setStatus(BookingModel b, String name) async {
    final st = statuses.firstWhereOrNull(
      (s) => s.name.toLowerCase() == name.toLowerCase(),
    );
    if (st == null) {
      Get.snackbar('Status', 'Item "$name" not found in lookup type 1');
      return false;
    }

    // vehicles of this booking
    var cars = vehiclesOf(b);
    if (cars.isEmpty) {
      final full = await fetchOne(b.id!);
      final ids = (full?.lines ?? []).map((d) => d.vehicleId).toSet();
      cars = vehicles.where((v) => ids.contains(v.id)).toList();
    }

    // never approve a car that is not free
    if (name == 'Approved') {
      final busy = cars.where(
        (v) => statusKindOf(v.statusName) != StatusKind.available,
      );
      if (busy.isNotEmpty) {
        Get.snackbar(
          'Not available',
          '${busy.first.displayName} is ${busy.first.statusName}. Cannot approve.',
        );
        return false;
      }
    }

    final r = await api.changeBookingStatus(b.id!, st.id);
    print('STATUS ${r.statusCode}: ${r.bodyString}');
    if (!_ok(r.statusCode)) {
      Get.snackbar('Failed', 'HTTP ${r.statusCode}: ${r.bodyString}');
      return false;
    }

    // keep the car in sync with the booking
    if (name == 'Approved') {
      await _setVehicles(cars, _vStatusId('rented', 6));
    } else if (name == 'Completed' ||
        (name == 'Rejected' && b.approval == Approval.approved)) {
      await _setVehicles(cars, _vStatusId('available', 4));
    }

    Get.snackbar('Done', 'Booking ${b.bookingNo} ${name.toLowerCase()}');
    await load();
    return true;
  }

  Future<void> _setVehicles(List<VehicleModel> cars, int statusId) async {
    for (final v in cars) {
      final r = await api.updateVehicle(v.id!, {
        'id': v.id,
        'licensePlate': v.licensePlate,
        'brandId': v.brandId,
        'modelId': v.modelId,
        'locationId': v.locationId,
        'colorId': v.colorId ?? 0,
        'statusId': statusId,
        'imageUrl': v.imageUrl,
      });
      print('VEHICLE ${v.id} -> status $statusId: ${r.statusCode}');
    }
  }

  /// One booking with its lines and documents (View dialog).
  Future<BookingModel?> fetchOne(int id) async {
    final r = await api.getBooking(id);
    if (!_ok(r.statusCode) || r.body is! Map) return null;
    final m = Map<String, dynamic>.from(r.body);
    final inner = m['result'] is Map
        ? Map<String, dynamic>.from(m['result'])
        : m;
    return BookingModel.fromJson(inner);
  }

  // ---------------- create ----------------
  
  String _nextNo() {
    var max = 0;
    for (final b in bookings) {
      final n = int.tryParse(b.bookingNo.replaceAll(RegExp(r'[^0-9]'), ''));
      if (n != null && n > max) max = n;
    }
    if (max == 0) max = DateTime.now().millisecondsSinceEpoch % 100000;
    return 'R${(max + 1).toString().padLeft(6, '0')}';
  }

  int _daysBetween(DateTime start, DateTime end) {
    final h = end.difference(start).inHours;
    return h <= 24 ? 1 : (h / 24).ceil();
  }

  Future<bool> createBooking({
    required int userId,
    required int? sourceId,
    required DateTime start,
    required DateTime end,
    required List<VehicleModel> vehicles,
    double taxRate = 0,
    Map<String, dynamic> extra = const {},
  }) async {
    try {
      final days = _daysBetween(start, end);
      double priceOf(VehicleModel v) => v.dayPrice ?? v.price ?? 0;

      final lines = [
        for (final v in vehicles)
          {
            'vehicleId': v.id,
            'description': v.displayName,
            'qty': days,
            'unitPrice': priceOf(v),
            'subTotal': priceOf(v) * days,
          },
      ];
      final subtotal = vehicles.fold<double>(
        0,
        (s, v) => s + priceOf(v) * days,
      );
      final total = subtotal * (1 + taxRate);
      final no = _nextNo();

      final body = {
        'bookingNo': no,
        'userId': userId,
        'businessSourceId': sourceId ?? 0,
        'startDate': start.toUtc().toIso8601String(),
        'endDate': end.toUtc().toIso8601String(),
        'total': total,
        'bookingDetails': lines,
        ...extra,
      };
      print('CREATE BOOKING body: $body');

      final res = await api.createBooking(body);
      print('CREATE BOOKING ${res.statusCode}: ${res.bodyString}');

      if (!_ok(res.statusCode)) {
        Get.snackbar(
          'Booking failed',
          'HTTP ${res.statusCode}: ${res.bodyString}',
          duration: const Duration(seconds: 8),
        );
        return false;
      }

      Get.snackbar('Success', 'Booking $no created');
      await load();
      return true;
    } catch (e) {
      Get.snackbar('Error', '$e');
      return false;
    }
  }

  Future<bool> bookAsCustomer(
    VehicleModel v,
    DateTime start,
    DateTime end,
  ) async {
    final uid = AuthService.userId;
    if (uid == null) {
      Get.snackbar('Login required', 'Please log in to book');
      return false;
    }
    return createBooking(
      userId: uid,
      sourceId: null,
      start: start,
      end: end,
      vehicles: [v],
    );
  }

  // ---------------- delete ----------------
  Future<bool> removeBooking(int id) async {
    for (final d in linesOf(id)) {
      if (d.id != null) await api.deleteBookingDetail(d.id!);
    }
    await api.deleteBooking(id);
    await load();
    final gone = !bookings.any((b) => b.id == id);
    Get.snackbar(
      gone ? 'Deleted' : 'Delete failed',
      gone ? 'Booking removed' : 'The server did not remove it',
    );
    return gone;
  }
}
