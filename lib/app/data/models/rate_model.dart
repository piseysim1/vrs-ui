class RateModel {
  final int? id;
  final int? modelId;
  final String modelName;
  final int? rateTypeId;
  final String rateTypeName;
  final String? rateTypeImage;
  final String code;
  final double price;

  RateModel({
    this.id,
    this.modelId,
    required this.modelName,
    this.rateTypeId,
    required this.rateTypeName,
    this.rateTypeImage,
    required this.code,
    required this.price,
  });

  factory RateModel.fromJson(Map<String, dynamic> json) {
    return RateModel(
      id: json['id'],
      modelId: json['modelId'],
      modelName: json['modelName'] ?? '',
      rateTypeId: json['rateTypeId'],
      rateTypeName: json['rateTypeName'] ?? '',
      rateTypeImage: json['rateTypeImage'],
      code: json['code'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}