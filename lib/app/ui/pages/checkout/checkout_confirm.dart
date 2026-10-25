import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrs_ui/app/core/utils/image_url.dart';
import 'package:vrs_ui/app/data/models/booking_summary_model.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/navbar.dart';
import 'package:vrs_ui/app/ui/pages/home/home_widget/navbar_widget.dart';

const kMyBookingsRoute = '/my-bookings';

const _primary = Color(0xFF003399);
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);

class BookingConfirmedPage extends StatefulWidget {
  final BookingSummary summary;
  const BookingConfirmedPage({super.key, required this.summary});

  @override
  State<BookingConfirmedPage> createState() => _BookingConfirmedPageState();
}

class _BookingConfirmedPageState extends State<BookingConfirmedPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  BookingSummary get s => widget.summary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: const NavbarWidget(),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ConfettiPainter(_confetti)),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _card(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFF1E40AF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 30,
              color: Color(0xFFA5B4FC),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Booking Confirmed!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _primary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your reservation is secure. We\'ve sent a detailed\n'
          'confirmation email to your registered address.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 26),
        _details(),
        const SizedBox(height: 26),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: () => Get.offAllNamed(kMyBookingsRoute),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'View My Bookings',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            OutlinedButton(
              onPressed: () => Get.offAllNamed('/home'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _muted),
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Return to Home',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  // ---------- grey details panel ----------
  Widget _details() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF0F3),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _border),
    ),
    child: Column(
      children: [
        _vehicleImage(),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final a = _tile(
              Icons.tag,
              'REFERENCE NO.',
              s.reference.isEmpty ? '—' : s.reference,
            );
            final b = _tile(
              Icons.place_outlined,
              'PICK-UP / DROP-OFF',
              s.locationName.isEmpty ? '—' : s.locationName,
            );
            if (c.maxWidth < 420) {
              return Column(children: [a, const SizedBox(height: 12), b]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: a),
                const SizedBox(width: 14),
                Expanded(child: b),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _datesTile(),
      ],
    ),
  );

  Widget _vehicleImage() {
    final url = resolveImageUrl(s.imageUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 170,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url == null)
              Container(
                color: const Color(0xFF1E293B),
                child: const Icon(
                  Icons.directions_car,
                  size: 56,
                  color: Colors.white24,
                ),
              )
            else
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1E293B),
                  child: const Icon(
                    Icons.directions_car,
                    size: 56,
                    color: Colors.white24,
                  ),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.45, 1],
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 12,
              right: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B5BDB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.brandName.isEmpty
                          ? 'VEHICLE'
                          : s.brandName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.vehicleName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _border),
    ),
    child: child,
  );

  Widget _label(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 9,
      letterSpacing: 0.6,
      fontWeight: FontWeight.w600,
      color: _muted,
    ),
  );

  Widget _tile(IconData icon, String label, String value) => _box(
    child: Row(
      children: [
        Icon(icon, size: 20, color: _muted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(label),
              const SizedBox(height: 3),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _datesTile() => _box(
    child: Row(
      children: [
        const Icon(Icons.calendar_month_outlined, size: 20, color: _muted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('DATES'),
              const SizedBox(height: 3),
              Text(
                _range(s.start, s.end),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _label('TOTAL'),
            const SizedBox(height: 2),
            Text(
              '\$${s.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _primary,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  static const _m = [
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

  /// "Oct 12 - Oct 15, 2026"  (or with both years if they differ)
  String _range(DateTime a, DateTime b) {
    final left = '${_m[a.month - 1]} ${a.day}';
    final right = '${_m[b.month - 1]} ${b.day}, ${b.year}';
    return a.year == b.year ? '$left - $right' : '$left, ${a.year} - $right';
  }
}

/// Light one-shot confetti that falls and fades out.
class _ConfettiPainter extends CustomPainter {
  final Animation<double> anim;
  late final List<_Dot> dots;

  _ConfettiPainter(this.anim) : super(repaint: anim) {
    final r = Random(11);
    const colors = [
      Color(0xFF3B5BDB),
      Color(0xFF93C5FD),
      Color(0xFFA5B4FC),
      Color(0xFF1E40AF),
    ];
    dots = List.generate(
      46,
      (_) => _Dot(
        x: r.nextDouble(),
        delay: r.nextDouble() * 0.35,
        size: 2 + r.nextDouble() * 4,
        speed: 0.55 + r.nextDouble() * 0.45,
        phase: r.nextDouble() * 6.28,
        color: colors[r.nextInt(colors.length)],
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in dots) {
      final t = ((anim.value - d.delay) / (1 - d.delay)).clamp(0.0, 1.0);
      if (t == 0) continue;
      final y = -10 + t * size.height * 0.85 * d.speed;
      final x = d.x * size.width + sin(t * 7 + d.phase) * 16;
      final paint = Paint()
        ..color = d.color.withOpacity((1 - t).clamp(0.0, 1.0) * 0.8);
      canvas.drawCircle(Offset(x, y), d.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => true;
}

class _Dot {
  final double x, delay, size, speed, phase;
  final Color color;
  _Dot({
    required this.x,
    required this.delay,
    required this.size,
    required this.speed,
    required this.phase,
    required this.color,
  });
}
