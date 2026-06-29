import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Wrap a list row to fade + slide it in, staggered by its index.
/// Usage: itemBuilder: (_, i) => AnimatedListItem(index: i, child: yourRow),
class AnimatedListItem extends StatelessWidget {
  final int index;
  final Widget child;
  const AnimatedListItem({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    // Cap the stagger so a 60-item list doesn't take forever.
    final delayMs = (index.clamp(0, 12)) * 35;
    return child
        .animate()
        .fadeIn(duration: 220.ms, delay: delayMs.ms)
        .slideY(begin: 0.08, end: 0, duration: 220.ms, delay: delayMs.ms, curve: Curves.easeOut);
  }
}