import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/data/models/booking_model.dart';

enum BookingAction { approve, reject, complete }

class ConfirmActionDialog extends StatelessWidget {
  final BookingModel booking;
  final BookingAction action;
  final String? carName;
  final Future<void> Function() onConfirm;

  const ConfirmActionDialog({
    super.key,
    required this.booking,
    required this.action,
    required this.onConfirm,
    this.carName,
  });

  @override
  Widget build(BuildContext context) {
    late Color color, soft;
    late IconData icon;
    late String title, text, button;

    switch (action) {
      case BookingAction.approve:
        color = const Color(0xFF1E9E5A); soft = const Color(0xFFE6F7EE);
        icon = Icons.check_circle_rounded;
        title = 'Approve this booking?';
        text = 'The booking will be confirmed and the car will be set to Rented.';
        button = 'Approve booking';
        break;
      case BookingAction.reject:
        color = const Color(0xFFDC3545); soft = const Color(0xFFFDECEE);
        icon = Icons.cancel_rounded;
        title = 'Reject this booking?';
        text = 'The customer’s request will be declined. The car stays available.';
        button = 'Reject booking';
        break;
      case BookingAction.complete:
        color = const Color(0xFF003399); soft = const Color(0xFFE8EEFF);
        icon = Icons.assignment_turned_in_rounded;
        title = 'Mark car as returned?';
        text = 'The booking will be completed and the car will be set back to Available.';
        button = 'Confirm return';
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 34),
            ),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(children: [
                _row('Booking', '#${booking.bookingNo}'),
                _row('Customer', booking.username),
                if (carName != null) _row('Vehicle', carName!),
                _row('Dates', '${fmtShort(booking.startDate)} – ${fmtShort(booking.endDate)}'),
                _row('Total', '\$${booking.total.toStringAsFixed(2)}', bold: true),
              ]),
            ),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: Get.back,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(button, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(
              width: 80,
              child: Text(k, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          Expanded(
            child: Text(v,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
          ),
        ]),
      );
}