import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LocationProvider extends GetConnect {
  final box = GetStorage();

  LocationProvider() {
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

  Future<Response> getLocations() => get('/vrms/api/location', query: _page);

  Future<Response> createLocation(Map<String, dynamic> body) =>
      post('/vrms/api/location', body);

  Future<Response> updateLocation(int id, Map<String, dynamic> body) =>
      put('/vrms/api/location/id', body, query: {'id': '$id'});

  // Same endpoint shapes as the vehicle delete: tries each until one works.
  Future<Response> deleteLocation(int id) async {
    final attempts = <Future<Response> Function()>[
      () => delete('/vrms/api/location/id', query: {'id': '$id'}),
      () => delete('/vrms/api/location/$id'),
      () => delete('/vrms/api/location', query: {'id': '$id'}),
    ];
    Response? last;
    for (var i = 0; i < attempts.length; i++) {
      final r = await attempts[i]();
      print('DELETE location $id try=$i -> ${r.statusCode} ${r.bodyString}');
      last = r;
      if (r.statusCode == 200 || r.statusCode == 204) return r;
    }
    return last!;
  }
}