import 'dart:async';
import 'package:flutter/material.dart';

class BrandSlider extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double itemWidth;
  final double gap;
  final double height;
  final Duration autoPlay;

  const BrandSlider({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemWidth = 190,
    this.gap = 12,
    this.height = 130,
    this.autoPlay = const Duration(seconds: 3),
  });

  @override
  State<BrandSlider> createState() => _BrandSliderState();
}

class _BrandSliderState extends State<BrandSlider> {
  final ScrollController _sc = ScrollController();
  Timer? _timer;
  bool _hovering = false;

  double get _step => widget.itemWidth + widget.gap;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.autoPlay, (_) {
      if (!_hovering) _move(forward: true);
    });
  }

  void _move({required bool forward}) {
    if (!_sc.hasClients) return;
    final max = _sc.position.maxScrollExtent;
    if (max <= 0) return; // everything already fits on screen

    double target;
    if (forward) {
      target = _sc.offset >= max - 1 ? 0 : _sc.offset + _step;
    } else {
      target = _sc.offset <= 1 ? max : _sc.offset - _step;
    }

    _sc.animateTo(
      target.clamp(0.0, max),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _hovering = true, // pause while the mouse is over it
      onExit: (_) => _hovering = false,
      child: Row(
        children: [
          _arrow(Icons.chevron_left_rounded, () {
            _move(forward: false);
            _startTimer();
          }),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: widget.height,
              child: ListView.separated(
                controller: _sc,
                scrollDirection: Axis.horizontal,
                itemCount: widget.itemCount,
                separatorBuilder: (_, __) => SizedBox(width: widget.gap),
                itemBuilder: (context, i) => SizedBox(
                  width: widget.itemWidth,
                  child: widget.itemBuilder(context, i),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _arrow(Icons.chevron_right_rounded, () {
            _move(forward: true);
            _startTimer();
          }),
        ],
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 22, color: Colors.black87),
      ),
    );
  }
}
