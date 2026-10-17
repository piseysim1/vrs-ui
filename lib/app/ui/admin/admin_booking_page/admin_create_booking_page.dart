import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vrs_ui/app/controllers/admin_controller.dart';
import 'package:vrs_ui/app/controllers/booking_controller.dart';
import 'package:vrs_ui/app/core/utils/image_url.dart';
import 'package:vrs_ui/app/data/models/booking_model.dart';
import 'package:vrs_ui/app/data/models/payment_method_model.dart';
import 'package:vrs_ui/app/data/models/vehicle_model.dart';
import 'package:vrs_ui/app/data/providers/admin_provider.dart';
import 'package:vrs_ui/app/data/providers/file_provider.dart';

class AdminCreateBookingPage extends StatefulWidget {
  const AdminCreateBookingPage({super.key});

  @override
  State<AdminCreateBookingPage> createState() => _AdminCreateBookingPageState();
}

class _AdminCreateBookingPageState extends State<AdminCreateBookingPage> {
  static const _primary = Color(0xFF003399);
  static const _tax = 0.0;

  final api = AdminProvider();
  final ac = Get.find<AdminController>();
  final bc = Get.find<BookingController>();

  // customer
  bool existing = true;
  List<Map<String, dynamic>> users = [];
  Map<String, dynamic>? customer;
  final _search = TextEditingController();
  final _nFull = TextEditingController();
  final _nUser = TextEditingController();
  final _nPass = TextEditingController();
  final _nPhone = TextEditingController();
  final _nEmail = TextEditingController();

  final docs = <String, ({String name, Uint8List bytes})>{};

  // vehicle
  VehicleModel? vehicle;

  // schedule + payment
  DateTime start = DateTime.now().add(const Duration(hours: 2));
  DateTime end = DateTime.now().add(const Duration(days: 3));
  int? pickupId, returnId, paymentId;
  bool sameReturn = true;
  List<PaymentMethodModel> methods = [];
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_search, _nFull, _nUser, _nPass, _nPhone, _nEmail]) {
      c.dispose();
    }
    super.dispose();
  }

  List _list(dynamic d) {
    if (d is List) return d;
    if (d is Map) {
      for (final k in const ['results', 'Results', 'items', 'data']) {
        if (d[k] is List) return d[k];
      }
    }
    return [];
  }

  Future<void> _load() async {
    final res = await Future.wait([api.getUsers(), api.getPaymentMethods()]);
    if (res[0].statusCode == 200) {
      users = _list(
        res[0].body,
      ).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (res[1].statusCode == 200) {
      methods =
          _list(res[1].body)
              .map(
                (e) =>
                    PaymentMethodModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
            ..sort((a, b) => a.ordering.compareTo(b.ordering));
      if (methods.isNotEmpty) paymentId = methods.first.id;
    }
    if (ac.locations.isNotEmpty) pickupId = ac.locations.first.id;
    if (mounted) setState(() {});
  }

  // ---------- price ----------
  int get days {
    final h = end.difference(start).inHours;
    return h <= 24 ? 1 : (h / 24).ceil();
  }

  double get rate => vehicle?.dayPrice ?? vehicle?.price ?? 0;
  double get total => rate * days * (1 + _tax);
  Future<void> _pickDoc(String key) async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    setState(() => docs[key] = (name: f.name, bytes: bytes));
  }

  Future<void> _createCustomer() async {
    if (_nFull.text.trim().isEmpty ||
        _nUser.text.trim().isEmpty ||
        _nPass.text.isEmpty) {
      Get.snackbar('Customer', 'Full name, username and password are required');
      return;
    }
    final r = await api.registerUser({
      'fullName': _nFull.text.trim(),
      'username': _nUser.text.trim(),
      'password': _nPass.text,
      'phone': _nPhone.text.trim(),
      'email': _nEmail.text.trim(),
    });
    print('REGISTER ${r.statusCode}: ${r.bodyString}');
    if (r.statusCode != 200 && r.statusCode != 201) {
      Get.snackbar('Register failed', 'HTTP ${r.statusCode}: ${r.bodyString}');
      return;
    }
    final u = await api.getUsers();
    if (u.statusCode == 200) {
      users = _list(u.body).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    customer = users.firstWhereOrNull(
      (x) =>
          '${x['username']}'.toLowerCase() == _nUser.text.trim().toLowerCase(),
    );
    setState(() => existing = true);
  }

  Future<void> _submit() async {
    if (customer == null) {
      Get.snackbar('Customer', 'Please select or create a customer');
      return;
    }
    if (vehicle == null) {
      Get.snackbar('Vehicle', 'Please select a vehicle');
      return;
    }
    if (!end.isAfter(start)) {
      Get.snackbar('Dates', 'Return must be after pick-up');
      return;
    }
    setState(() => saving = true);
    try {
      final urls = <String, String>{};
      final files = FileProvider();
      for (final e in docs.entries) {
        final u = await files.uploadImage(e.value.bytes, e.value.name);
        if (u == null) {
          Get.snackbar('Upload failed', e.value.name);
          return;
        }
        urls[e.key] = u;
      }
      final landing = bc.sources.firstWhereOrNull(
        (s) => s.name.toLowerCase().contains('walk'),
      );

      final ok = await bc.createBooking(
        userId: customer!['id'],
        sourceId: landing?.id,
        start: start,
        end: end,
        vehicles: [vehicle!],
        taxRate: _tax,
        extra: {
          'locationId': pickupId,
          'returnLocationId': sameReturn ? pickupId : returnId,
          'paymentMethodId': paymentId,
          'identityCardUrl': urls['idCard'],
          'vehicleDocumentUrl': urls['vehicleDoc'],
          'vehicleRegistrationUrl': urls['registration'],
        },
      );
      if (ok && mounted) Get.back();
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'DriveBlue',
          style: TextStyle(color: _primary, fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Create New Booking',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEFF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Draft #${bc.bookings.length + 1}',
                        style: const TextStyle(fontSize: 11, color: _primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _customerCard(),
                const SizedBox(height: 16),
                _vehicleCard(),
                const SizedBox(height: 16),
                _scheduleCard(),
                const SizedBox(height: 16),
                _footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----- customer -----
  Widget _customerCard() => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.person_outline, color: _primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Customer Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            _toggle(),
          ],
        ),
        const SizedBox(height: 14),
        if (existing) _existingCustomer() else _newCustomer(),
        const SizedBox(height: 16),
        const Divider(),
        const Text(
          'Identity & Vehicle Verification Documents',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _docTile('idCard', 'Khmer Identity Card'),
            _docTile('vehicleDoc', 'Vehicle Verification Doc'),
            _docTile('registration', 'Vehicle Registration'),
          ],
        ),
      ],
    ),
  );

  Widget _toggle() => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F3F7),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _seg(
          'Existing Customer',
          existing,
          () => setState(() => existing = true),
        ),
        _seg('+ Add New', !existing, () => setState(() => existing = false)),
      ],
    ),
  );

  Widget _seg(String t, bool on, VoidCallback f) => InkWell(
    onTap: f,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: on ? Colors.white : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        t,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: on ? Colors.black : Colors.grey.shade600,
        ),
      ),
    ),
  );

  Widget _existingCustomer() {
    if (customer != null) {
      final name = '${customer!['fullName'] ?? customer!['username']}';
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _primary,
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${customer!['email'] ?? ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  Text(
                    '${customer!['phone'] ?? ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                customer = null;
                _search.clear();
              }),
              child: const Text('Switch Client'),
            ),
          ],
        ),
      );
    }
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (u) => '${u['fullName'] ?? u['username']}',
      optionsBuilder: (v) {
        final q = v.text.trim().toLowerCase();
        return users.where(
          (u) =>
              q.isEmpty ||
              '${u['fullName']}'.toLowerCase().contains(q) ||
              '${u['username']}'.toLowerCase().contains(q) ||
              '${u['phone']}'.contains(q),
        );
      },
      onSelected: (u) => setState(() => customer = u),
      fieldViewBuilder: (context, c, f, _) => TextField(
        controller: c,
        focusNode: f,
        decoration: _dec(
          'Search client account (name, username, phone)',
          icon: Icons.search,
        ),
      ),
    );
  }

  Widget _newCustomer() => Column(
    children: [
      Row(
        children: [
          Expanded(child: _tf(_nFull, 'Full name')),
          const SizedBox(width: 12),
          Expanded(child: _tf(_nUser, 'Username')),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: _tf(_nPhone, 'Phone')),
          const SizedBox(width: 12),
          Expanded(child: _tf(_nEmail, 'Email')),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: _tf(_nPass, 'Password', obscure: true)),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _createCustomer,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            ),
            child: const Text('Create customer'),
          ),
        ],
      ),
    ],
  );

  Widget _docTile(String key, String label) {
    final d = docs[key];
    return InkWell(
      onTap: () => _pickDoc(key),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 290,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              d == null
                  ? Icons.upload_file_outlined
                  : Icons.description_outlined,
              size: 18,
              color: _primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    d?.name ?? 'Tap to attach',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (d != null)
              const Text(
                'Attached',
                style: TextStyle(
                  color: Color(0xFF1E9E5A),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ----- vehicle -----
  Widget _vehicleCard() => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.directions_car_outlined, color: _primary),
            SizedBox(width: 8),
            Text(
              'Vehicle Selection',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Select an available vehicle from inventory.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 14),
        Obx(() {
          final list = ac.vehicles
              .where((v) => statusKindOf(v.statusName) == StatusKind.available)
              .toList();
          if (list.isEmpty) return const Text('No available vehicles');
          return Column(children: [for (final v in list) _vehicleTile(v)]);
        }),
      ],
    ),
  );

  Widget _vehicleTile(VehicleModel v) {
    final on = vehicle?.id == v.id;
    final url = resolveImageUrl(v.imageUrl);
    final price = v.dayPrice ?? v.price ?? 0;
    return InkWell(
      onTap: () => setState(() => vehicle = v),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: on ? _primary : Colors.grey.shade300,
            width: on ? 2 : 1,
          ),
          color: on ? const Color(0xFFF5F8FF) : Colors.white,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 120,
                height: 80,
                child: url == null
                    ? Container(
                        color: const Color(0xFFF1F3F7),
                        child: const Icon(Icons.directions_car),
                      )
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF1F3F7),
                          child: const Icon(Icons.directions_car),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Plate: ${v.licensePlate}  •  ${v.colorName}  •  ${v.locationName}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  Text(
                    v.statusName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1E9E5A),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price > 0 ? '\$${price.toStringAsFixed(0)} /day' : '—',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ----- schedule + payment -----
  Widget _scheduleCard() => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.calendar_month_outlined, color: _primary),
            SizedBox(width: 8),
            Text(
              'Rental Schedule & Payment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, c) {
            final pick = _panel('PICKUP', [
              _dtField('Date & Time', start, (d) => setState(() => start = d)),
              _locDd(
                'Pickup Facility',
                pickupId,
                (v) => setState(() => pickupId = v),
              ),
              _payDd(),
            ]);
            final ret = _panel('RETURN  •  $days day${days > 1 ? 's' : ''}', [
              _dtField('Date & Time', end, (d) => setState(() => end = d)),
              CheckboxListTile(
                value: sameReturn,
                onChanged: (v) => setState(() => sameReturn = v ?? true),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Same as pickup',
                  style: TextStyle(fontSize: 12),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (!sameReturn)
                _locDd(
                  'Return Facility',
                  returnId,
                  (v) => setState(() => returnId = v),
                ),
            ]);
            if (c.maxWidth < 700) {
              return Column(children: [pick, const SizedBox(height: 12), ret]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: pick),
                const SizedBox(width: 16),
                Expanded(child: ret),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _panel(String title, List<Widget> kids) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFAFBFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _primary,
          ),
        ),
        const SizedBox(height: 10),
        for (final k in kids) ...[k, const SizedBox(height: 10)],
      ],
    ),
  );

  Widget _dtField(String label, DateTime v, ValueChanged<DateTime> on) =>
      InkWell(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: v,
            firstDate: DateTime.now().subtract(const Duration(days: 1)),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (d == null || !mounted) return;
          final t = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(v),
          );
          if (t == null) return;
          on(DateTime(d.year, d.month, d.day, t.hour, t.minute));
        },
        child: InputDecorator(
          decoration: _dec(label, icon: Icons.event),
          child: Text(
            '${fmtDate(v)} • ${TimeOfDay.fromDateTime(v).format(context)}',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      );

  Widget _locDd(String label, int? value, ValueChanged<int?> on) {
    final items = ac.locations;
    return DropdownButtonFormField<int>(
      value: items.any((e) => e.id == value) ? value : null,
      isExpanded: true,
      decoration: _dec(label, icon: Icons.place_outlined),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e.id,
              child: Text(e.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: on,
    );
  }

  Widget _payDd() => DropdownButtonFormField<int>(
    value: methods.any((m) => m.id == paymentId) ? paymentId : null,
    isExpanded: true,
    decoration: _dec('Payment Method', icon: Icons.credit_card_outlined),
    items: methods
        .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
        .toList(),
    onChanged: (v) => setState(() => paymentId = v),
  );

  // ----- footer -----
  Widget _footer() => _card(
    Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total  •  $days day${days > 1 ? 's' : ''} × \$${rate.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _primary,
                ),
              ),
            ],
          ),
        ),
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: saving ? null : _submit,
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check, size: 18),
          label: const Text('Create booking'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    ),
  );

  // ----- helpers -----
  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: child,
  );

  Widget _tf(TextEditingController c, String label, {bool obscure = false}) =>
      TextField(controller: c, obscureText: obscure, decoration: _dec(label));

  InputDecoration _dec(String label, {IconData? icon}) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFF7F8FA),
    isDense: true,
    prefixIcon: icon == null ? null : Icon(icon, size: 18),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
  );
}
