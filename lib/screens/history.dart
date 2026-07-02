import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:easy_translate/models/translation.dart';
import 'package:easy_translate/widgets/empty_state.dart';
import 'package:easy_translate/providers/history_provider.dart';
import 'package:easy_translate/Google_Ads/Native_Ads/BottomNavSafeNativeAd.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Set<String> _selected = {};
  bool get _inSelectionMode => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().load();
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  void _clearSelection() => setState(_selected.clear);

  Future<void> _deleteOne(HistoryProvider p, Translation t) async {
    await p.remove(t.id);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Translation deleted'),
          action: SnackBarAction(label: 'Undo', onPressed: () => p.restore(t)),
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  Future<void> _deleteSelected(HistoryProvider p) async {
    final count = _selected.length;

    final doomed = p.items.where((t) => _selected.contains(t.id)).toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $count item${count == 1 ? '' : 's'}?'),
        content: const Text('You can undo this from the snackbar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.errorContainer,
              foregroundColor: context.colors.onErrorContainer,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await p.removeMany(doomed.map((t) => t.id));
    if (!mounted) return;
    _clearSelection();
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$count deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              for (final t in doomed) {
                await p.restore(t);
              }
            },
          ),
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HistoryProvider>();

    _selected.retainAll(p.items.map((t) => t.id));
    final selectionMode = _inSelectionMode;
    return Scaffold(
      appBar: selectionMode ? _selectionAppBar(p) : _normalAppBar(p),
      bottomNavigationBar: const BottomNavSafeNativeAd(tabIndex: 1),
      body: SafeArea(
        child: Column(
          children: [
            if (!selectionMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  onChanged: p.search,
                  decoration: const InputDecoration(
                    hintText: 'Search history…',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
            Expanded(child: _body(p)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _normalAppBar(HistoryProvider p) {
    return AppBar(
      title: const Text(
        S.history,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      centerTitle: true,
      actions: [
        if (p.items.isNotEmpty)
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () => _confirmClear(p),
          ),
      ],
    );
  }

  PreferredSizeWidget _selectionAppBar(HistoryProvider p) {
    return AppBar(
      backgroundColor: context.colors.primaryContainer,
      foregroundColor: context.colors.onPrimaryContainer,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        tooltip: 'Cancel',
        onPressed: _clearSelection,
      ),
      title: Text('${_selected.length} selected'),
      actions: [
        IconButton(
          tooltip: 'Select all',
          icon: const Icon(Icons.select_all_rounded),
          onPressed: () => setState(() {
            _selected.addAll(p.filtered.map((t) => t.id));
          }),
        ),
        IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () => _deleteSelected(p),
        ),
      ],
    );
  }

  Widget _body(HistoryProvider p) {
    if (p.items.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        title: 'No history yet',
        message: 'Your translations will appear here.',
      );
    }
    final list = p.filtered;
    if (list.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final t = list[i];
        final selected = _selected.contains(t.id);
        return Dismissible(
          key: ValueKey(t.id),

          direction: _inSelectionMode
              ? DismissDirection.none
              : DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: context.colors.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: context.colors.onErrorContainer,
            ),
          ),
          onDismissed: (_) => _deleteOne(p, t),
          child: _Tile(
            t: t,
            selected: selected,
            selectionMode: _inSelectionMode,
            onTap: () {
              if (_inSelectionMode) _toggleSelect(t.id);
            },
            onLongPress: () => _toggleSelect(t.id),
          ),
        );
      },
    );
  }

  Future<void> _confirmClear(HistoryProvider p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.errorContainer,
              foregroundColor: context.colors.onErrorContainer,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) p.clearAll();
  }
}

class _Tile extends StatelessWidget {
  final Translation t;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _Tile({
    required this.t,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final src = Languages.byCode(t.sourceLang);
    final tgt = Languages.byCode(t.targetLang);
    return Card(
      color: selected ? context.colors.primaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
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
          leading: selectionMode
              ? Checkbox(value: selected, onChanged: (_) => onTap())
              : CircleAvatar(
                  backgroundColor: context.colors.primaryContainer,
                  child: Text(src.flag, style: const TextStyle(fontSize: 16)),
                ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(tgt.flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                DateFormat.MMMd().format(t.createdAt),
                style: context.text.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
