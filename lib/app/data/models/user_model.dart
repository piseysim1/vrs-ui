class RegisterModel {
  final String fullName;
  final String email;
  final String phone;
  final String password;


  RegisterModel({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phone,
      'password': password,
    };
  }
  factory RegisterModel.fromJson(Map<String, dynamic> json) {
    return RegisterModel(
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phoneNumber'] ?? '',
      password: '',
    );
  }
}