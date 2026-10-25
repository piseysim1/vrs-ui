import 'package:flutter/material.dart';

class AboutUsSection extends StatelessWidget {
  const AboutUsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth > 900;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 40.0 : 20.0,
            vertical: isDesktop ? 48.0 : 32.0,
          ),
          color: Colors.white,
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1300),
              child: Flex(
                direction: isDesktop ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ===== LEFT: Animated image card =====
                  isDesktop
                      ? Expanded(
                          flex: 6,
                          child: SizedBox(
                            width: double.infinity,
                            child: const _JourneyCard(),
                          ),
                        )
                      : const SizedBox(
                          width: double.infinity,
                          child: _JourneyCard(),
                        ),

                  SizedBox(
                    width: isDesktop ? 60 : 0,
                    height: isDesktop ? 0 : 32,
                  ),

                  // ===== RIGHT: Text content =====
                  isDesktop
                      ? Expanded(flex: 5, child: _buildTextContent(isDesktop))
                      : SizedBox(
                          width: double.infinity,
                          child: _buildTextContent(isDesktop),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextContent(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ABOUT US',
          style: TextStyle(
            color: Color.fromARGB(255, 82, 255, 192),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Drive Your Way with Confidence',
          style: TextStyle(
            color: const Color(0xFF0F172A),
            fontSize: isDesktop ? 32 : 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'We provide a seamless car rental experience tailored to your lifestyle and travel needs. Whether it is a weekend getaway, a business trip, or long-term mobility, our well-maintained fleet and dedicated support team ensure you always drive in comfort and safety.',
          style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.6),
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isDesktop ? 5 : 4,
          children: const [
            _FeatureItem(text: 'Clean & Modern Fleet'),
            _FeatureItem(text: 'Transparent Pricing'),
            _FeatureItem(text: '24/7 Road Support'),
            _FeatureItem(text: 'Flexible Booking Terms'),
          ],
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          onPressed: () {},
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Explore Fleet',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _JourneyCard extends StatefulWidget {
  const _JourneyCard({Key? key}) : super(key: key);

  @override
  State<_JourneyCard> createState() => _JourneyCardState();
}

class _JourneyCardState extends State<_JourneyCard>
    with TickerProviderStateMixin {
  late final AnimationController _zoomCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _enterCtrl;

  late final Animation<double> _zoom;
  late final Animation<double> _float;
  late final Animation<Offset> _line1Slide;
  late final Animation<double> _line1Fade;
  late final Animation<Offset> _line2Slide;
  late final Animation<double> _line2Fade;

  bool _hover = false;

  @override
  void initState() {
    super.initState();

    _zoomCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _zoom = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _zoomCtrl, curve: Curves.easeInOut));

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _float = Tween<double>(
      begin: -6,
      end: 6,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    CurvedAnimation interval(
      double a,
      double b, [
      Curve c = Curves.easeOutCubic,
    ]) => CurvedAnimation(
      parent: _enterCtrl,
      curve: Interval(a, b, curve: c),
    );

    _line1Fade = Tween<double>(begin: 0, end: 1).animate(interval(0.3, 0.65));
    _line1Slide = Tween<Offset>(
      begin: const Offset(-0.15, 0),
      end: Offset.zero,
    ).animate(interval(0.3, 0.65));
    _line2Fade = Tween<double>(begin: 0, end: 1).animate(interval(0.5, 0.9));
    _line2Slide = Tween<Offset>(
      begin: const Offset(-0.15, 0),
      end: Offset.zero,
    ).animate(interval(0.5, 0.9));
  }

  @override
  void dispose() {
    _zoomCtrl.dispose();
    _floatCtrl.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: AspectRatio(
          aspectRatio: 16 / 11,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:
                      (_hover
                              ? const Color.fromARGB(255, 130, 228, 231)
                              : Colors.black)
                          .withOpacity(_hover ? 0.28 : 0.15),
                  blurRadius: _hover ? 36 : 20,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedBuilder(
                    animation: _zoom,
                    builder: (_, child) =>
                        Transform.scale(scale: _zoom.value, child: child),
                    child: Image.asset(
                      'assets/images/toyotaTacoma.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0F172A).withOpacity(0.35),
                          const Color(0xFF0F172A).withOpacity(0.92),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: AnimatedBuilder(
                      animation: _float,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _float.value),
                        child: child,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.support_agent,
                              color: Color.fromARGB(255, 82, 255, 192),
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '24/7 Support',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SlideTransition(
                          position: _line1Slide,
                          child: FadeTransition(
                            opacity: _line1Fade,
                            child: const Text(
                              'Your Journey,',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SlideTransition(
                          position: _line2Slide,
                          child: FadeTransition(
                            opacity: _line2Fade,
                            child: const Text(
                              'Our Priority.',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
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
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;
  const _FeatureItem({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle,
          color: Color.fromARGB(255, 5, 198, 114),
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
