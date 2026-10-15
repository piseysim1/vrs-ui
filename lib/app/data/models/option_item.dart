class OptionItem {
  final int id;
  final String name;
  final String code;
  final int? parentId;
  final int? typeId;

  const OptionItem({
    required this.id,
    required this.name,
    this.code = '',
    this.parentId,
    this.typeId,
  });

  factory OptionItem.fromJson(Map<String, dynamic> json) {
    final en = (json['nameEn'] ?? '').toString().trim();
    return OptionItem(
      id: json['id'] ?? 0,
      // English name first (the Khmer "name" is the fallback)
      name: en.isNotEmpty
          ? en
          : (json['name'] ?? json['code'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      parentId: json['brandId'],
      typeId: int.tryParse(
        '${json['lookUpTypeId'] ?? json['lookupTypeId'] ?? ''}',
      ),
    );
  }
}
