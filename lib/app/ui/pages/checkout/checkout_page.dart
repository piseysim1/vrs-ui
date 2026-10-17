import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vrs_ui/app/controllers/checkout_controller.dart';
import 'package:vrs_ui/app/core/utils/image_url.dart';
import 'package:vrs_ui/app/data/models/booking_model.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/navbar_widget.dart';

class CheckoutPage extends GetView<CheckoutController> {
  const CheckoutPage({super.key});

  static const _primary = Color(0xFF003399);

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 650;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const NavbarWidget(),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final v = controller.vehicle.value;
        if (v == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Vehicle not found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => Get.offAllNamed('/home'),
                  child: const Text('Back to home'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.all(narrow ? 16 : 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: Get.back,
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const Text(
                          'Checkout',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, c) {
                        final wide = c.maxWidth >= 900;
                        final left = Column(
                          children: [
                            _vehicleCard(),
                            const SizedBox(height: 16),
                            _rentalCard(context),
                            const SizedBox(height: 16),
                            _paymentCard(),
                          ],
                        );
                        if (!wide) {
                          return Column(
                            children: [
                              left,
                              const SizedBox(height: 16),
                              _summaryCard(context),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 62, child: left),
                            const SizedBox(width: 24),
                            Expanded(flex: 38, child: _summaryCard(context)),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ---------------- vehicle ----------------
  Widget _vehicleCard() {
    final v = controller.vehicle.value!;
    final url = resolveImageUrl(v.imageUrl);
    return _card(
      child: LayoutBuilder(
        builder: (context, c) {
          final img = ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: c.maxWidth < 500 ? double.infinity : 200,
              height: 140,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      v.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _tag(v.brandName),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                v.modelName,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  _spec(Icons.palette_outlined, v.colorName),
                  _spec(Icons.place_outlined, v.locationName),
                  _spec(Icons.confirmation_number_outlined, v.licensePlate),
                ],
              ),
            ],
          );
          if (c.maxWidth < 500) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [img, const SizedBox(height: 14), info],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              img,
              const SizedBox(width: 20),
              Expanded(child: info),
            ],
          );
        },
      ),
    );
  }

  Widget _noImg() => Container(
    color: const Color(0xFFF1F3F7),
    child: const Center(
      child: Icon(Icons.directions_car, size: 40, color: Colors.grey),
    ),
  );

  Widget _tag(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(t, style: TextStyle(fontSize: 11, color: Colors.blue.shade900)),
  );

  Widget _spec(IconData i, String t) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(i, size: 16, color: Colors.grey.shade700),
      const SizedBox(width: 6),
      Text(t.isEmpty ? '-' : t, style: const TextStyle(fontSize: 13)),
    ],
  );

  // ---------------- rental period ----------------
  Widget _rentalCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(Icons.calendar_month_outlined, 'Rental Period & Location'),
          const SizedBox(height: 16),
          _fieldLabel('Pick-up & Return Location'),
          Obx(() {
            final sel = controller.locationId.value;
            final items = controller.locations;
            return DropdownButtonFormField<int>(
              value: items.any((e) => e.id == sel) ? sel : null,
              isExpanded: true,
              decoration: _dec(prefix: Icons.place_outlined),
              items: items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(e.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) => controller.locationId.value = v,
            );
          }),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final a = _dateTime(
                context,
                'Pick-up Date & Time',
                controller.start,
              );
              final b = _dateTime(
                context,
                'Return Date & Time',
                controller.end,
              );
              if (c.maxWidth < 520) {
                return Column(children: [a, const SizedBox(height: 14), b]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: a),
                  const SizedBox(width: 16),
                  Expanded(child: b),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dateTime(BuildContext context, String label, Rx<DateTime> value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        Obx(() {
          final d = value.value;
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: _pickBox(fmtDate(d), () async {
                  final r = await showDatePicker(
                    context: context,
                    initialDate: d,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (r != null) {
                    value.value = DateTime(
                      r.year,
                      r.month,
                      r.day,
                      d.hour,
                      d.minute,
                    );
                  }
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _pickBox(
                  TimeOfDay.fromDateTime(d).format(context),
                  () async {
                    final r = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(d),
                    );
                    if (r != null) {
                      value.value = DateTime(
                        d.year,
                        d.month,
                        d.day,
                        r.hour,
                        r.minute,
                      );
                    }
                  },
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _pickBox(String text, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    ),
  );

  // ---------------- payment ----------------
  Widget _paymentCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(Icons.credit_card_outlined, 'Payment Method'),
          const SizedBox(height: 14),
          Obx(() {
            final sel = controller.paymentId.value;
            return Column(
              children: [
                for (final m in controller.methods)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => controller.paymentId.value = m.id,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: sel == m.id
                              ? const Color(0xFFE8EEFF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel == m.id
                                ? _primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              sel == m.id
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 20,
                              color: sel == m.id ? _primary : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                m.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            _logo(m.imageLogo),
                          ],
                        ),
                      ),
                    ),
                  ),
                _qrBox(),
              ],
            );
          }),
          const Divider(height: 28),
          _uploadField(
            'vehicleDoc',
            'Vehicle verification document',
            'PNG or JPG · Max 10 MB · Admin review and approval required',
          ),
          _uploadField('idCard', 'Khmer Identity Card', 'Attachment card here'),
          _uploadField(
            'paymentProof',
            'Payment method verification',
            'Upload QR statement',
          ),
          _uploadField(
            'registration',
            'Vehicle registration',
            'Upload registration',
          ),
        ],
      ),
    );
  }

  Widget _logo(String? path) {
    final url = resolveImageUrl(path);
    if (url == null) {
      return Icon(
        Icons.account_balance_wallet_outlined,
        size: 18,
        color: Colors.grey.shade700,
      );
    }
    return Image.network(
      url,
      width: 26,
      height: 26,
      errorBuilder: (_, __, ___) => Icon(
        Icons.account_balance_wallet_outlined,
        size: 18,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _qrBox() {
    final url = resolveImageUrl(controller.selectedMethod?.qrImage);
    if (url == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            'Scan to pay with ${controller.selectedMethod!.name}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Image.network(
            url,
            width: 180,
            height: 180,
            errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2, size: 80),
          ),
        ],
      ),
    );
  }

  Widget _uploadField(String key, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          Obx(() {
            final doc = controller.docs[key];
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final f = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );
                if (f == null) return;
                final bytes = await f.readAsBytes();
                if (bytes.length > 10 * 1024 * 1024) {
                  Get.snackbar('File too large', 'Maximum size is 10 MB');
                  return;
                }
                controller.docs[key] = PickedDoc(f.name, bytes);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        doc?.name ?? hint,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: doc == null
                              ? Colors.grey.shade600
                              : Colors.black87,
                        ),
                      ),
                    ),
                    if (doc != null)
                      InkWell(
                        onTap: () => controller.docs.remove(key),
                        child: const Icon(Icons.close, size: 18),
                      )
                    else
                      const Icon(Icons.upload_outlined, size: 18),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _summaryCard(BuildContext context) {
    return _card(
      padding: EdgeInsets.zero,
      child: Obx(() {
        controller.start.value;
        controller.end.value;
        final days = controller.days;
        final rate = controller.dailyRate;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price Summary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '$days Day${days > 1 ? 's' : ''} Rental',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _line(
                    'Daily Rate (\$${rate.toStringAsFixed(0)} × $days)',
                    '\$${controller.subtotal.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),
                  _line(
                    'Taxes & Fees (10%)',
                    '\$${controller.tax.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFFF7F8FA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Due',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Includes all taxes and fees',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '\$${controller.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.saving.value
                          ? null
                          : () async {
                              final ok = await controller.submit();
                              if (ok) Get.offAllNamed('/home');
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: controller.saving.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Booking',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'By confirming, you agree to our Rental Terms & Conditions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _line(String a, String b) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(a, style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
      Text(
        b,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ],
  );

  // ---------------- helpers ----------------
  Widget _card({required Widget child, EdgeInsets? padding}) => Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: child,
  );

  Widget _title(IconData i, String t) => Row(
    children: [
      Icon(i, size: 20, color: _primary),
      const SizedBox(width: 8),
      Text(
        t,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ],
  );

  Widget _fieldLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
  );

  InputDecoration _dec({IconData? prefix}) => InputDecoration(
    filled: true,
    fillColor: const Color(0xFFF7F8FA),
    isDense: true,
    prefixIcon: prefix == null ? null : Icon(prefix, size: 18),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
  );
}
