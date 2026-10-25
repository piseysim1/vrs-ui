import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/admin_controller.dart';
import 'package:vrs_ui/app/controllers/booking_controller.dart';
import 'package:vrs_ui/app/core/utils/image_url.dart';
import 'package:vrs_ui/app/data/models/booking_model.dart';
import 'package:vrs_ui/app/ui/admin/admin_booking_page/booking_actions.dart';

class BookingViewDialog extends StatefulWidget {
  final BookingModel booking;
  const BookingViewDialog({super.key, required this.booking});

  @override
  State<BookingViewDialog> createState() => _BookingViewDialogState();
}

class _BookingViewDialogState extends State<BookingViewDialog> {
  static const _primary = Color(0xFF003399);
  final bc = Get.find<BookingController>();
  BookingModel? full;
  bool loading = true;
  bool busy = false;

  BookingModel get b => full ?? widget.booking;

  String get _customer {
    if (b.username.isNotEmpty) return b.username;
    return b.userId != null ? 'Customer #${b.userId}' : '—';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final f = await bc.fetchOne(widget.booking.id!);
      if (!mounted) return;
      if (f != null) setState(() => full = f.mergedWith(widget.booking));
    } catch (e) {
      debugPrint('BOOKING VIEW load failed: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _vehicle(BookingDetailModel d) {
    if (d.description.isNotEmpty) return d.description;
    if (Get.isRegistered<AdminController>()) {
      final v = Get.find<AdminController>().vehicles.firstWhereOrNull(
        (x) => x.id == d.vehicleId,
      );
      if (v != null) return '${v.displayName} (${v.licensePlate})';
    }
    return 'Vehicle #${d.vehicleId}';
  }

  Future<void> _set(String name) async {
    if (busy) return;
    setState(() => busy = true);
    final ok = await applyBookingStatus(bc, b, name);
    if (!mounted) return;
    setState(() => busy = false);
    if (ok) Navigator.of(context).pop();
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final lines = b.lines.isNotEmpty ? b.lines : bc.linesOf(b.id);
    final docs = <String, String?>{
      'Khmer ID Card': b.identityCardUrl,
      'Vehicle Verification': b.vehicleDocumentUrl,
      'Payment Proof': b.paymentProofUrl,
      'Vehicle Registration': b.vehicleRegistrationUrl,
    };

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFFF8FAFC),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking ${b.bookingNo}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Details and verification status',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _pill(b.approval),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _close,
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            if (loading)
              const LinearProgressIndicator(
                backgroundColor: Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(_primary),
                minHeight: 2,
              ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer & Rental Row (Side-by-Side in Card Format)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 480;
                        return isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildCustomerCard()),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildRentalCard()),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildCustomerCard(),
                                  const SizedBox(height: 12),
                                  _buildRentalCard(),
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Vehicles Section
                    _buildSectionHeader(Icons.directions_car_outlined, 'VEHICLES'),
                    const SizedBox(height: 8),
                    _buildCardWrapper(
                      child: lines.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                loading ? 'Loading vehicles...' : 'No vehicle items found',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: lines.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              itemBuilder: (context, index) {
                                final d = lines[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _vehicle(d),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${d.qty.toStringAsFixed(0)} × \$${d.unitPrice.toStringAsFixed(2)} = ',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        '\$${d.subTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Documents Section
                    _buildSectionHeader(Icons.folder_open_outlined, 'DOCUMENTS'),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 160,
                        mainAxisExtent: 120,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final entry = docs.entries.elementAt(index);
                        return _buildDocTile(entry.key, entry.value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Total Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Includes taxes & fees',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '\$${b.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: _primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: busy ? null : _close,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                  if (b.approval == Approval.pending) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: busy ? null : () => _set('Rejected'),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        backgroundColor: const Color(0xFFFEF2F2),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: busy ? null : () => _set('Approved'),
                      icon: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return _buildCardWrapper(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.person_outline, 'CUSTOMER'),
            const SizedBox(height: 10),
            _infoRow('Name', _customer),
            const SizedBox(height: 6),
            _infoRow('Source', b.businessSourceName.isEmpty ? '—' : b.businessSourceName),
          ],
        ),
      ),
    );
  }

  Widget _buildRentalCard() {
    return _buildCardWrapper(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.calendar_today_outlined, 'RENTAL PERIOD'),
            const SizedBox(height: 10),
            _infoRow('Pick-up', fmtDate(b.startDate)),
            const SizedBox(height: 6),
            _infoRow('Return', fmtDate(b.endDate)),
            const SizedBox(height: 6),
            _infoRow('Duration', '${b.days} day${b.days > 1 ? 's' : ''}'),
          ],
        ),
      ),
    );
  }

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocTile(String label, String? path) {
    final url = resolveImageUrl(path);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: InkWell(
              onTap: url == null
                  ? null
                  : () => Get.dialog(
                        Dialog(child: InteractiveViewer(child: Image.network(url))),
                      ),
              borderRadius: BorderRadius.circular(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF1F5F9),
                  child: url == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.insert_drive_file_outlined, size: 20, color: Colors.grey.shade400),
                            const SizedBox(height: 2),
                            Text(
                              'Not provided',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                            ),
                          ],
                        )
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined, color: Colors.grey),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(Approval a) {
    late Color fg, bg, border;
    late String t;
    switch (a) {
      case Approval.pending:
        fg = const Color(0xFFD97706);
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFDE68A);
        t = 'PENDING';
        break;
      case Approval.approved:
        fg = const Color(0xFF16A34A);
        bg = const Color(0xFFF0FDF4);
        border = const Color(0xFFBBF7D0);
        t = 'APPROVED';
        break;
      case Approval.rejected:
        fg = const Color(0xFFDC2626);
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFECACA);
        t = 'REJECTED';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Text(
        t,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}