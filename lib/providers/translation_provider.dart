import 'dart:async';
import 'deps.dart';

import '../utils/constants.dart';
import '../utils/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_translate/models/language.dart';
import 'package:easy_translate/models/translation.dart';

class TranslationProvider extends ChangeNotifier {
  Language source = Languages.byCode(currentAppSettings.defaultSource);
  Language target = Languages.byCode(currentAppSettings.defaultTarget);

  void applyDefaults() {
    source = Languages.byCode(currentAppSettings.defaultSource);
    target = Languages.byCode(currentAppSettings.defaultTarget);
    notifyListeners();
  }

  String input = '';
  bool isLoading = false;
  bool isListening = false;
  String? error;
  Translation? result;
  String? detectedCode;

  Timer? _debounce;

  int _reqId = 0;

  void setInput(String value, {bool autoTranslate = true}) {
    input = value.censored;
    if (error != null) error = null;
    notifyListeners();
    if (autoTranslate && input.trim().isNotEmpty) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), translate);
    }
  }

  void setSource(Language l) {
    source = l;
    _debounce?.cancel();
    notifyListeners();
    if (input.trim().isNotEmpty) translate();
  }

  void setTarget(Language l) {
    target = l;
    _debounce?.cancel();
    notifyListeners();
    if (input.trim().isNotEmpty) translate();
  }

  void swap() {
    final newSrc = source.isAuto
        ? Languages.byCode(detectedCode ?? result?.sourceLang ?? 'en')
        : source;
    source = target;
    target = newSrc;
    if (result?.translatedText.isNotEmpty == true) {
      input = result!.translatedText;
    }
    notifyListeners();
    if (input.trim().isNotEmpty) translate();
  }

  Future<void> translate({
    TranslationOrigin origin = TranslationOrigin.text,
  }) async {
    final text = input.trim();
    if (text.isEmpty) return;

    if (text.hasCensorMark || text.hasProfanity) {
      result = Translation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sourceText: text.censored,
        translatedText: text.censored,
        sourceLang: source.code,
        targetLang: target.code,
        createdAt: DateTime.now(),
        origin: origin,
      );
      error = 'Profanity not translated.';
      notifyListeners();
      return;
    }

    final req = ++_reqId;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final src = source.code;
      final tgt = target.code;
      final (out, detected) = await translator.translate(
        text: text,
        source: src,
        target: tgt,
      );

      if (req != _reqId) return;
      result = Translation(
        id: uuid.v4(),
        sourceText: text.censored,
        translatedText: out.censored,
        sourceLang: detected.isEmpty ? src : detected,
        targetLang: tgt,
        createdAt: DateTime.now(),
        origin: origin,
      );
      detectedCode = result!.sourceLang;
      if (currentAppSettings.saveHistory) {
        unawaited(historyRepo.save(result!));
      }
      if (currentAppSettings.autoSpeak) {
        unawaited(
          tts.speak(
            result!.translatedText,
            lang: result!.targetLang,
            rate: currentAppSettings.speechRate,
          ),
        );
      }
    } catch (e) {
      if (req == _reqId) error = e.toString();
    } finally {
      if (req == _reqId) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> toggleFavorite() async {
    final t = result;
    if (t == null) return;
    if (t.isFavorite) {
      await favoritesRepo.remove(t.id);
      result = t.copyWith(isFavorite: false);
    } else {
      await favoritesRepo.add(t);
      result = t.copyWith(isFavorite: true);
    }
    notifyListeners();
  }

  Future<String> copy() async {
    await Clipboard.setData(ClipboardData(text: result?.translatedText ?? ''));
    return S.copied;
  }

  Future<void> share() async {
    final t = result;
    if (t == null) return;
    await SharePlus.instance.share(
      ShareParams(text: '${t.sourceText}\n\n→ ${t.translatedText}'),
    );
  }

  Future<void> speakResult() async {
    final t = result;
    if (t != null) {
      await tts.speak(
        t.translatedText,
        lang: t.targetLang,
        rate: currentAppSettings.speechRate,
      );
    }
  }

  Future<void> speakInput() async {
    if (input.trim().isEmpty) return;
    final lang = source.isAuto ? (detectedCode ?? 'en') : source.code;
    await tts.speak(input, lang: lang, rate: currentAppSettings.speechRate);
  }

  int _listenSession = 0;

  Future<void> startListening() async {
    if (!await speech.init()) {
      error = 'Microphone unavailable.';
      notifyListeners();
      return;
    }
    final session = ++_listenSession;
    isListening = true;
    notifyListeners();
    await speech.listen(
      localeId: source.isAuto ? null : source.code,
      onResult: (text, isFinal) {
        if (session != _listenSession) return;
        input = text;
        notifyListeners();
        if (isFinal) {
          if (session != _listenSession) return;
          isListening = false;
          notifyListeners();
          if (text.trim().isNotEmpty) {
            translate(origin: TranslationOrigin.voice);
          }
        }
      },
    );
  }

  Future<void> stopListening() async {
    _listenSession++;
    await speech.stop();
    isListening = false;
    notifyListeners();
  }

  void clear() {
    input = '';
    result = null;
    detectedCode = null;
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _listenSession++;
    try {
      unawaited(speech.cancel());
    } catch (_) {}
    try {
      unawaited(tts.stop());
    } catch (_) {}
    super.dispose();
  }
}
