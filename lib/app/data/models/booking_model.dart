enum BookingState { upcoming, active, completed }

enum Approval { pending, approved, rejected }

/// Server dates are UTC: convert to local time so comparisons are correct.
DateTime? _d(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

int? _i(dynamic v) => (v as num?)?.toInt();

double _n(dynamic v) => (v as num?)?.toDouble() ?? 0;

const _mon = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Oct 22
String fmtShort(DateTime? d) =>
    d == null ? '-' : '${_mon[d.month - 1]} ${d.day}';

/// 18 Oct 2026
String fmtDate(DateTime? d) {
  if (d == null) return '—';
  return '${d.day.toString().padLeft(2, '0')} ${_mon[d.month - 1]} ${d.year}';
}

/// One row of the booking-detail endpoint
/// { id, bookingId, vehicleId, description, qty, unitPrice, subTotal }
class BookingDetailModel {
  final int? id;
  final int? bookingId;
  final int? vehicleId;
  final String description;
  final double qty;
  final double unitPrice;
  final double subTotal;

  const BookingDetailModel({
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
        id: _i(j['id']),
        bookingId: _i(j['bookingId']),
        vehicleId: _i(j['vehicleId']),
        description: (j['description'] ?? '').toString(),
        qty: _n(j['qty']),
        unitPrice: _n(j['unitPrice']),
        subTotal: _n(j['subTotal']),
      );
}

class BookingModel {
  final int? id;
  final String bookingNo;
  final int? userId;
  final String username;
  final int? businessSourceId;
  final String businessSourceName;
  final int? locationId;
  final String locationName;
  final DateTime? startDate;
  final DateTime? endDate;
  final double total;
  final int? statusId;
  final String statusName;
  final int? paymentMethodId;
  final String paymentMethodName;
  final String? identityCardUrl;
  final String? vehicleDocumentUrl;
  final String? paymentProofUrl;
  final String? vehicleRegistrationUrl;

  /// Filled from the single-booking endpoint (the list does not include lines).
  final List<BookingDetailModel> lines;

  BookingModel({
    this.id,
    required this.bookingNo,
    this.userId,
    required this.username,
    this.businessSourceId,
    this.businessSourceName = '',
    this.locationId,
    this.locationName = '',
    this.startDate,
    this.endDate,
    required this.total,
    this.statusId,
    this.statusName = '',
    this.paymentMethodId,
    this.paymentMethodName = '',
    this.identityCardUrl,
    this.vehicleDocumentUrl,
    this.paymentProofUrl,
    this.vehicleRegistrationUrl,
    this.lines = const [],
  });

  factory BookingModel.fromJson(Map<String, dynamic> j) => BookingModel(
    id: _i(j['id']),
    bookingNo: (j['bookingNo'] ?? '').toString(),
    userId: _i(j['userId']),
    username: (j['username'] ?? '').toString(),
    businessSourceId: _i(j['businessSourceId']),
    businessSourceName: (j['businessSourceName'] ?? '').toString(),
    locationId: _i(j['locationId']),
    locationName: (j['locationName'] ?? '').toString(),
    startDate: _d(j['startDate']),
    endDate: _d(j['endDate']),
    total: _n(j['total']),
    statusId: _i(j['statusId']),
    statusName: (j['statusName'] ?? '').toString(),
    paymentMethodId: _i(j['paymentMethodId']),
    paymentMethodName: (j['paymentMethodName'] ?? '').toString(),
    identityCardUrl: j['identityCardUrl']?.toString(),
    vehicleDocumentUrl: j['vehicleDocumentUrl']?.toString(),
    paymentProofUrl: j['paymentProofUrl']?.toString(),
    vehicleRegistrationUrl: j['vehicleRegistrationUrl']?.toString(),
    lines: (j['bookingDetails'] is List)
        ? (j['bookingDetails'] as List)
              .whereType<Map>()
              .map(
                (e) =>
                    BookingDetailModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : const [],
  );

  // ---------------- approval ----------------
  Approval get approval {
    final s = statusName.toLowerCase();
    if (s.contains('reject') || s.contains('cancel')) return Approval.rejected;
    if (s.contains('approv') || s.contains('complet')) return Approval.approved;
    
    if (s.contains('approv') || s.contains('complet')) return Approval.approved;
    if (s.contains('reject')) return Approval.rejected;
    return Approval.pending;
  }

  /// The car has been brought back (status "Completed")
  bool get isReturned => statusName.toLowerCase().contains('complet');
  bool get isCancelled => statusName.toLowerCase().contains('cancel');
  // ---------------- time-based state ----------------
  /// Compares the real time (not only the date).
  BookingState get state {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) {
      return BookingState.upcoming;
    }
    if (endDate != null && now.isAfter(endDate!)) {
      return BookingState.completed;
    }
    return BookingState.active;
  }

  /// approved, not returned, rental period running now
  bool get isRunning =>
      approval == Approval.approved &&
      !isReturned &&
      state == BookingState.active;

  /// approved, not returned, end time already passed
  bool get isOverdue =>
      approval == Approval.approved &&
      !isReturned &&
      state == BookingState.completed;

  /// the car is with the customer (running or overdue)
  bool get isOut => isRunning || isOverdue;

  /// up to 24h = 1 day, otherwise round up (70h -> 3 days)
  int get days {
    if (startDate == null || endDate == null) return 1;
    final h = endDate!.difference(startDate!).inHours;
    return h <= 24 ? 1 : (h / 24).ceil();
  }

  /// Fields of this one (usually the single-booking response) win;
  /// anything empty falls back to [base] (usually the row from the list).
  BookingModel mergedWith(BookingModel base) => BookingModel(
    id: id ?? base.id,
    bookingNo: bookingNo.isNotEmpty ? bookingNo : base.bookingNo,
    userId: userId ?? base.userId,
    username: username.isNotEmpty ? username : base.username,
    businessSourceId: businessSourceId ?? base.businessSourceId,
    businessSourceName: businessSourceName.isNotEmpty
        ? businessSourceName
        : base.businessSourceName,
    locationId: locationId ?? base.locationId,
    locationName: locationName.isNotEmpty ? locationName : base.locationName,
    startDate: startDate ?? base.startDate,
    endDate: endDate ?? base.endDate,
    total: total != 0 ? total : base.total,
    statusId: statusId ?? base.statusId,
    statusName: statusName.isNotEmpty ? statusName : base.statusName,
    paymentMethodId: paymentMethodId ?? base.paymentMethodId,
    paymentMethodName: paymentMethodName.isNotEmpty
        ? paymentMethodName
        : base.paymentMethodName,
    identityCardUrl: identityCardUrl ?? base.identityCardUrl,
    vehicleDocumentUrl: vehicleDocumentUrl ?? base.vehicleDocumentUrl,
    paymentProofUrl: paymentProofUrl ?? base.paymentProofUrl,
    vehicleRegistrationUrl:
        vehicleRegistrationUrl ?? base.vehicleRegistrationUrl,
    lines: lines.isNotEmpty ? lines : base.lines,
  );
}
