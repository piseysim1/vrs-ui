import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class CustomerProvider extends GetConnect {
  final box = GetStorage();

  CustomerProvider() {
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

  Future<Response> getUsers() => get('/vrms/api/user', query: _page);

  // POST /vrms/api/user
  // body: username, fullName, phone, email, profile, roleId, password
  Future<Response> createUser(Map<String, dynamic> body) =>
      post('/vrms/api/user', body);

  // PUT /vrms/api/user/id?id=...
  Future<Response> updateUser(int id, Map<String, dynamic> body) =>
      put('/vrms/api/user/id', body, query: {'id': '$id'});

  // Tries the same URL shapes as the vehicle/brand deletes until one works.
  Future<Response> deleteUser(int id) async {
    final attempts = <Future<Response> Function()>[
      () => delete('/vrms/api/user/id', query: {'id': '$id'}),
      () => delete('/vrms/api/user/$id'),
      () => delete('/vrms/api/user', query: {'id': '$id'}),
    ];
    Response? last;
    for (var i = 0; i < attempts.length; i++) {
      final r = await attempts[i]();
      print('DELETE user $id try=$i -> ${r.statusCode} ${r.bodyString}');
      last = r;
      if (r.statusCode == 200 || r.statusCode == 204) return r;
    }
    return last!;
  }
}