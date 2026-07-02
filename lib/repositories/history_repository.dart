import 'package:hive/hive.dart';
import '../utils/constants.dart';
import 'package:easy_translate/models/translation.dart';

class HistoryRepository {
  Box get _box => Hive.box(K.boxHistory);

  Future<void> save(Translation t) => _box.put(t.id, t.toMap());

  Future<void> remove(String id) => _box.delete(id);

  Future<void> removeMany(Iterable<String> ids) => _box.deleteAll(ids);

  Future<void> clear() => _box.clear();

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
