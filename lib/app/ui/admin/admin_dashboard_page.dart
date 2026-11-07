import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/controllers/admin_controller.dart';
import 'package:vrs_ui/app/core/utils/image_url.dart';
import 'package:vrs_ui/app/data/models/vehicle_model.dart';

class AdminDashboardPage extends GetView<AdminController> {
  const AdminDashboardPage({super.key});

  // ---------- colors (inline, no AppColors) ----------
  static const _primary = Color(0xFF003399);
  static const _accent = Color(0xFF2563EB);
  static const _border = Color(0xFFE2E8F0);
  static const _text = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _softPrimary = Color(0xFFE8EEFF);
  static const _gradient = LinearGradient(
    colors: [Color(0xFF003399), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const _palette = [
    _primary,
    _accent,
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final list = controller.vehicles.toList();
      final brandCount = controller.brands.length;
      final locationCount = controller.locations.length;

      final byStatus = _countBy(list, (v) => v.statusName);
      final byBrand = _countBy(list, (v) => v.brandName);
      final byLocation = _countBy(list, (v) => v.locationName);

      final priced = list
          .where((v) => v.price != null && v.price! > 0)
          .toList();
      final avgPrice = priced.isEmpty
          ? 0.0
          : priced.fold<double>(0, (s, v) => s + v.price!) / priced.length;

      final availableCount = byStatus.entries
          .where((e) {
            final k = e.key.toLowerCase();
            return k.contains('available') && !k.contains('unavailable');
          })
          .fold<int>(0, (s, e) => s + e.value);

      final recent = list.reversed.take(6).toList();

      return LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final pad = w < 650 ? 16.0 : 28.0;
          final wide = w >= 1000;

          final statusPanel = _panel(
            'Fleet by Status',
            'How your vehicles are distributed',
            _statusChart(byStatus, list.length),
          );
          final brandPanel = _panel(
            'Vehicles by Brand',
            'Top brands in your fleet',
            _barList(byBrand, _primary),
          );
          final locationPanel = _panel(
            'Vehicles by Location',
            'Where your vehicles are parked',
            _barList(byLocation, _accent),
          );
          final recentPanel = _panel(
            'Recently Added',
            'Latest vehicles in the system',
            _recentList(recent),
          );

          return SingleChildScrollView(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 24),

                // KPI cards
                _kpiGrid(w - pad * 2, [
                  _Kpi(
                    'Total Vehicles',
                    '${list.length}',
                    Icons.directions_car_rounded,
                    _primary,
                    highlight: true,
                  ),
                  _Kpi(
                    'Available Now',
                    '$availableCount',
                    Icons.check_circle_outline_rounded,
                    const Color(0xFF10B981),
                  ),
                  _Kpi('Brands', '$brandCount', Icons.sell_outlined, _accent),
                  _Kpi(
                    'Locations',
                    '$locationCount',
                    Icons.place_outlined,
                    const Color(0xFF8B5CF6),
                  ),
                ]),
                const SizedBox(height: 16),
                _kpiGrid(w - pad * 2, [
                  _Kpi(
                    'Avg. Rate',
                    avgPrice == 0 ? '-' : '\$${avgPrice.toStringAsFixed(0)}',
                    Icons.payments_outlined,
                    const Color(0xFF06B6D4),
                  ),
                ]),
                const SizedBox(height: 24),

                // Charts
                if (wide) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: statusPanel),
                      const SizedBox(width: 16),
                      Expanded(flex: 5, child: brandPanel),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: locationPanel),
                      const SizedBox(width: 16),
                      Expanded(flex: 5, child: recentPanel),
                    ],
                  ),
                ] else ...[
                  statusPanel,
                  const SizedBox(height: 16),
                  brandPanel,
                  const SizedBox(height: 16),
                  locationPanel,
                  const SizedBox(height: 16),
                  recentPanel,
                ],
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    });
  }

  // ───────────────────────── header ─────────────────────────

  Widget _header() {
    final now = DateTime.now();
    const months = [
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
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : (hour < 18 ? 'Good afternoon' : 'Good evening');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, Admin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Here is what is happening with your fleet today.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  '${now.day} ${months[now.month - 1]} ${now.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── KPI ─────────────────────────

  Widget _kpiGrid(double width, List<_Kpi> items) {
    const gap = 16.0;
    final cols = width >= 1000 ? 4 : (width >= 560 ? 2 : 1);
    final cardW = (width - gap * (cols - 1)) / cols;

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [for (final k in items) _kpiCard(k, cardW)],
    );
  }

  Widget _kpiCard(_Kpi k, double width) {
    final hl = k.highlight;
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hl ? null : Colors.white,
        gradient: hl ? _gradient : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hl ? Colors.transparent : _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: hl ? Colors.white24 : k.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(k.icon, color: hl ? Colors.white : k.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  k.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: hl ? Colors.white70 : _muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  k.value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: hl ? Colors.white : _text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── panels ─────────────────────────

  Widget _panel(String title, String subtitle, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: _muted)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _empty(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Center(
      child: Text(text, style: const TextStyle(color: _muted)),
    ),
  );

  // ───────────────────────── status donut ─────────────────────────

  Widget _statusChart(Map<String, int> data, int total) {
    if (data.isEmpty) return _empty('No vehicles yet');
    final entries = data.entries.toList();

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: Center(
            child: SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(190, 190),
                    painter: _DonutPainter(
                      values: [for (final e in entries) e.value.toDouble()],
                      colors: [
                        for (int i = 0; i < entries.length; i++)
                          _palette[i % _palette.length],
                      ],
                      track: _softPrimary,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: _text,
                        ),
                      ),
                      const Text(
                        'vehicles',
                        style: TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        for (int i = 0; i < entries.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _palette[i % _palette.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entries[i].key,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  '${entries[i].value}  '
                  '(${(entries[i].value * 100 / total).toStringAsFixed(0)}%)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ───────────────────────── bar list ─────────────────────────

  Widget _barList(Map<String, int> data, Color color) {
    if (data.isEmpty) return _empty('No data yet');
    final entries = data.entries.take(6).toList();
    final max = entries.map((e) => e.value).reduce(math.max);

    return Column(
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.key,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${e.value}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Container(height: 8, color: _softPrimary),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: e.value / max),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (_, t, __) => FractionallySizedBox(
                          widthFactor: t,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ───────────────────────── recent vehicles ─────────────────────────

  Widget _recentList(List<VehicleModel> items) {
    if (items.isEmpty) return _empty('No vehicles yet');

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _recentRow(items[i]),
          if (i != items.length - 1) const Divider(height: 20, color: _border),
        ],
      ],
    );
  }

  Widget _recentRow(VehicleModel v) {
    final url = resolveImageUrl(v.imageUrl);
    final hasPrice = v.price != null && v.price! > 0;
    final status = v.statusName.isEmpty ? 'Unknown' : v.statusName;
    final sc = _statusColor(status);

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 64,
            height: 46,
            child: url == null
                ? _thumb()
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _thumb(),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                v.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${v.licensePlate}  •  ${v.locationName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: sc.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: sc,
            ),
          ),
        ),
        if (hasPrice) ...[
          const SizedBox(width: 12),
          Text(
            '\$${v.price!.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: _primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _thumb() => Container(
    color: _softPrimary,
    child: const Icon(Icons.directions_car, size: 22, color: _primary),
  );

  // ───────────────────────── helpers ─────────────────────────

  /// Counts items by a text key and returns the result sorted high → low.
  Map<String, int> _countBy(
    List<VehicleModel> list,
    String Function(VehicleModel) key,
  ) {
    final m = <String, int>{};
    for (final v in list) {
      final k = key(v).trim().isEmpty ? 'Unknown' : key(v).trim();
      m[k] = (m[k] ?? 0) + 1;
    }
    final sorted = m.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted) e.key: e.value};
  }

  Color _statusColor(String s) {
    final t = s.toLowerCase();
    if (t.contains('unavail') || t.contains('maint') || t.contains('repair')) {
      return const Color(0xFFEF4444);
    }
    if (t.contains('available')) return const Color(0xFF10B981);
    if (t.contains('book') || t.contains('rent') || t.contains('use')) {
      return _accent;
    }
    return _primary;
  }
}

class _Kpi {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlight;
  const _Kpi(
    this.label,
    this.value,
    this.icon,
    this.color, {
    this.highlight = false,
  });
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final Color track;
  _DonutPainter({
    required this.values,
    required this.colors,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total == 0) return;

    const stroke = 26.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, bg);

    final gap = values.length > 1 ? 0.04 : 0.0;
    double start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = colors[i];
      canvas.drawArc(
        rect,
        start + gap / 2,
        math.max(sweep - gap, 0.01),
        false,
        p,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.values != values || old.colors != colors || old.track != track;
}
