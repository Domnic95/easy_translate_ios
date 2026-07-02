import 'package:easy_translate/models/translation.dart';
import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/extensions.dart';

class TranslationCard extends StatelessWidget {
  final Translation t;
  final VoidCallback? onSpeak, onCopy, onShare, onFavorite;
  const TranslationCard({
    super.key,
    required this.t,
    this.onSpeak,
    this.onCopy,
    this.onShare,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final src = Languages.byCode(t.sourceLang);
    final tgt = Languages.byCode(t.targetLang);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(src.flag, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  src.name,
                  style: context.text.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, size: 14),
                Text(tgt.flag, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  tgt.name,
                  style: context.text.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              t.translatedText,
              style: context.text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: onSpeak,
                  icon: const Icon(Icons.volume_up_rounded),
                ),
                IconButton(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded),
                ),
                IconButton(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_rounded),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onFavorite,
                  icon: Icon(
                    t.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: t.isFavorite ? Colors.amber : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
