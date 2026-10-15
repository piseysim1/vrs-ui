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
  Future<Response> getVehicles() => get('/vrms/api/vehicle', query: _page);
  Future<Response> createVehicle(Map<String, dynamic> b) =>
      post('/vrms/api/vehicle', b);
  Future<Response> updateVehicle(int id, Map<String, dynamic> b) =>
      put('/vrms/api/vehicle/id', b, query: {'id': '$id'});
  Future<Response> deleteVehicle(int id) async {
    final attempts = <Future<Response> Function()>[
      () => delete('/vrms/api/vehicle/id', query: {'id': '$id'}),
      () => delete('/vrms/api/vehicle/$id'),
      () => delete('/vrms/api/vehicle', query: {'id': '$id'}),
    ];
    Response? last;
    for (var i = 0; i < attempts.length; i++) {
      final r = await attempts[i]();
      print('DELETE vehicle $id try=$i -> ${r.statusCode} ${r.bodyString}');
      last = r;
      if (r.statusCode == 200 || r.statusCode == 204) return r;
    }
    return last!;
  }
  Future<Response> getBrands() => get('/vrms/api/brand', query: _page);
  Future<Response> getModels() => get('/vrms/api/model', query: _page);
  Future<Response> createModel(Map<String, dynamic> b) =>
      post('/vrms/api/model', b);
  Future<Response> getLocations() => get('/vrms/api/location', query: _page);

  // rate
  Future<Response> getRates() => get('/vrms/api/rate', query: _page);
  Future<Response> createRate(Map<String, dynamic> b) =>
      post('/vrms/api/rate', b);
  Future<Response> updateRate(int id, Map<String, dynamic> b) =>
      put('/vrms/api/rate/id', b, query: {'id': '$id'});
  Future<List<OptionItem>> fetchLookupItems({int maxId = 30}) async {
    final responses = await Future.wait(
      List.generate(maxId, (i) => get('/vrms/api/lookupitem/${i + 1}')),
    );

    print(
      'LOOKUP sample (id 4): ${responses[3].statusCode} ${responses[3].body}',
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
