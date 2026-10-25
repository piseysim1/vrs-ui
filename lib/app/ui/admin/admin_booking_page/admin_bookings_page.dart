import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/booking_controller.dart';
import 'package:vrs_ui/app/data/models/booking_model.dart';
import 'package:vrs_ui/app/ui/admin/admin_booking_page/admin_create_booking_page.dart';
import 'package:vrs_ui/app/ui/admin/admin_booking_page/booking_view_dialog.dart';
import 'package:vrs_ui/app/ui/admin/admin_booking_page/confirm_action_dialog.dart';

class AdminBookingsPage extends GetView<BookingController> {
  const AdminBookingsPage({super.key});

  static const _primary = Color(0xFF003399);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bookings',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: controller.load,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: () => Get.dialog(const AdminCreateBookingPage()),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Booking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _stats(),
          const SizedBox(height: 16),
          _listCard(),
        ],
      ),
    );
  }

  // ---------------- dashboard ----------------
  Widget _stats() => Obx(() {
    final cards = [
      _stat(
        Icons.event_note_outlined,
        Colors.blueGrey,
        'Total bookings',
        '${controller.totalCount}',
        null,
      ),
      _stat(
        Icons.payments_outlined,
        Colors.green,
        'Revenue',
        '\$${controller.revenue.toStringAsFixed(2)}',
        Colors.green,
      ),
      _stat(
        Icons.directions_car,
        Colors.amber.shade800,
        'Active now (cars out)',
        '${controller.activeCount}',
        Colors.amber.shade800,
      ),
      _stat(
        Icons.schedule,
        const Color(0xFF2563EB),
        'Confirmed (upcoming)',
        '${controller.upcomingCount}',
        const Color(0xFF2563EB),
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 12.0;
        final cols = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 500 ? 2 : 1);
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final x in cards) SizedBox(width: w, child: x)],
        );
      },
    );
  });

  Widget _stat(
    IconData icon,
    Color color,
    String label,
    String value,
    Color? valueColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _box(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- list ----------------
  Widget _listCard() => Container(
    decoration: _box(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_filterBar(), const Divider(height: 1), _table()],
    ),
  );

  Widget _filterBar() => Padding(
    padding: const EdgeInsets.all(14),
    child: Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Obx(() {
          final f = controller.filter.value;
          Widget chip(String key, String text) =>
              _chip(text, f == key, () => controller.setFilter(key));
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip('all', 'All (${controller.totalCount})'),
              chip('pending', 'Pending (${controller.pendingCount})'),
              chip('approved', 'Approved (${controller.approvedCount})'),
              chip('rejected', 'Rejected (${controller.rejectedCount})'),
            ],
          );
        }),
        SizedBox(
          width: 260,
          child: TextField(
            onChanged: controller.setSearch,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search booking no, customer...',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _chip(String text, bool sel, VoidCallback onTap) => InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: sel ? const Color(0xFF111827) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: sel ? Colors.white : Colors.grey.shade700,
        ),
      ),
    ),
  );

  Widget _table() => Obx(() {
    if (controller.isLoading.value) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final items = controller.pageItems;
    if (controller.filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Center(child: Text('No bookings found')),
      );
    }
    final pageNo = controller.page.value;
    final count = controller.pageCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1100),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F8FA)),
              headingTextStyle: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: Colors.grey.shade600,
              ),
              dataRowMinHeight: 78,
              dataRowMaxHeight: 78,
              columns: const [
                DataColumn(label: Text('BOOKING ID')),
                DataColumn(label: Text('CUSTOMER')),
                DataColumn(label: Text('ASSIGNED VEHICLE')),
                DataColumn(label: Text('RENTAL DATES')),
                DataColumn(label: Text('AMOUNT')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: items.map(_row).toList(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${controller.filtered.length} bookings',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: pageNo > 0
                        ? () => controller.page.value--
                        : null,
                    child: const Text('Previous'),
                  ),
                  Text('${pageNo + 1} / $count'),
                  TextButton(
                    onPressed: pageNo < count - 1
                        ? () => controller.page.value++
                        : null,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  });

  DataRow _row(BookingModel b) {
    final cars = controller.vehiclesOf(b);
    final car = cars.isEmpty ? null : cars.first;
    final email = controller.emailOf(b.userId);

    String overdueText() {
      final d = DateTime.now().difference(b.endDate!);
      return d.inDays >= 1 ? 'Overdue ${d.inDays}d' : 'Overdue ${d.inHours}h';
    }

    return DataRow(
      cells: [
        DataCell(
          Text(
            '#${b.bookingNo}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),

        // customer
        DataCell(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                b.username,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
            ],
          ),
        ),

        // vehicle
        DataCell(
          car == null
              ? Text('—', style: TextStyle(color: Colors.grey.shade500))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          car.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            car.brandName,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        if (cars.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(
                              '+${cars.length - 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      car.licensePlate,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
        ),

        // dates
        DataCell(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${fmtShort(b.startDate)} – ${fmtShort(b.endDate)}, ${b.endDate?.year ?? ''}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${b.days} day${b.days > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              if (b.isOverdue && b.endDate != null)
                Text(
                  overdueText(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFD97706),
                  ),
                ),
            ],
          ),
        ),

        DataCell(
          Text(
            '\$${b.total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),

        DataCell(_statusPill(b)),

        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Get.dialog(BookingViewDialog(booking: b)),
                child: const Text('View'),
              ),
              if (b.approval == Approval.pending) ...[
                _actionBtn(
                  'Approve',
                  const Color(0xFF1E9E5A),
                  () => _confirmStatus(b, 'Approved'),
                ),
                _actionBtn(
                  'Reject',
                  const Color(0xFFDC3545),
                  () => _confirmStatus(b, 'Rejected'),
                ),
              ],
              if (b.approval == Approval.approved && !b.isReturned)
                _actionBtn(
                  'Return',
                  _primary,
                  () => _confirmStatus(b, 'Completed'),
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, size: 18),
                onSelected: (v) {
                  if (v == 'delete') _confirmDelete(b);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(String t, Color c, VoidCallback f) => TextButton(
    onPressed: f,
    child: Text(
      t,
      style: TextStyle(color: c, fontWeight: FontWeight.w700),
    ),
  );

  Widget _statusPill(BookingModel b) {
    late Color fg, bg;
    late String t;
    if (b.approval == Approval.rejected) {
      fg = const Color(0xFFDC3545);
      bg = const Color(0xFFFDECEE);
      t = 'Rejected';
    } else if (b.approval == Approval.pending) {
      fg = const Color(0xFFD97706);
      bg = const Color(0xFFFFF4E0);
      t = 'Pending';
    } else if (b.isReturned) {
      fg = Colors.grey.shade700;
      bg = const Color(0xFFF1F3F7);
      t = 'Completed';
    } else if (b.isOverdue) {
      fg = const Color(0xFFB45309);
      bg = const Color(0xFFFEF3C7);
      t = 'Pending Return';
    } else if (b.isRunning) {
      fg = const Color(0xFF1E9E5A);
      bg = const Color(0xFFE6F7EE);
      t = 'Active';
    } else {
      fg = const Color(0xFF2563EB);
      bg = const Color(0xFFE8F0FE);
      t = 'Confirmed';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        t,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  void _confirmStatus(BookingModel b, String name) {
    final cars = controller.vehiclesOf(b);
    Get.dialog(
      ConfirmActionDialog(
        booking: b,
        carName: cars.isEmpty
            ? null
            : '${cars.first.displayName} (${cars.first.licensePlate})',
        action: name == 'Approved'
            ? BookingAction.approve
            : name == 'Rejected'
            ? BookingAction.reject
            : BookingAction.complete,
        onConfirm: () => controller.setStatus(b, name),
      ),
    );
  }

  void _confirmDelete(BookingModel b) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete booking?'),
        content: Text('${b.bookingNo} (${b.username}) will be removed.'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.removeBooking(b.id!);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.grey.shade200),
  );
}
