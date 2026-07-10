import 'dart:async';
import 'deps.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:easy_translate/models/translation.dart';
import 'package:easy_translate/utils/error_messages.dart';
import 'package:easy_translate/utils/speech_merge.dart';

class VoiceProvider extends ChangeNotifier {
  String source = currentAppSettings.defaultSource == 'auto'
      ? 'en'
      : currentAppSettings.defaultSource;
  String target = currentAppSettings.defaultTarget;

  void applyDefaults() {
    source = currentAppSettings.defaultSource == 'auto'
        ? 'en'
        : currentAppSettings.defaultSource;
    target = currentAppSettings.defaultTarget;
    notifyListeners();
  }

  bool isListening = false;
  bool isTranslating = false;
  String partial = '';
  Translation? result;
  String? error;

  int _reqId = 0;

  bool _wantsListening = false;

  void resetSync() {
    _reqId++;
    _wantsListening = false;
    isListening = false;
    isTranslating = false;
    partial = '';
    result = null;
    error = null;

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> reset() async {
    resetSync();
    try {
      await speech.cancel();
    } catch (_) {}
    try {
      await tts.stop();
    } catch (_) {}
  }

  void setSource(String c) {
    source = c;
    notifyListeners();
    _retranslate();
  }

  void setTarget(String c) {
    target = c;
    notifyListeners();
    _retranslate();
  }

  Future<void> _retranslate() async {
    final text = (result?.sourceText ?? partial).trim();
    if (text.isEmpty) return;
    final req = ++_reqId;
    final previousId = result?.id;
    isTranslating = true;
    notifyListeners();
    try {
      final (out, _) = await translator.translate(
        text: text,
        source: source,
        target: target,
      );
      if (req != _reqId) return;
      result = Translation(
        id: previousId ?? uuid.v4(),
        sourceText: text,
        translatedText: out,
        sourceLang: source,
        targetLang: target,
        createdAt: DateTime.now(),
        origin: TranslationOrigin.voice,
      );
      error = null;
      if (currentAppSettings.saveHistory) {
        unawaited(historyRepo.save(result!));
      }
      if (currentAppSettings.autoSpeak) {
        unawaited(
          tts.speak(out, lang: target, rate: currentAppSettings.speechRate),
        );
      }
    } catch (e) {
      if (req == _reqId) error = friendlyTranslationError(e);
    } finally {
      if (req == _reqId) {
        isTranslating = false;
        notifyListeners();
      }
    }
  }

  Future<void> start() async {
    unawaited(tts.stop());
    if (!await speech.init()) {
      error = 'Microphone unavailable.';
      notifyListeners();
      return;
    }
    final session = ++_reqId;
    _wantsListening = true;
    partial = '';
    isListening = true;
    error = null;
    notifyListeners();

    bool finalised = false;
    bool sawListening = false;
    String accumulated = '';
    Timer? silenceTimer;
    Timer? restartDebounce;
    const silenceGap = Duration(seconds: 2);
    const initialGrace = Duration(seconds: 8);
    const sessionTimeout = Duration(seconds: 90);
    const restartDebounceGap = Duration(milliseconds: 280);
    final sessionStart = DateTime.now();

    Future<void> finalise(String text) async {
      if (finalised || session != _reqId) return;
      finalised = true;
      _wantsListening = false;
      silenceTimer?.cancel();
      restartDebounce?.cancel();
      isListening = false;
      notifyListeners();
      try {
        await speech.stop();
      } catch (_) {}
      if (text.trim().isEmpty) return;
      await _translateAndSpeak(text, session);
    }

    void armSilenceTimer(Duration gap) {
      silenceTimer?.cancel();
      silenceTimer = Timer(gap, () async {
        if (!finalised && session == _reqId) await finalise(partial);
      });
    }

    Future<void> startInner() async {
      if (finalised || session != _reqId) return;
      if (DateTime.now().difference(sessionStart) > sessionTimeout) {
        await finalise(partial);
        return;
      }
      await speech.listen(
        localeId: source,
        onResult: (text, isFinal) async {
          if (session != _reqId || finalised || !_wantsListening) return;
          if (text.isEmpty) return;
          restartDebounce?.cancel();
          partial = smartMergeSpeech(accumulated, text);
          notifyListeners();
          armSilenceTimer(silenceGap);
        },
        onStatus: (status) async {
          if (session != _reqId || finalised || !_wantsListening) return;
          if (status == 'listening') {
            sawListening = true;
            restartDebounce?.cancel();
            return;
          }
          if ((status == 'notListening' || status == 'done') && sawListening) {
            if (partial.isNotEmpty) accumulated = partial;
            restartDebounce?.cancel();
            restartDebounce = Timer(restartDebounceGap, () async {
              if (session != _reqId || finalised || !_wantsListening) return;
              await startInner();
            });
          }
        },
        onError: (err) async {
          if (session != _reqId || finalised || !_wantsListening) return;
          if (!sawListening) return;
          if (partial.isNotEmpty) accumulated = partial;
          restartDebounce?.cancel();
          restartDebounce = Timer(const Duration(milliseconds: 320), () async {
            if (session != _reqId || finalised || !_wantsListening) return;
            await startInner();
          });
        },
      );
    }

    armSilenceTimer(initialGrace);
    await startInner();
  }

  Future<void> stop() async {
    final translateSession = ++_reqId;
    final captured = partial.trim();
    _wantsListening = false;
    isListening = false;
    notifyListeners();
    try {
      await speech.stop();
    } catch (_) {}
    if (captured.isNotEmpty) {
      await _translateAndSpeak(captured, translateSession);
    }
  }

  @override
  void dispose() {
    _reqId++;
    _wantsListening = false;
    try {
      unawaited(speech.cancel());
    } catch (_) {}
    try {
      unawaited(tts.stop());
    } catch (_) {}
    super.dispose();
  }

  Future<void> _translateAndSpeak(String text, int session) async {
    isTranslating = true;
    notifyListeners();
    try {
      final (out, _) = await translator.translate(
        text: text,
        source: source,
        target: target,
      );
      if (session != _reqId) return;
      result = Translation(
        id: uuid.v4(),
        sourceText: text,
        translatedText: out,
        sourceLang: source,
        targetLang: target,
        createdAt: DateTime.now(),
        origin: TranslationOrigin.voice,
      );
      if (currentAppSettings.saveHistory) {
        unawaited(historyRepo.save(result!));
      }
      if (currentAppSettings.autoSpeak) {
        unawaited(
          tts.speak(out, lang: target, rate: currentAppSettings.speechRate),
        );
      }
    } catch (e) {
      if (session == _reqId) error = friendlyTranslationError(e);
    } finally {
      if (session == _reqId) {
        isTranslating = false;
        notifyListeners();
      }
    }
  }
}
