import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/admin_controller.dart'
    show StatusKind, statusKindOf;
import 'package:vrs_ui/app/controllers/home_controller.dart';
import 'package:vrs_ui/app/core/utils/auth_service.dart';
import 'package:vrs_ui/app/core/utils/image_url.dart';
import 'package:vrs_ui/app/data/models/option_item.dart';
import 'package:vrs_ui/app/data/models/vehicle_model.dart';
import 'package:vrs_ui/app/data/providers/admin_provider.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/navbar.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/navbar_widget.dart';

const _primary = Color(0xFF003399);
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);

Color? _hex(String? s) {
  if (s == null) return null;
  var h = s.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return (h.length == 8 && v != null) ? Color(v) : null;
}

class VehicleDetailPage extends StatefulWidget {
  /// Optional: lets another screen open a specific car without a route param.
  final int? vehicleId;
  const VehicleDetailPage({super.key, this.vehicleId});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  final controller = Get.find<HomeController>();
  final _scroll = ScrollController();
  int? _id;

  @override
  void initState() {
    super.initState();
    _id = widget.vehicleId ?? int.tryParse(Get.parameters['id'] ?? '');
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Get.back();
    } else {
      Get.offAllNamed('/home');
    }
  }

  // Opens another car in place (no route change, so no controller is
  // disposed) and scrolls back to the top.
  void _open(int? id) {
    setState(() => _id = id);
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 650;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const NavbarWidget(),
      body: Obx(() {
        if (controller.isLoadingVehicles.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final v = controller.vehicleList.firstWhereOrNull((e) => e.id == _id);
        if (v == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Vehicle not found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _goBack,
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          );
        }

        // up to 3 other cars of the same brand, available ones first
        final similar =
            controller.vehicleList
                .where(
                  (e) =>
                      e.id != v.id &&
                      e.brandId != null &&
                      e.brandId == v.brandId,
                )
                .toList()
              ..sort((a, b) {
                int rank(VehicleModel x) =>
                    statusKindOf(x.statusName) == StatusKind.available ? 0 : 1;
                return rank(a).compareTo(rank(b));
              });

        return SingleChildScrollView(
          controller: _scroll,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: narrow ? 16 : 40,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _backButton(),
                    const SizedBox(height: 12),
                    _DetailBody(
                      key: ValueKey(v.id),
                      vehicle: v,
                      similar: similar.take(3).toList(),
                      onOpen: _open,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _backButton() => TextButton.icon(
    onPressed: _goBack,
    icon: const Icon(Icons.arrow_back, size: 18),
    label: const Text('Back to Fleet'),
    style: TextButton.styleFrom(
      foregroundColor: Colors.blueGrey.shade700,
      padding: EdgeInsets.zero,
    ),
  );
}

// ======================================================================
// body: loads the model description and the status / colour lookup items
// ======================================================================
class _DetailBody extends StatefulWidget {
  final VehicleModel vehicle;
  final List<VehicleModel> similar;
  final ValueChanged<int?> onOpen;

  const _DetailBody({
    super.key,
    required this.vehicle,
    required this.similar,
    required this.onOpen,
  });

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  final api = AdminProvider();

  String? description; // Model.Note
  OptionItem? statusItem; // LookUpItem (VehicleStatus)
  OptionItem? colorItem; // LookUpItem (Color)
  bool loading = true;

  VehicleModel get v => widget.vehicle;

  @override
  void initState() {
    super.initState();
    _load();
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

  Map<String, dynamic>? _unwrap(dynamic b) {
    if (b is! Map) return null;
    if (b.containsKey('id')) return Map<String, dynamic>.from(b);
    for (final k in const ['result', 'results', 'data']) {
      final x = b[k];
      if (x is Map) return Map<String, dynamic>.from(x);
      if (x is List && x.isNotEmpty && x.first is Map) {
        return Map<String, dynamic>.from(x.first);
      }
    }
    return null;
  }

  Future<String?> _modelNote() async {
    try {
      final r = await api.getModels();
      if (r.statusCode != 200) return null;
      for (final e in _list(r.body)) {
        if (e is Map && e['id'] == v.modelId) {
          final n = (e['note'] ?? '').toString().trim();
          return n.isEmpty ? null : n;
        }
      }
    } catch (e) {
      debugPrint('MODEL NOTE failed: $e');
    }
    return null;
  }

  Future<OptionItem?> _lookup(int? id) async {
    if (id == null || id == 0) return null;
    try {
      final r = await api.get('/vrms/api/lookupitem/$id');
      if (r.statusCode != 200) return null;
      final m = _unwrap(r.body);
      return m == null ? null : OptionItem.fromJson(m);
    } catch (e) {
      debugPrint('LOOKUP $id failed: $e');
      return null;
    }
  }

  Future<void> _load() async {
    final res = await Future.wait([
      _modelNote(),
      _lookup(v.statusId),
      _lookup(v.colorId),
    ]);
    if (!mounted) return;
    setState(() {
      description = res[0] as String?;
      statusItem = res[1] as OptionItem?;
      colorItem = res[2] as OptionItem?;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    _image(),
                    const SizedBox(height: 20),
                    _descriptionCard(),
                    const SizedBox(height: 20),
                    _technicalCard(),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _infoCard(),
                    if (widget.similar.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _similarCard(),
                    ],
                  ],
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            _image(),
            const SizedBox(height: 20),
            _infoCard(),
            const SizedBox(height: 20),
            _descriptionCard(),
            const SizedBox(height: 20),
            _technicalCard(),
            if (widget.similar.isNotEmpty) ...[
              const SizedBox(height: 20),
              _similarCard(),
            ],
          ],
        );
      },
    );
  }

  // ---------------- image ----------------
  Widget _image() {
    final url = resolveImageUrl(v.imageUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: url == null
            ? _placeholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, __, ___) => _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.grey.shade200,
    child: const Center(
      child: Icon(Icons.directions_car, size: 80, color: Colors.grey),
    ),
  );

  // ---------------- info (right) ----------------
  Widget _infoCard() {
    final day = v.dayPrice;
    final hour = v.hourPrice;
    final main = day ?? v.price;
    final mainUnit = day != null
        ? 'day'
        : ((v.rateTypeName ?? '').isNotEmpty
              ? v.rateTypeName!.toLowerCase()
              : '');
    final available = statusKindOf(v.statusName) == StatusKind.available;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  v.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _statusPill(),
            ],
          ),
          const SizedBox(height: 14),
          if (main != null && main > 0)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${main.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                if (mainUnit.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 5),
                    child: Text(
                      '/ $mainUnit',
                      style: const TextStyle(fontSize: 15, color: _muted),
                    ),
                  ),
                if (day != null && hour != null && hour > 0) ...[
                  const SizedBox(width: 18),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '\$${hour.toStringAsFixed(0)} / hour',
                      style: const TextStyle(fontSize: 14, color: _muted),
                    ),
                  ),
                ],
              ],
            )
          else
            const Text('Price not available', style: TextStyle(color: _muted)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip(
                Icons.palette_outlined,
                v.colorName.isNotEmpty ? v.colorName : (colorItem?.name ?? '-'),
                swatch: _hex(colorItem?.color),
              ),
              _chip(
                Icons.place_outlined,
                v.locationName.isEmpty ? '-' : v.locationName,
              ),
              _chip(
                Icons.confirmation_number_outlined,
                v.licensePlate.isEmpty ? '-' : v.licensePlate,
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: available
                  ? () {
                      if (!AuthService.isLoggedIn) {
                        Get.toNamed('/login');
                        return;
                      }
                      Get.toNamed('/checkout/${v.id}');
                    }
                  : null,
              icon: const Icon(Icons.event_available, size: 20),
              label: Text(available ? 'Book Now' : 'Currently unavailable'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                disabledForegroundColor: _muted,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Free cancellation up to 24 hours before pickup.',
              style: TextStyle(fontSize: 11, color: _muted),
            ),
          ),
        ],
      ),
    );
  }

  Color _kindColor(StatusKind k) {
    switch (k) {
      case StatusKind.available:
        return const Color(0xFF28A745);
      case StatusKind.maintenance:
        return const Color(0xFFDC3545);
      case StatusKind.onRent:
        return const Color(0xFFD97706);
      default:
        return _muted;
    }
  }

  // Uses the colour stored on the LookUpItem; falls back to a default.
  Widget _statusPill() {
    final name = v.statusName.isNotEmpty
        ? v.statusName
        : (statusItem?.name ?? '');
    if (name.isEmpty) return const SizedBox.shrink();
    final c = _hex(statusItem?.color) ?? _kindColor(statusKindOf(name));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: c),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text, {Color? swatch}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (swatch != null)
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: swatch,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black26),
            ),
          )
        else
          Icon(icon, size: 16, color: _muted),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, color: _ink)),
      ],
    ),
  );

  // ---------------- description (left) ----------------
  Widget _descriptionCard() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 10),
        if (loading)
          const LinearProgressIndicator(minHeight: 2)
        else
          Text(
            description ?? 'No description available for this model.',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: description == null ? _muted : const Color(0xFF334155),
            ),
          ),
      ],
    ),
  );

  // ---------------- technical details (left) ----------------
  Widget _technicalCard() {
    final rows = <_Spec>[
      _Spec('Brand', v.brandName),
      _Spec('Model', v.modelName),
      _Spec('License plate', v.licensePlate),
      _Spec(
        'Color',
        v.colorName.isNotEmpty ? v.colorName : (colorItem?.name ?? ''),
        swatch: _hex(colorItem?.color),
      ),
      _Spec(
        'Status',
        v.statusName.isNotEmpty ? v.statusName : (statusItem?.name ?? ''),
      ),
      _Spec('Location', v.locationName),
      if (v.dayPrice != null)
        _Spec('Daily rate', '\$${v.dayPrice!.toStringAsFixed(2)}'),
      if (v.hourPrice != null)
        _Spec('Hourly rate', '\$${v.hourPrice!.toStringAsFixed(2)}'),
    ].where((r) => r.value.trim().isNotEmpty).toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Technical Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++)
                    Container(
                      color: i.isEven ? const Color(0xFFF8FAFC) : Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: _border),
                                  bottom: BorderSide(color: _border),
                                ),
                              ),
                              child: Text(
                                rows[i].label,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _muted,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: _border),
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (rows[i].swatch != null) ...[
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: rows[i].swatch,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black26,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Text(
                                      rows[i].value,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: _ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- similar cars (right) ----------------
  Widget _similarCard() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More from ${v.brandName.isEmpty ? 'this brand' : v.brandName}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 14),
        for (final x in widget.similar) _similarTile(x),
      ],
    ),
  );

  Widget _similarTile(VehicleModel x) {
    final url = resolveImageUrl(x.imageUrl);
    final p = x.dayPrice ?? x.price;
    final unit = x.dayPrice != null
        ? 'day'
        : ((x.rateTypeName ?? '').isNotEmpty
              ? x.rateTypeName!.toLowerCase()
              : '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => widget.onOpen(x.id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 96,
                  height: 68,
                  child: url == null
                      ? _placeholder()
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      x.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p != null && p > 0
                          ? '\$${p.toStringAsFixed(0)}${unit.isEmpty ? '' : ' / $unit'}'
                          : 'Price not available',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class _Spec {
  final String label;
  final String value;
  final Color? swatch;
  _Spec(this.label, this.value, {this.swatch});
}
