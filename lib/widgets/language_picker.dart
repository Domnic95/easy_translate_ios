import 'package:easy_translate/models/language.dart';
import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/extensions.dart';

Future<Language?> pickLanguage(
  BuildContext context, {
  bool includeAuto = false,
  String? selected,
}) {
  return showModalBottomSheet<Language>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _LangPicker(includeAuto: includeAuto, selected: selected),
  );
}

class _LangPicker extends StatefulWidget {
  final bool includeAuto;
  final String? selected;
  const _LangPicker({required this.includeAuto, this.selected});

  @override
  State<_LangPicker> createState() => _LangPickerState();
}

class _LangPickerState extends State<_LangPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final all = [if (widget.includeAuto) Languages.auto, ...Languages.all];
    final q = _q.toLowerCase();
    final filtered = q.isEmpty
        ? all
        : all
              .where(
                (l) =>
                    l.name.toLowerCase().contains(q) ||
                    l.nativeName.toLowerCase().contains(q),
              )
              .toList();
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              TextField(
                onChanged: (v) => setState(() => _q = v),
                decoration: const InputDecoration(
                  hintText: 'Search languages',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final l = filtered[i];
                    final sel = l.code == widget.selected;
                    return ListTile(
                      leading: Text(
                        l.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(l.name),
                      subtitle: l.nativeName == l.name
                          ? null
                          : Text(l.nativeName),
                      trailing: sel
                          ? Icon(
                              Icons.check_rounded,
                              color: context.colors.primary,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(l),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
