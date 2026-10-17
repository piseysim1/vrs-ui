class PaymentMethodModel {
  final int id;
  final String name;
  final String note;
  final String? qrImage;
  final String? imageLogo;
  final int ordering;

  const PaymentMethodModel({
    required this.id,
    required this.name,
    this.note = '',
    this.qrImage,
    this.imageLogo,
    this.ordering = 0,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> j) =>
      PaymentMethodModel(
        id: j['id'] ?? 0,
        name: (j['name'] ?? '').toString(),
        note: (j['note'] ?? '').toString(),
        qrImage: j['qrImage']?.toString(),
        imageLogo: j['imageLogo']?.toString(),
        ordering: j['ordering'] ?? 0,
      );
}