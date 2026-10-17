enum BookingState { upcoming, active, completed }

DateTime? _d(dynamic v) => v == null ? null : DateTime.tryParse('$v');

class BookingModel {
  final int? id;
  final String bookingNo;
  final int? userId;
  final String username;
  final int? businessSourceId;
  final String businessSourceName;
  final DateTime? startDate;
  final DateTime? endDate;
  final double total;

  BookingModel({
    this.id,
    required this.bookingNo,
    this.userId,
    required this.username,
    this.businessSourceId,
    required this.businessSourceName,
    this.startDate,
    this.endDate,
    required this.total,
  });

  factory BookingModel.fromJson(Map<String, dynamic> j) => BookingModel(
        id: j['id'],
        bookingNo: (j['bookingNo'] ?? '').toString(),
        userId: j['userId'],
        username: (j['username'] ?? '').toString(),
        businessSourceId: j['businessSourceId'],
        businessSourceName: (j['businessSourceName'] ?? '').toString(),
        startDate: _d(j['startDate']),
        endDate: _d(j['endDate']),
        total: (j['total'] as num?)?.toDouble() ?? 0,
      );

  int get days {
    if (startDate == null || endDate == null) return 1;
    final d = endDate!.difference(startDate!).inDays;
    return d < 1 ? 1 : d;
  }

  BookingState get state {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (startDate != null && today.isBefore(startDate!)) return BookingState.upcoming;
    if (endDate != null && today.isAfter(endDate!)) return BookingState.completed;
    return BookingState.active;
  }
}

class BookingDetailModel {
  final int? id;
  final int? bookingId;
  final int? vehicleId;
  final String description;
  final double qty;
  final double unitPrice;
  final double subTotal;

  BookingDetailModel({
    this.id,
    this.bookingId,
    this.vehicleId,
    this.description = '',
    this.qty = 1,
    this.unitPrice = 0,
    this.subTotal = 0,
  });

  factory BookingDetailModel.fromJson(Map<String, dynamic> j) =>
      BookingDetailModel(
        id: j['id'],
        bookingId: j['bookingId'],
        vehicleId: j['vehicleId'],
        description: (j['description'] ?? '').toString(),
        qty: (j['qty'] as num?)?.toDouble() ?? 1,
        unitPrice: (j['unitPrice'] as num?)?.toDouble() ?? 0,
        subTotal: (j['subTotal'] as num?)?.toDouble() ?? 0,
      );
}

String fmtDate(DateTime? d) => d == null
    ? '-'
    : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';