import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class BrandProvider extends GetConnect {
  final box = GetStorage();

  BrandProvider() {
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

  Future<Response> getBrands() => get('/vrms/api/brand', query: _page);

  Future<Response> createBrand(Map<String, dynamic> body) =>
      post('/vrms/api/brand', body);

  Future<Response> updateBrand(int id, Map<String, dynamic> body) =>
      put('/vrms/api/brand/id', body, query: {'id': '$id'});

  // Same endpoint shapes as the vehicle delete: tries each until one works.
  Future<Response> deleteBrand(int id) async {
    final attempts = <Future<Response> Function()>[
      () => delete('/vrms/api/brand/id', query: {'id': '$id'}),
      () => delete('/vrms/api/brand/$id'),
      () => delete('/vrms/api/brand', query: {'id': '$id'}),
    ];
    Response? last;
    for (var i = 0; i < attempts.length; i++) {
      final r = await attempts[i]();
      print('DELETE brand $id try=$i -> ${r.statusCode} ${r.bodyString}');
      last = r;
      if (r.statusCode == 200 || r.statusCode == 204) return r;
    }
    return last!;
  }
}
