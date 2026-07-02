import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/extensions.dart';

class PulsingMic extends StatelessWidget {
  final bool active;
  final bool busy;
  final VoidCallback onTap;
  final double size;
  const PulsingMic({
    super.key,
    required this.active,
    required this.onTap,
    this.busy = false,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.colors.primary;
    return SizedBox(
      width: size * 1.8,
      height: size * 1.8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (active)
            ...List.generate(3, (i) {
              return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.25),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(), delay: (i * 400).ms)
                  .scaleXY(
                    begin: 1,
                    end: 2.0,
                    duration: 1400.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeOut(duration: 1400.ms);
            }),
          if (busy)
            SizedBox(
              width: size * 1.15,
              height: size * 1.15,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          Material(
            color: busy ? color.withValues(alpha: 0.75) : color,
            shape: const CircleBorder(),
            elevation: 6,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: busy ? null : onTap,
              child: SizedBox(
                width: size,
                height: size,
                child: Icon(
                  busy
                      ? Icons.hourglass_top_rounded
                      : active
                      ? Icons.stop_rounded
                      : Icons.mic_rounded,
                  size: size * 0.42,
                  color: context.colors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
