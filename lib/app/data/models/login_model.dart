class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  Map toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class LoginResponse {
  final String? token;
  final String? message;

  LoginResponse({this.token, this.message});

  factory LoginResponse.fromJson(Map json) {
    return LoginResponse(
      token: json['token'] ?? json['result']?['token'],
      message: json['message'],
    );
  }
}