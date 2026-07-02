import 'package:hive/hive.dart';
import '../utils/constants.dart';
import 'package:easy_translate/models/app_settings.dart';

class SettingsRepository {
  static const _key = 'current';
  Box get _box => Hive.box(K.boxSettings);

  AppSettings read() {
    final raw = _box.get(_key);
    if (raw is! Map) return const AppSettings();
    var s = AppSettings.fromMap(raw);
    final storedVersion = (raw['schemaVersion'] as int?) ?? 0;
    if (storedVersion < AppSettings.schemaVersion) {
      s = _migrate(s, from: storedVersion);

      _box.put(_key, s.toMap());
    }
    return s;
  }

  AppSettings _migrate(AppSettings s, {required int from}) {
    if (from < 1) {
      if (s.defaultTarget == 'es') {
        s = s.copyWith(defaultTarget: 'en');
      }
    }
    if (from < 2) {
      if (s.defaultTarget == 'en' || s.defaultTarget == 'es') {
        s = s.copyWith(defaultTarget: 'hi');
      }
    }
    return s;
  }

  Future<void> write(AppSettings s) => _box.put(_key, s.toMap());

  Stream<AppSettings> watch() async* {
    yield read();
    yield* _box.watch(key: _key).asyncMap((_) async => read());
  }
}
