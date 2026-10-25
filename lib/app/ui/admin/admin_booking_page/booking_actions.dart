import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/admin_controller.dart';
import 'package:vrs_ui/app/controllers/booking_controller.dart';
import 'package:vrs_ui/app/data/models/booking_model.dart';
import 'package:vrs_ui/app/data/providers/admin_provider.dart';

// LookUpItems: 4 = Available, 5 = Unavailable, 6 = Rented
const kRentedStatusId = 6;

/// Changes the booking status and, when it is Approved, marks every vehicle
/// on the booking as Rented so the fleet and the dashboard stay in sync.
Future<bool> applyBookingStatus(
  BookingController bc,
  BookingModel b,
  String name,
) async {
  final ok = await bc.setStatus(b, name);
  if (ok && name == 'Approved') await markVehiclesRented(bc, b);
  return ok;
}

Future<void> markVehiclesRented(BookingController bc, BookingModel b) async {
  if (!Get.isRegistered<AdminController>()) return;
  final ac = Get.find<AdminController>();

  var lines = b.lines.isNotEmpty ? b.lines : bc.linesOf(b.id);
  if (lines.isEmpty && b.id != null) {
    final full = await bc.fetchOne(b.id!);
    lines = full?.lines ?? [];
  }

  final api = AdminProvider();
  for (final d in lines) {
    final v = ac.vehicles.firstWhereOrNull((x) => x.id == d.vehicleId);
    if (v == null || v.id == null) continue;

    final res = await api.updateVehicle(v.id!, {
      'id': v.id,
      'licensePlate': v.licensePlate,
      'brandId': v.brandId,
      'modelId': v.modelId,
      'locationId': v.locationId,
      'colorId': v.colorId ?? 0,
      'statusId': kRentedStatusId,
      'imageUrl': v.imageUrl,
    });
    print('VEHICLE ${v.id} -> Rented: ${res.statusCode} ${res.bodyString}');
  }

  await ac.loadAll(); // refreshes the Vehicle page and the dashboard
}

/// Confirm dialog for Approve / Reject. Uses Navigator so an open
/// snackbar can't swallow the close.
void confirmBookingStatus(BookingController c, BookingModel b, String name) {
  Get.dialog(
    Builder(
      builder: (ctx) => AlertDialog(
        title: Text('$name booking?'),
        content: Text(
          '${b.bookingNo} for ${b.username} will be marked as $name.'
          '${name == 'Approved' ? '\nThe vehicle will be set to Rented.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              applyBookingStatus(c, b, name);
            },
            child: Text(name == 'Approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    ),
  );
}

void confirmBookingDelete(BookingController c, BookingModel b) {
  Get.dialog(
    Builder(
      builder: (ctx) => AlertDialog(
        title: const Text('Delete booking?'),
        content: Text('${b.bookingNo} (${b.username}) will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (b.id != null) c.removeBooking(b.id!);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ),
  );
}