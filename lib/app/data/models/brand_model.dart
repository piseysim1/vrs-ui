class BrandModel {
  final int? id;
  final String code;
  final String name;
  final String? note;

  BrandModel({this.id, required this.code, required this.name, this.note});

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'],
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      note: json['note'],
    );
  }
}
