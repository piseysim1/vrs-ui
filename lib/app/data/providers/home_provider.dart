import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class HomeProvider extends GetConnect {
  final box = GetStorage();

  HomeProvider() {
    httpClient.baseUrl = 'https://latest-dev.vbsxr.com';
    httpClient.timeout = const Duration(seconds: 20);

    httpClient.addRequestModifier<dynamic>((request) {
      final token = box.read('token');
      if (token != null && token.toString().isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';
      return request;
    });
  }

  Future<Response> getBrands() {
    return get('/vrms/api/brand', query: {'pageIndex': '1', 'pageSize': '25'});
  }

  Future<Response> getVehicles() =>
      get('/vrms/api/vehicle', query: {'pageIndex': '1', 'pageSize': '25'});
  Future<Response> getRates() =>
      get('/vrms/api/rate', query: {'pageIndex': '1', 'pageSize': '100'});
}
