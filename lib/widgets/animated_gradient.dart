import 'package:flutter/material.dart';
import '../utils/extensions.dart';

class AnimatedGradient extends StatefulWidget {
  final Widget child;
  const AnimatedGradient({super.key, required this.child});

  @override
  State<AnimatedGradient> createState() => _AnimatedGradientState();
}

class _AnimatedGradientState extends State<AnimatedGradient>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1 + _c.value * 2, -1),
            end: Alignment(1, 1 - _c.value * 2),
            colors: [
              context.colors.primaryContainer,
              context.colors.tertiaryContainer,
            ],
          ),
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}
