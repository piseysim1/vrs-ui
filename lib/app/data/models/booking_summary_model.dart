/// What the "Booking Confirmed" page shows after a successful checkout.
class BookingSummary {
  final String reference;
  final String vehicleName;
  final String brandName;
  final String? imageUrl;
  final String locationName;
  final DateTime start;
  final DateTime end;
  final double total;

  const BookingSummary({
    required this.reference,
    required this.vehicleName,
    required this.brandName,
    required this.imageUrl,
    required this.locationName,
    required this.start,
    required this.end,
    required this.total,
  });
}