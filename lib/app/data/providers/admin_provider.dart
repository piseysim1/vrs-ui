import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vrs_ui/app/data/models/option_item.dart';

class AdminProvider extends GetConnect {
  final box = GetStorage();

  AdminProvider() {
    httpClient.baseUrl = 'https://latest-dev.vbsxr.com';
    httpClient.timeout = const Duration(seconds: 30);
    httpClient.addRequestModifier<dynamic>((request) {
      final token = box.read('token');
      if (token != null && token.toString().isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';
      return request;
    });
  }

  static const _page = {'pageIndex': '1', 'pageSize': '100'};

  // ---------- vehicle ----------
  Future<Response> getVehicles() => get('/vrms/api/vehicle', query: _page);
  Future<Response> createVehicle(Map<String, dynamic> b) =>
      post('/vrms/api/vehicle', b);
  Future<Response> updateVehicle(int id, Map<String, dynamic> b) =>
      put('/vrms/api/vehicle/id', b, query: {'id': '$id'});

  Future<Response> deleteVehicle(int id) => _deleteById('vehicle', id);

  // ---------- brand / model / location ----------
  Future<Response> getBrands() => get('/vrms/api/brand', query: _page);
  Future<Response> getModels() => get('/vrms/api/model', query: _page);
  Future<Response> createModel(Map<String, dynamic> b) =>
      post('/vrms/api/model', b);
  Future<Response> getLocations() => get('/vrms/api/location', query: _page);
  Future<Response> getPaymentMethods() =>
      get('/vrms/api/paymentmethod', query: _page);

  // body guessed: username, password, fullName, phone, email
  Future<Response> registerUser(Map<String, dynamic> b) =>
      post('/vrms/api/auth/register', b);
  // ---------- rate ----------
  Future<Response> getRates() => get('/vrms/api/rate', query: _page);
  Future<Response> createRate(Map<String, dynamic> b) =>
      post('/vrms/api/rate', b);
  Future<Response> updateRate(int id, Map<String, dynamic> b) =>
      put('/vrms/api/rate/id', b, query: {'id': '$id'});
  // ---------- bookings ----------
  Future<Response> getBookings() => get('/vrms/api/booking', query: _page);
  Future<Response> createBooking(Map<String, dynamic> b) =>
      post('/vrms/api/booking', b);
  Future<Response> getBookingDetails() =>
      get('/vrms/api/bookingdetail', query: _page);
  Future<Response> createBookingDetail(Map<String, dynamic> b) =>
      post('/vrms/api/bookingdetail', b);
  Future<Response> getUsers() => get('/vrms/api/user', query: _page);

  Future<Response> deleteBooking(int id) => _deleteById('booking', id);
  Future<Response> deleteBookingDetail(int id) =>
      _deleteById('bookingdetail', id);

  /// Tries the two route shapes your Swagger may use.
  Future<Response> _deleteById(String name, int id) async {
    final attempts = <Future<Response> Function()>[
      () => delete('/vrms/api/$name/id', query: {'id': '$id'}),
      () => delete('/vrms/api/$name/$id'),
    ];
    Response? last;
    for (final a in attempts) {
      last = await a();
      print('DELETE $name $id -> ${last.statusCode} ${last.bodyString}');
      if (last.statusCode == 200 || last.statusCode == 204) return last;
    }
    return last!;
  }

  Future<Response> changeBookingStatus(int id, int statusId) =>
      put('/vrms/api/booking/status', {'id': id, 'statusId': statusId});

  Future<Response> getBooking(int id) async {
    final r = await get('/vrms/api/booking/id', query: {'id': '$id'});
    if (r.statusCode == 200) return r;
    return get('/vrms/api/booking/$id');
  }

  Future<Response> updateUser(int id, Map<String, dynamic> b) =>
      put('/vrms/api/user/id', b, query: {'id': '$id'});
  // ---------- lookup items ----------
  /// There is no "list lookup items" endpoint, only GET /lookupitem/{id}.
  Future<List<OptionItem>> fetchLookupItems({int maxId = 30}) async {
    final responses = await Future.wait(
      List.generate(maxId, (i) => get('/vrms/api/lookupitem/${i + 1}')),
    );

    final out = <OptionItem>[];
    for (final r in responses) {
      if (r.statusCode != 200) continue;
      final m = _unwrap(r.body);
      if (m != null) out.add(OptionItem.fromJson(m));
    }
    print('LOOKUP items loaded from API: ${out.length}');
    return out;
  }

  Map<String, dynamic>? _unwrap(dynamic b) {
    if (b is! Map) return null;
    if (b.containsKey('id')) return Map<String, dynamic>.from(b);
    for (final k in const ['result', 'results', 'data']) {
      final v = b[k];
      if (v is Map) return Map<String, dynamic>.from(v);
      if (v is List && v.isNotEmpty && v.first is Map) {
        return Map<String, dynamic>.from(v.first);
      }
    }
    return null;
  }
}
