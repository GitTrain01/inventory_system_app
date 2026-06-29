import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Adds a gentle press-scale + ripple to any widget (e.g. a Card).
class Tappable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const Tappable({super.key, required this.child, this.onTap});
  @override
  State<Tappable> createState() => _TappableState();
}

class _TappableState extends State<Tappable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}