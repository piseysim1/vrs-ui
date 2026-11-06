import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/my_bookings_controller.dart';
import 'package:vrs_ui/app/core/utils/image_url.dart';
import 'package:vrs_ui/app/data/models/booking_model.dart';
import 'package:vrs_ui/app/data/models/vehicle_model.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/navbar.dart';

class MyBookingsPage extends GetView<MyBookingsController> {
  const MyBookingsPage({super.key});

  static const _primary = Color(0xFF003399);
  static const _phone = '048896522';

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const NavbarWidget(),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = controller.filtered;
        final sel = controller.selected;
        final f = controller.filter.value;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: narrow ? 16 : 32,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(f),
                  const SizedBox(height: 16),
                  _chips(),
                  const SizedBox(height: 20),
                  if (list.isEmpty)
                    _empty()
                  else
                    LayoutBuilder(
                      builder: (context, c) {
                        final left = Column(
                          children: [
                            for (final b in list)
                              _bookingCard(context, b, b.id == sel?.id),
                            if (sel != null) _docsCard(sel),
                          ],
                        );
                        final right = sel == null
                            ? const SizedBox()
                            : _reviewCard(sel);
                        if (c.maxWidth < 850) {
                          return Column(children: [left, right]);
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: left),
                            const SizedBox(width: 24),
                            SizedBox(width: 340, child: right),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _header(String f) {
    final confirmed = f == 'confirmed';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                confirmed ? 'My Bookings — Confirmed' : 'My Bookings',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                confirmed
                    ? 'Your booking is confirmed and documents are approved. Review pickup details and download the payment document.'
                    : 'Manage your reservations, documents and rental details while your booking is under review.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => Get.offAllNamed('/home'),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Book a vehicle'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chips() {
    final f = controller.filter.value;
    Widget chip(String key, String label, int n) {
      final on = f == key;
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => controller.setFilter(key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: on ? _primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: on ? _primary : Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: on ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: on ? Colors.white24 : const Color(0xFFF1F3F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$n',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: on ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        chip('all', 'All bookings', controller.allCount),
        chip('confirmed', 'Confirmed', controller.confirmedCount),
        chip('completed', 'Completed', controller.completedCount),
        chip('cancelled', 'Cancelled', controller.cancelledCount),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            controller.pendingCount > 0
                ? '${controller.allCount} booking${controller.allCount == 1 ? '' : 's'} · ${controller.pendingCount} pending'
                : '${controller.allCount} booking${controller.allCount == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _empty() => _card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 10),
            const Text(
              'No bookings here yet',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextButton(
              onPressed: () => Get.offAllNamed('/home'),
              child: const Text('Browse vehicles'),
            ),
          ],
        ),
      ),
    ),
  );

  // ---------------- booking card ----------------
  Widget _bookingCard(BuildContext context, BookingModel b, bool selected) {
    final v = controller.vehicleOf(b);
    final url = resolveImageUrl(v?.imageUrl);
    final approved = b.approval == Approval.approved;
    final pickup = v?.locationName ?? b.locationName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => controller.selectedId.value = b.id,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _primary : Colors.grey.shade200,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // reference + status
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'REFERENCE NO.  ',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      b.bookingNo,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    _statusPill(b),
                  ],
                ),
              ),
              const Divider(height: 1),

              // vehicle
              Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final img = ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: c.maxWidth < 480 ? double.infinity : 200,
                        height: 120,
                        child: url == null
                            ? _noImg()
                            : Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _noImg(),
                              ),
                      ),
                    );
                    final info = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v?.displayName ?? 'Vehicle',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          v == null ? '' : '${v.modelName} • ${v.licensePlate}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 15),
                            const SizedBox(width: 6),
                            Text(
                              '${fmtShort(b.startDate)} – ${fmtShort(b.endDate)}, ${b.endDate?.year ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 22),
                        Text(
                          'TOTAL · ${b.days} DAY${b.days > 1 ? 'S' : ''} RENTAL',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '\$${b.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    );
                    if (c.maxWidth < 480) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [img, const SizedBox(height: 12), info],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        img,
                        const SizedBox(width: 18),
                        Expanded(child: info),
                      ],
                    );
                  },
                ),
              ),

              // pickup
              Container(
                width: double.infinity,
                color: const Color(0xFFF7F8FA),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PICK-UP · ${fmtDate(b.startDate)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            pickup.isEmpty ? '—' : pickup,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // confirmed: pickup instructions + payment document
              if (approved && !b.isReturned) _pickupInfo(b, pickup),

              // actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (b.approval == Approval.pending)
                      OutlinedButton(
                        onPressed: () =>
                            Get.dialog(_ManageDialog(booking: b, vehicle: v)),
                        child: const Text('Manage booking'),
                      ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          Get.dialog(_ReceiptDialog(booking: b, vehicle: v)),
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: const Text('Payment document'),
                    ),
                    if (b.approval == Approval.pending)
                      TextButton(
                        onPressed: () => _confirmCancel(b),
                        child: const Text(
                          'Cancel booking',
                          style: TextStyle(color: Color(0xFFDC3545)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickupInfo(BookingModel b, String pickup) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pickup instructions',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Download the payment document below, then take it to the pickup location to collect your vehicle.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 16, color: _primary),
            const SizedBox(width: 6),
            Text(
              pickup.isEmpty ? '—' : pickup,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Call to verify',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.phone_outlined, size: 16, color: _primary),
            const SizedBox(width: 6),
            const Text(
              _phone,
              style: TextStyle(fontWeight: FontWeight.w700, color: _primary),
            ),
          ],
        ),
      ],
    ),
  );

  // ---------------- documents list ----------------
  Widget _docsCard(BookingModel b) {
    final docs = controller.docsOf(b);
    final approved = b.approval == Approval.approved;
    final rejected = b.approval == Approval.rejected;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Documents & verification',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${docs.length} documents attached',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            approved
                ? 'All attached documents have been approved. Download the payment document and take it to the pickup location to collect your vehicle.'
                : rejected
                ? 'This booking was not approved. Please contact support if you have questions.'
                : 'Your documents are awaiting admin review and approval. Once approved, the payment document and pickup location will become available.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 10),
          if (docs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No documents were attached to this booking',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            for (final d in docs)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.description_outlined, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            d.url.split('/').last,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _docPill(b),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => _viewDoc(d.title, d.url),
                      child: const Text(
                        'View',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: _primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.lock_outline, size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                'PNG or JPG · Max 10 MB per file · Only shared with the review team',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _docPill(BookingModel b) {
    late Color fg, bg;
    late String t;
    switch (b.approval) {
      case Approval.approved:
        fg = const Color(0xFF1E9E5A);
        bg = const Color(0xFFE6F7EE);
        t = 'Approved';
        break;
      case Approval.rejected:
        fg = const Color(0xFFDC3545);
        bg = const Color(0xFFFDECEE);
        t = 'Rejected';
        break;
      case Approval.pending:
        fg = const Color(0xFFD97706);
        bg = const Color(0xFFFFF4E0);
        t = 'Pending review';
        break;
    }
    return _pill(t, fg, bg);
  }

  void _viewDoc(String title, String path) {
    final url = resolveImageUrl(path);
    Get.dialog(
      Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: url == null
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No file'),
                      )
                    : InteractiveViewer(
                        child: Image.network(
                          url,
                          errorBuilder: (_, __, ___) => const Padding(
                            padding: EdgeInsets.all(40),
                            child: Text('Cannot display this file'),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- document review panel ----------------
  Widget _reviewCard(BookingModel b) {
    final docs = controller.docsOf(b);
    final a = b.approval;

    late Color boxFg, boxBg;
    late IconData boxIcon;
    late String boxTitle, boxText;
    late List<_Step> steps;

    if (a == Approval.approved) {
      boxFg = _primary;
      boxBg = const Color(0xFFE8EEFF);
      boxIcon = Icons.check_circle_outline;
      boxTitle = 'Documents approved';
      boxText =
          'All documents for this booking have been approved. You can now download the payment document and prepare for pickup.';
      steps = [
        _Step(
          'Reservation confirmed',
          'Your booking reference is ${b.bookingNo}.',
          _StepState.done,
        ),
        _Step(
          'Documents submitted',
          'All ${docs.length} attachments are available for review.',
          _StepState.done,
        ),
        _Step(
          'Documents approved',
          'All attached documents have been approved.',
          _StepState.warn,
        ),
      ];
    } else if (a == Approval.rejected) {
      boxFg = const Color(0xFFDC3545);
      boxBg = const Color(0xFFFDECEE);
      boxIcon = Icons.cancel_outlined;
      boxTitle = b.isCancelled ? 'Booking cancelled' : 'Booking rejected';
      boxText = b.isCancelled
          ? 'This booking was cancelled. You can book another vehicle at any time.'
          : 'The admin could not approve this booking. Please contact support for details.';
      steps = [
        _Step(
          'Booking submitted',
          'Your booking reference is ${b.bookingNo}.',
          _StepState.done,
        ),
        _Step(
          'Documents submitted',
          '${docs.length} attachments were available for review.',
          _StepState.done,
        ),
        _Step(
          b.isCancelled ? 'Cancelled' : 'Rejected',
          'No further action is needed.',
          _StepState.error,
        ),
      ];
    } else {
      boxFg = const Color(0xFFDC3545);
      boxBg = const Color(0xFFFDECEE);
      boxIcon = Icons.error_outline;
      boxTitle = 'Pending admin approval';
      boxText =
          'Admin must review your booking and attached documents before confirmation. Once approved, the payment document and pickup location will become available.';
      steps = [
        _Step(
          'Booking submitted',
          'Your booking reference is ${b.bookingNo}.',
          _StepState.done,
        ),
        _Step(
          'Documents submitted',
          'All ${docs.length} attachments are available for review.',
          _StepState.done,
        ),
        _Step(
          'Admin review in progress',
          'Approval has not yet been granted.',
          _StepState.error,
        ),
      ];
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Document review',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: boxBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(boxIcon, size: 15, color: boxFg),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        boxTitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: boxFg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  boxText,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final s in steps) _stepTile(s),
          const SizedBox(height: 6),
          Text(
            a == Approval.approved
                ? 'Pickup instructions and verification contact are ready below.'
                : 'Check your notifications and registered email for review updates.',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _stepTile(_Step s) {
    late Color c;
    late IconData i;
    switch (s.state) {
      case _StepState.done:
        c = const Color(0xFF1E9E5A);
        i = Icons.check_circle_outline;
        break;
      case _StepState.warn:
        c = const Color(0xFFD97706);
        i = Icons.schedule;
        break;
      case _StepState.error:
        c = const Color(0xFFDC3545);
        i = Icons.access_time;
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: c.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(i, size: 16, color: c),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  s.text,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- small helpers ----------------
  Widget _statusPill(BookingModel b) {
    if (b.approval == Approval.rejected) {
      return _pill(
        b.isCancelled ? 'Cancelled' : 'Rejected',
        const Color(0xFFDC3545),
        const Color(0xFFFDECEE),
      );
    }
    if (b.isReturned)
      return _pill('Completed', Colors.grey.shade700, const Color(0xFFF1F3F7));
    if (b.approval == Approval.approved) {
      return _pill('Confirmed', _primary, const Color(0xFFE8EEFF));
    }
    return _pill('Pending', const Color(0xFFDC3545), const Color(0xFFFDECEE));
  }

  Widget _pill(String t, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      t,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
    ),
  );

  Widget _noImg() => Container(
    color: const Color(0xFFF1F3F7),
    child: const Center(
      child: Icon(Icons.directions_car, size: 36, color: Colors.grey),
    ),
  );

  Widget _card({required Widget child, EdgeInsets? padding}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: child,
  );

  void _confirmCancel(BookingModel b) {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text(
          'Booking ${b.bookingNo} will be cancelled. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Keep booking')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.cancel(b);
            },
            child: const Text(
              'Cancel booking',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

enum _StepState { done, warn, error }

class _Step {
  final String title, text;
  final _StepState state;
  _Step(this.title, this.text, this.state);
}

// ======================================================================
//  Manage booking: summary of what was booked
// ======================================================================
class _ManageDialog extends StatelessWidget {
  final BookingModel booking;
  final VehicleModel? vehicle;
  const _ManageDialog({required this.booking, this.vehicle});

  @override
  Widget build(BuildContext context) {
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Booking ${booking.bookingNo}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              row('Vehicle', vehicle?.displayName ?? '—'),
              row('Pick-up', fmtDate(booking.startDate)),
              row('Return', fmtDate(booking.endDate)),
              row(
                'Duration',
                '${booking.days} day${booking.days > 1 ? 's' : ''}',
              ),
              row('Total', '\$${booking.total.toStringAsFixed(2)}'),
              const SizedBox(height: 10),
              Text(
                'To change dates or vehicle, cancel this booking and create a new one while it is still pending.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================================
//  Payment document (receipt)
// ======================================================================
class _ReceiptDialog extends StatelessWidget {
  final BookingModel booking;
  final VehicleModel? vehicle;
  const _ReceiptDialog({required this.booking, this.vehicle});

  @override
  Widget build(BuildContext context) {
    final approved = booking.approval == Approval.approved;
    final tax = booking.total - booking.total / 1.10;

    Widget row(String k, String v, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          Text(
            v,
            style: TextStyle(
              fontSize: bold ? 18 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Payment document',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              row('Reference', booking.bookingNo),
              row('Customer', booking.username),
              row('Vehicle', vehicle?.displayName ?? '—'),
              row(
                'Rental',
                '${fmtShort(booking.startDate)} – ${fmtShort(booking.endDate)}',
              ),
              row(
                'Payment',
                booking.paymentMethodName.isEmpty
                    ? '—'
                    : booking.paymentMethodName,
              ),
              const Divider(),
              row('Taxes & fees (10%)', '\$${tax.toStringAsFixed(2)}'),
              row(
                'Total due',
                '\$${booking.total.toStringAsFixed(2)}',
                bold: true,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: approved
                      ? const Color(0xFFE6F7EE)
                      : const Color(0xFFFFF4E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  approved
                      ? 'Approved. Show this document at the pickup location.'
                      : 'Not valid until the booking is approved by admin.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: approved
                        ? const Color(0xFF1E9E5A)
                        : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
