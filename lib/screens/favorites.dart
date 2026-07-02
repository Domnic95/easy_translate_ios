import '../utils/constants.dart';
import '../utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:easy_translate/providers/favorites_provider.dart';
import 'package:easy_translate/widgets/empty_state.dart';
import 'package:easy_translate/Google_Ads/Native_Ads/BottomNavSafeNativeAd.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<FavoritesProvider>();
    return Scaffold(
      bottomNavigationBar: const BottomNavSafeNativeAd(tabIndex: 2),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          S.favorites,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: p.items.isEmpty
            ? const EmptyState(
                icon: Icons.star_outline_rounded,
                title: 'No favorites yet',
                message: 'Star a translation to keep it here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: p.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final t = p.items[i];
                  final src = Languages.byCode(t.sourceLang);
                  final tgt = Languages.byCode(t.targetLang);
                  return Dismissible(
                    key: ValueKey(t.id),
                    background: Container(
                      color: context.colors.errorContainer,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: const Icon(Icons.delete_rounded),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => p.remove(t.id),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        title: Text(
                          t.sourceText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            t.translatedText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        leading: const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                        ),
                        trailing: Text(
                          '${src.flag} → ${tgt.flag}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
