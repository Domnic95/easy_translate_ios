import 'package:easy_translate/models/language.dart';
import 'package:flutter/material.dart';

import '../utils/extensions.dart';
import 'language_chip.dart';
import 'language_picker.dart';

class LanguageSwapBar extends StatefulWidget {
  final Language source;
  final Language target;
  final ValueChanged<Language> onSource;
  final ValueChanged<Language> onTarget;
  final VoidCallback onSwap;
  const LanguageSwapBar({
    super.key,
    required this.source,
    required this.target,
    required this.onSource,
    required this.onTarget,
    required this.onSwap,
  });

  @override
  State<LanguageSwapBar> createState() => _LanguageSwapBarState();
}

class _LanguageSwapBarState extends State<LanguageSwapBar>
    with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: LanguageChip(
              language: widget.source,
              onTap: () async {
                final l = await pickLanguage(
                  context,
                  includeAuto: true,
                  selected: widget.source.code,
                );
                if (l != null) widget.onSource(l);
              },
            ),
          ),
          RotationTransition(
            turns: Tween<double>(begin: 0, end: 0.5).animate(
              CurvedAnimation(parent: _spin, curve: Curves.easeOutBack),
            ),
            child: IconButton.filledTonal(
              onPressed: () {
                _spin.forward(from: 0);
                widget.onSwap();
              },
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
          ),
          Expanded(
            child: LanguageChip(
              language: widget.target,
              onTap: () async {
                final l = await pickLanguage(
                  context,
                  selected: widget.target.code,
                );
                if (l != null) widget.onTarget(l);
              },
            ),
          ),
        ],
      ),
    );
  }
}
