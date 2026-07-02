import 'package:hive/hive.dart';
import '../utils/constants.dart';
import 'package:easy_translate/models/translation.dart';

class FavoritesRepository {
  Box get _box => Hive.box(K.boxFavorites);

  Future<void> add(Translation t) =>
      _box.put(t.id, t.copyWith(isFavorite: true).toMap());

  Future<void> remove(String id) => _box.delete(id);

  List<Translation> getAll() {
    final list = _box.values.whereType<Map>().map(Translation.fromMap).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Stream<List<Translation>> watch() async* {
    yield getAll();
    yield* _box.watch().asyncMap((_) async => getAll());
  }
}
