class LocationModel {
  final int? id;
  final String code;
  final String name;
  final String note;

  const LocationModel({
    this.id,
    required this.code,
    required this.name,
    this.note = '',
  });

  factory LocationModel.fromJson(Map<String, dynamic> j) => LocationModel(
    id: (j['id'] as num?)?.toInt(),
    code: (j['code'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    note: (j['note'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'code': code,
    'name': name,
    'note': note,
  };
}
