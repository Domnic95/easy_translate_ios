import 'package:hive/hive.dart';
import '../utils/constants.dart';
import 'package:easy_translate/models/conversation_message.dart';

class ConversationRepository {
  Box get _box => Hive.box(K.boxConversations);

  Future<void> append(ConversationMessage m) => _box.put(m.id, m.toMap());

  Future<void> clear() => _box.clear();

  List<ConversationMessage> getAll() {
    final list = _box.values
        .whereType<Map>()
        .map(ConversationMessage.fromMap)
        .toList();
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  Stream<List<ConversationMessage>> watch() async* {
    yield getAll();
    yield* _box.watch().asyncMap((_) async => getAll());
  }
}
