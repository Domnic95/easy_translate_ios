import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ExpandedNativeAdShimmer extends StatelessWidget {
  const ExpandedNativeAdShimmer({super.key, this.height = 336});

  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111A33) : Colors.white;
    final block = isDark ? const Color(0xFF1B2547) : const Color(0xFFE2E8F0);
    final highlight = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.75);

    return SizedBox(
          height: height,
          child: Stack(
            children: [
              Container(
                height: height,
                color: bg,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Block(
                      width: double.infinity,
                      height: 180,
                      radius: 8,
                      color: block,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _Block(
                            width: 48,
                            height: 48,
                            radius: 10,
                            color: block,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Block(
                                  width: double.infinity,
                                  height: 12,
                                  radius: 6,
                                  color: block,
                                ),
                                const SizedBox(height: 6),
                                _Block(
                                  width: 100,
                                  height: 10,
                                  radius: 5,
                                  color: block,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    _Block(
                      width: double.infinity,
                      height: 12,
                      radius: 6,
                      color: block,
                    ),
                    const SizedBox(height: 8),
                    _Block(
                      width: double.infinity,
                      height: 52,
                      radius: 16,
                      color: block,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _Block(width: 22, height: 14, radius: 4, color: block),
              ),
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
