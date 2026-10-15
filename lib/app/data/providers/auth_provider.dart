import 'package:get/get.dart';

class AuthProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = 'https://latest-dev.vbsxr.com';
    super.onInit();
  }
  Future registerUser(Map data) async{
    return await post('/vrms/api/auth/register', data);
  }
  Future LoginUser(Map data) async{
    return await post('/vrms/api/auth/login', data);
  }
}
