import 'package:easy_translate/providers/deps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _warmedUp = false;
  Future<void>? _warmFuture;
  String? _lastLang;
  double? _lastRate;
  Future<void> _speakLock = Future<void>.value();

  final Map<String, DateTime> _knownUnavailable = {};
  static const _unavailableTtl = Duration(minutes: 5);
  void clearUnavailableCache() => _knownUnavailable.clear();

  Future<void> warmUp() async {
    if (_warmedUp) return;
    return _warmFuture ??= _doWarmUp();
  }

  Future<void> _doWarmUp() async {
    try {
      await _tts.setSharedInstance(true);
    } catch (_) {}
    try {
      await _tts.awaitSpeakCompletion(false);
    } catch (_) {}
    _warmedUp = true;
  }

  Future<void> speak(
    String text, {
    required String lang,
    double rate = 0.5,
  }) {
    final next = _speakLock
        .catchError((_) {})
        .then((_) => _speakLocked(text, lang: lang, rate: rate));
    _speakLock = next;
    return next;
  }

  Future<void> _speakLocked(
    String text, {
    required String lang,
    required double rate,
  }) async {
    if (text.trim().isEmpty) return;
    if (!_warmedUp) await warmUp();

    if (!await _isAvailable(lang)) {
      _showUnavailableToast();
      return;
    }

    if (_lastRate != rate) {
      await _tts.setSpeechRate(rate);
      _lastRate = rate;
    }
    if (_lastLang != lang) {
      await _tts.setLanguage(lang);
      _lastLang = lang;
    }

    try {
      await _tts.stop();
    } catch (_) {}
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();

  Future<bool> _isAvailable(String lang) async {
    final cachedAt = _knownUnavailable[lang];
    if (cachedAt != null &&
        DateTime.now().difference(cachedAt) < _unavailableTtl) {
      return false;
    } else if (cachedAt != null) {
      _knownUnavailable.remove(lang);
    }
    try {
      final result = await _tts.isLanguageAvailable(lang);
      final available = result == true || result == 1;
      if (!available) {
        _knownUnavailable[lang] = DateTime.now();
      }
      return available;
    } catch (_) {
      _knownUnavailable[lang] = DateTime.now();
      return false;
    }
  }

  void _showUnavailableToast() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final messenger = ScaffoldMessenger.maybeOf(ctx);
    if (messenger == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text("Voice playback isn't available for this language."),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
  }
}
