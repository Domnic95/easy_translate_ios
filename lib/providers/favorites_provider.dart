import 'dart:async';
import 'deps.dart';
import 'package:easy_translate/models/translation.dart';
import 'package:flutter/foundation.dart';

class FavoritesProvider extends ChangeNotifier {
  List<Translation> items = [];
  StreamSubscription? _sub;

  void load() {
    items = favoritesRepo.getAll();
    notifyListeners();
    _sub ??= favoritesRepo.watch().listen((list) {
      items = list;
      notifyListeners();
    });
  }

  Future<void> remove(String id) => favoritesRepo.remove(id);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
