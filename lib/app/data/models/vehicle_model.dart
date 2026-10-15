class VehicleRate {
  final int? rateTypeId;
  final String rateTypeName;
  final double price;

  VehicleRate({this.rateTypeId, required this.rateTypeName, required this.price});

  factory VehicleRate.fromJson(Map<String, dynamic> j) => VehicleRate(
        rateTypeId: j['rateTypeId'],
        rateTypeName: (j['rateTypeName'] ?? '').toString(),
        price: (j['price'] as num?)?.toDouble() ?? 0,
      );
}

class VehicleModel {
  final int? id;
  final String licensePlate;
  final int? brandId;
  final String brandName;
  final int? modelId;
  final String modelName;
  final int? locationId;
  final String locationName;
  final int? colorId;
  final String colorName;
  final int? statusId;
  final String statusName;
  final int? rateId;
  final String? imageUrl;
  final List<VehicleRate> rates;

  // kept so the home page keeps working (it sets these itself)
  double? price;
  String? rateTypeName;

  VehicleModel({
    this.id,
    required this.licensePlate,
    this.brandId,
    required this.brandName,
    this.modelId,
    required this.modelName,
    this.locationId,
    required this.locationName,
    this.colorId,
    required this.colorName,
    this.statusId,
    required this.statusName,
    this.rateId,
    this.imageUrl,
    this.rates = const [],
    this.price,
    this.rateTypeName,
  });

  String get displayName => '$brandName $modelName'.trim();

  // lookup item ids: 1 = Daily, 2 = Hourly
  double? get dayPrice => _priceOf(1);
  double? get hourPrice => _priceOf(2);

  double? _priceOf(int typeId) {
    for (final r in rates) {
      if (r.rateTypeId == typeId) return r.price;
    }
    return null;
  }

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    final rates = (json['rates'] is List)
        ? (json['rates'] as List)
            .whereType<Map>()
            .map((e) => VehicleRate.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <VehicleRate>[];

    final v = VehicleModel(
      id: json['id'],
      licensePlate: json['licensePlate'] ?? '',
      brandId: json['brandId'],
      brandName: json['brandName'] ?? '',
      modelId: json['modelId'],
      modelName: json['modelName'] ?? '',
      locationId: json['locationId'],
      locationName: json['locationName'] ?? '',
      colorId: json['colorId'],
      colorName: json['colorName'] ?? '',
      statusId: json['statusId'],
      statusName: json['statusName'] ?? '',
      rateId: json['rateId'],
      imageUrl: json['imageUrl'],
      rates: rates,
    );
    final first = v.dayPrice != null
        ? rates.firstWhere((r) => r.rateTypeId == 1)
        : (rates.isNotEmpty ? rates.first : null);
    v.price = first?.price;
    v.rateTypeName = first?.rateTypeName;
    return v;
  }
}