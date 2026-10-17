class CustomerModel {
  final int? id;
  final String username;
  final String fullName;
  final String phone;
  final String email;
  final String? profile;
  final int? roleId;

  const CustomerModel({
    this.id,
    required this.username,
    required this.fullName,
    this.phone = '',
    this.email = '',
    this.profile,
    this.roleId,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> j) => CustomerModel(
    id: (j['id'] as num?)?.toInt(),
    username: (j['username'] ?? '').toString(),
    fullName: (j['fullName'] ?? '').toString(),
    phone: (j['phone'] ?? '').toString(),
    email: (j['email'] ?? '').toString(),
    profile: j['profile']?.toString(),
    roleId: (j['roleId'] as num?)?.toInt(),
  );
}