import 'dart:async';
import 'deps.dart';
import 'package:easy_translate/models/translation.dart';
import 'package:flutter/foundation.dart';

class HistoryProvider extends ChangeNotifier {
  List<Translation> items = [];
  String query = '';
  StreamSubscription? _sub;

  List<Translation> get filtered {
    if (query.isEmpty) return items;
    final q = query.toLowerCase();
    return items
        .where(
          (t) =>
              t.sourceText.toLowerCase().contains(q) ||
              t.translatedText.toLowerCase().contains(q),
        )
        .toList();
  }

  void load() {
    items = historyRepo.getAll();
    notifyListeners();
    _sub ??= historyRepo.watch().listen((list) {
      items = list;
      notifyListeners();
    });
  }

  void search(String q) {
    query = q;
    notifyListeners();
  }

  Future<void> remove(String id) => historyRepo.remove(id);

  Future<void> removeMany(Iterable<String> ids) => historyRepo.removeMany(ids);

  Future<void> restore(Translation t) => historyRepo.save(t);

  Future<void> clearAll() => historyRepo.clear();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
