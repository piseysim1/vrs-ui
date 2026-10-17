import 'package:get/get.dart';
import 'package:vrs_ui/app/core/utils/auth_service.dart';
import 'package:vrs_ui/app/data/models/booking_model.dart';
import 'package:vrs_ui/app/data/models/option_item.dart';
import 'package:vrs_ui/app/data/models/vehicle_model.dart';
import 'package:vrs_ui/app/data/providers/admin_provider.dart';

const kBusinessSourceTypeId = 5;

class BookingController extends GetxController {
  final api = AdminProvider();
  static const pageSize = 8;

  final bookings = <BookingModel>[].obs;
  final details = <BookingDetailModel>[].obs;
  final users = <OptionItem>[].obs;
  final sources = <OptionItem>[].obs;

  final isLoading = false.obs;
  final search = ''.obs;
  final filter = 'all'.obs; // all | upcoming | active | completed
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
        api.getBookings(),
        api.getBookingDetails(),
        api.getUsers(),
      ]);

      if (_ok(res[0].statusCode)) {
        bookings.value = _list(res[0].body)
            .map((e) => BookingModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        Get.snackbar('Bookings', 'HTTP ${res[0].statusCode}: ${res[0].bodyString}');
      }
      if (_ok(res[1].statusCode)) {
        print('BOOKING DETAIL sample: ${_list(res[1].body).take(1)}');
        details.value = _list(res[1].body)
            .map((e) => BookingDetailModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (_ok(res[2].statusCode)) {
        users.value = _list(res[2].body)
            .map((e) => OptionItem(
                  id: e['id'] ?? 0,
                  name: (e['fullName'] ?? e['username'] ?? '').toString(),
                ))
            .toList();
      }
      if (sources.isEmpty) {
        final items = await api.fetchLookupItems();
        sources.value =
            items.where((e) => e.typeId == kBusinessSourceTypeId).toList();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load bookings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------- stats ----------------
  int get totalCount => bookings.length;
  double get revenue => bookings.fold(0.0, (s, b) => s + b.total);
  int _count(BookingState s) => bookings.where((b) => b.state == s).length;
  int get activeCount => _count(BookingState.active);
  int get upcomingCount => _count(BookingState.upcoming);
  int get completedCount => _count(BookingState.completed);

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
      if (filter.value != 'all' && b.state.name != filter.value) return false;
      return q.isEmpty ||
          b.bookingNo.toLowerCase().contains(q) ||
          b.username.toLowerCase().contains(q) ||
          b.businessSourceName.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
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

  /// One request: the booking with its detail lines nested inside.
  /// (Needs the backend to declare bookingDetails as a list.)
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
          }
      ];
      final subtotal = vehicles.fold<double>(0, (s, v) => s + priceOf(v) * days);
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
        ...extra, // ignored by the API until the backend adds these fields
      };
      print('CREATE BOOKING body: $body');

      final res = await api.createBooking(body);
      print('CREATE BOOKING ${res.statusCode}: ${res.bodyString}');

      if (!_ok(res.statusCode)) {
        Get.snackbar('Booking failed', 'HTTP ${res.statusCode}: ${res.bodyString}',
            duration: const Duration(seconds: 8));
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

  /// Quick booking by the logged-in customer (used by the dialog).
  Future<bool> bookAsCustomer(VehicleModel v, DateTime start, DateTime end) async {
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
    // the API soft-deletes, then throws "not found": judge by reloading
    await load();
    final gone = !bookings.any((b) => b.id == id);
    Get.snackbar(gone ? 'Deleted' : 'Delete failed',
        gone ? 'Booking removed' : 'The server did not remove it');
    return gone;
  }
}