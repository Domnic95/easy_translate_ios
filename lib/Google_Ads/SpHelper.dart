import 'package:shared_preferences/shared_preferences.dart';

class SpHelper {
  static SharedPreferences? _preferences;

  static const _kClickKey = "click_count";
  static const _kBackClickKey = "back_click_count";

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static Future<SharedPreferences> _ensureInitialized() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  static Future<void> incrementClick() async {
    final prefs = await _ensureInitialized();
    final click = await getclick();
    await prefs.setInt(_kClickKey, click + 1);
  }

  static Future<int> getclick() async {
    final prefs = await _ensureInitialized();
    return prefs.getInt(_kClickKey) ?? 0;
  }

  static Future<void> resetClick() async {
    final prefs = await _ensureInitialized();
    await prefs.remove(_kClickKey);
  }

  static Future<void> incrementBackClick() async {
    final prefs = await _ensureInitialized();
    final click = await getBackClick();
    await prefs.setInt(_kBackClickKey, click + 1);
  }

  static Future<int> getBackClick() async {
    final prefs = await _ensureInitialized();
    return prefs.getInt(_kBackClickKey) ?? 0;
  }

  static Future<void> resetBackClick() async {
    final prefs = await _ensureInitialized();
    await prefs.remove(_kBackClickKey);
  }
}
