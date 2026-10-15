import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:vrs_ui/app/core/utils/image_url.dart';
import 'package:vrs_ui/app/data/models/vehicle_model.dart';

class HeroBanner extends StatefulWidget {
  final List<VehicleModel> vehicles;
  final bool loading;
  final void Function(VehicleModel v) onBook;
  final Duration autoPlay;

  const HeroBanner({
    super.key,
    required this.vehicles,
    required this.onBook,
    this.loading = false,
    this.autoPlay = const Duration(seconds: 6),
  });

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      widget.autoPlay,
      (_) => _go(_index + 1, manual: false),
    );
  }

  void _go(int i, {bool manual = true}) {
    final n = widget.vehicles.length;
    if (!mounted || n < 2) return;
    setState(() => _index = ((i % n) + n) % n);
    if (manual) _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isMobile = c.maxWidth < 650;
        final height = isMobile ? 500.0 : 520.0;
        final pad = isMobile ? 22.0 : 56.0;
        final list = widget.vehicles;

        // Loading / empty state
        if (widget.loading || list.isEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: ColoredBox(
                color: const Color(0xFF111111),
                child: Center(
                  child: widget.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'No vehicles available',
                          style: TextStyle(color: Colors.white70),
                        ),
                ),
              ),
            ),
          );
        }

        final idx = _index % list.length;
        final v = list[idx];

        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFF111111)),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 900),
                  layoutBuilder: (current, previous) => Stack(
                    fit: StackFit.expand,
                    children: [...previous, if (current != null) current],
                  ),
                  child: _HeroSlide(
                    key: ValueKey('${v.id}-$idx'),
                    v: v,
                    isMobile: isMobile,
                    padding: pad,
                    onBook: () => widget.onBook(v),
                  ),
                ),
                Positioned(
                  left: pad,
                  right: pad,
                  bottom: isMobile ? 18 : 28,
                  child: Row(
                    children: [
                      for (int i = 0; i < list.length; i++) ...[
                        _progressBar(i, idx, isMobile),
                        const SizedBox(width: 8),
                      ],
                      const Spacer(),
                      if (!isMobile) ...[
                        Text(
                          '${(idx + 1).toString().padLeft(2, '0')} / '
                          '${list.length.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      _arrow(Icons.arrow_back_rounded, () => _go(idx - 1)),
                      const SizedBox(width: 8),
                      _arrow(Icons.arrow_forward_rounded, () => _go(idx + 1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _progressBar(int i, int active, bool isMobile) {
    final w = isMobile ? 26.0 : 44.0;
    return GestureDetector(
      onTap: () => _go(i),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: w,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white30,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.centerLeft,
          child: i == active
              ? TweenAnimationBuilder<double>(
                  key: ValueKey('p$active'),
                  tween: Tween(begin: 0, end: 1),
                  duration: widget.autoPlay,
                  builder: (_, t, __) => Container(
                    width: w * t,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.14),
          border: Border.all(color: Colors.white38),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ───────────────────────── single slide ─────────────────────────

class _HeroSlide extends StatefulWidget {
  final VehicleModel v;
  final bool isMobile;
  final double padding;
  final VoidCallback onBook;

  const _HeroSlide({
    super.key,
    required this.v,
    required this.isMobile,
    required this.padding,
    required this.onBook,
  });

  @override
  State<_HeroSlide> createState() => _HeroSlideState();
}

class _HeroSlideState extends State<_HeroSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7000),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Animation<double> _iv(double a, double b) => CurvedAnimation(
    parent: _c,
    curve: Interval(a, b, curve: Curves.easeOutCubic),
  );

  Widget _reveal(
    Animation<double> a,
    Widget child, {
    Offset from = const Offset(0, 0.35),
  }) => FadeTransition(
    opacity: a,
    child: SlideTransition(
      position: Tween<Offset>(begin: from, end: Offset.zero).animate(a),
      child: child,
    ),
  );

  Widget _carPlaceholder() => const ColoredBox(
    color: Color(0xFF2A2A2A),
    child: Center(
      child: Icon(Icons.directions_car, size: 64, color: Colors.white38),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final v = widget.v;
    final m = widget.isMobile;
    final url = resolveImageUrl(v.imageUrl);
    final hasPrice = v.price != null && v.price! > 0;
    final subtitle = [
      v.modelName,
      v.colorName,
      v.locationName,
    ].where((e) => e.isNotEmpty).join('  •  ');
    final eyebrow = (v.brandName.isNotEmpty ? v.brandName : 'FEATURED')
        .toUpperCase();

    return LayoutBuilder(
      builder: (context, box) {
        final W = box.maxWidth;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Blurred car photo as background
            if (url != null)
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Transform.scale(
                  scale: 1.25,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
            // Dark overlay so text is readable
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: m ? Alignment.topCenter : Alignment.centerLeft,
                  end: m ? Alignment.bottomCenter : Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(m ? 0.35 : 0.80),
                    Colors.black.withOpacity(m ? 0.85 : 0.45),
                  ],
                ),
              ),
            ),

            // The car card
            Positioned(
              top: m ? 24 : 36,
              right: widget.padding,
              left: m ? widget.padding : null,
              bottom: m ? null : 84,
              height: m ? 180 : null,
              width: m ? null : W * 0.46,
              child: _reveal(
                _iv(0.0, 0.2),
                from: const Offset(0.12, 0),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 40,
                        offset: Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (_, child) => Transform.scale(
                        scale: 1.0 + 0.06 * _c.value, // slow zoom
                        child: child,
                      ),
                      child: url == null
                          ? _carPlaceholder()
                          : Image.network(
                              url,
                              fit: BoxFit
                                  .cover, // use BoxFit.contain to show the full car
                              errorBuilder: (_, __, ___) => _carPlaceholder(),
                            ),
                    ),
                  ),
                ),
              ),
            ),

            // Text
            Padding(
              padding: EdgeInsets.only(
                left: widget.padding,
                right: widget.padding,
                bottom: m ? 60 : 84,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: m ? 500 : 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _reveal(
                        _iv(0.04, 0.16),
                        Text(
                          eyebrow,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: m ? 12 : 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _reveal(
                        _iv(0.08, 0.22),
                        Text(
                          v.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: m ? 34 : 52,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _reveal(
                        _iv(0.14, 0.28),
                        Text(
                          subtitle.isEmpty ? v.licensePlate : subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: m ? 13 : 16,
                          ),
                        ),
                      ),
                      SizedBox(height: m ? 18 : 26),
                      _reveal(
                        _iv(0.20, 0.34),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: widget.onBook,
                              icon: const Icon(Icons.event_available, size: 18),
                              label: const Text('BOOK NOW'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  horizontal: m ? 20 : 30,
                                  vertical: m ? 14 : 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                textStyle: TextStyle(
                                  fontSize: m ? 13 : 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (hasPrice) ...[
                              const SizedBox(width: 16),
                              Text(
                                '\$${v.price!.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: m ? 20 : 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if ((v.rateTypeName ?? '').isNotEmpty)
                                Text(
                                  ' / ${v.rateTypeName}',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
