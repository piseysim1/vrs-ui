import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/booking_controller.dart';
import 'package:vrs_ui/app/data/models/booking_model.dart';
import 'package:vrs_ui/app/ui/admin/admin_booking_page/admin_create_booking_page.dart';

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
          // _sourceCard(),
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
        'Active now',
        '${controller.activeCount}',
        Colors.amber.shade800,
      ),
      _stat(
        Icons.schedule,
        const Color(0xFF2563EB),
        'Upcoming',
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

  // Widget _sourceCard() => Obx(() {
  //   final data = controller.bySource;
  //   if (data.isEmpty) return const SizedBox.shrink();
  //   final max = data.values.reduce((a, b) => a > b ? a : b);
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(18),
  //     decoration: _box(),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           'Bookings by source',
  //           style: TextStyle(fontWeight: FontWeight.w700),
  //         ),
  //         const SizedBox(height: 12),
  //         for (final e in data.entries)
  //           Padding(
  //             padding: const EdgeInsets.only(bottom: 8),
  //             child: Row(
  //               children: [
  //                 SizedBox(
  //                   width: 130,
  //                   child: Text(
  //                     e.key,
  //                     overflow: TextOverflow.ellipsis,
  //                     style: const TextStyle(fontSize: 12),
  //                   ),
  //                 ),
  //                 Expanded(
  //                   child: ClipRRect(
  //                     borderRadius: BorderRadius.circular(6),
  //                     child: LinearProgressIndicator(
  //                       value: e.value / max,
  //                       minHeight: 10,
  //                       backgroundColor: const Color(0xFFEEF0F4),
  //                       color: _primary,
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 10),
  //                 Text(
  //                   '${e.value}',
  //                   style: const TextStyle(fontWeight: FontWeight.w700),
  //                 ),
  //               ],
  //             ),
  //           ),
  //       ],
  //     ),
  //   );
  // });

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
              chip('upcoming', 'Upcoming (${controller.upcomingCount})'),
              chip('active', 'Active (${controller.activeCount})'),
              chip('completed', 'Completed (${controller.completedCount})'),
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
            constraints: const BoxConstraints(minWidth: 980),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F8FA)),
              headingTextStyle: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: Colors.grey.shade600,
              ),
              dataRowMinHeight: 58,
              dataRowMaxHeight: 58,
              columns: const [
                DataColumn(label: Text('BOOKING NO')),
                DataColumn(label: Text('CUSTOMER')),
                DataColumn(label: Text('SOURCE')),
                DataColumn(label: Text('START')),
                DataColumn(label: Text('END')),
                DataColumn(label: Text('TOTAL')),
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

  DataRow _row(BookingModel b) => DataRow(
    cells: [
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0FF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            b.bookingNo,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      DataCell(
        Text(
          b.username,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      DataCell(
        Text(
          b.businessSourceName.isEmpty ? '—' : b.businessSourceName,
          style: const TextStyle(fontSize: 12),
        ),
      ),
      DataCell(
        Text(fmtDate(b.startDate), style: const TextStyle(fontSize: 12)),
      ),
      DataCell(Text(fmtDate(b.endDate), style: const TextStyle(fontSize: 12))),
      DataCell(
        Text(
          '\$${b.total.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
      DataCell(_statePill(b.state)),
      DataCell(
        Row(
          children: [
            // TextButton.icon(
            //   onPressed: () => Get.to(() => const AdminCreateBookingPage()),
            //   icon: const Icon(Icons.visibility_outlined, size: 15),
            //   label: const Text('View'),
            //   style: TextButton.styleFrom(foregroundColor: _primary),
            // ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red,
              ),
              onPressed: () => _confirmDelete(b),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _statePill(BookingState s) {
    late Color fg, bg;
    late String t;
    switch (s) {
      case BookingState.upcoming:
        fg = const Color(0xFF2563EB);
        bg = const Color(0xFFE8F0FE);
        t = 'UPCOMING';
        break;
      case BookingState.active:
        fg = const Color(0xFFD97706);
        bg = const Color(0xFFFFF4E0);
        t = 'ACTIVE';
        break;
      case BookingState.completed:
        fg = const Color(0xFF1E9E5A);
        bg = const Color(0xFFE6F7EE);
        t = 'COMPLETED';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: fg),
          const SizedBox(width: 5),
          Text(
            t,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
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
