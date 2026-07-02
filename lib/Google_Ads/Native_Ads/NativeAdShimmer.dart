import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NativeAdShimmer extends StatelessWidget {
  const NativeAdShimmer({super.key, this.height = 60});

  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111A33) : Colors.white;
    final block = isDark ? const Color(0xFF1B2547) : const Color(0xFFE2E8F0);
    final highlight = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.75);

    return Container(
          height: height,
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Block(width: 44, height: 44, radius: 10, color: block),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Block(width: 140, height: 12, radius: 6, color: block),
                    const SizedBox(height: 8),
                    _Block(width: 100, height: 10, radius: 5, color: block),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _Block(width: 80, height: 34, radius: 18, color: block),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1400.ms, color: highlight);
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
  });

  final double width;
  final double height;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
