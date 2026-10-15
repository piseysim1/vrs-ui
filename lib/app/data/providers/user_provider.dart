import 'package:get/get.dart';

class UserProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = 'https://latest-dev.vbsxr.com';
    httpClient.timeout = const Duration(seconds: 20);
    super.onInit();
  }

  Future<Response> getUsers(String token) => get(
    '/vrms/api/user',
    query: {'pageIndex': '1', 'pageSize': '100'},
    headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
  );
}
