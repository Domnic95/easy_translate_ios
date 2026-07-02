import 'dart:async';
import 'dart:developer';
import 'deps.dart';
import 'package:easy_translate/models/conversation_message.dart';
import 'package:easy_translate/utils/speech_merge.dart';
import 'package:flutter/foundation.dart';

class ConversationProvider extends ChangeNotifier {
  String leftLang = currentAppSettings.defaultSource == 'auto'
      ? 'en'
      : currentAppSettings.defaultSource;
  String rightLang = currentAppSettings.defaultTarget;

  void applyDefaults() {
    leftLang = currentAppSettings.defaultSource == 'auto'
        ? 'en'
        : currentAppSettings.defaultSource;
    rightLang = currentAppSettings.defaultTarget;
    notifyListeners();
  }

  bool? activeSide;
  String partial = '';
  String? error;
  List<ConversationMessage> messages = [];

  bool isTranslating = false;
  String? pendingOriginal;
  bool? pendingFromLeft;

  bool get isBusy => activeSide != null || isTranslating;

  StreamSubscription? _sub;

  int _listenId = 0;
  int _msgReqId = 0;

  bool _wantsListening = false;

  void init() {
    messages = conversationRepo.getAll();
    notifyListeners();
    _sub ??= conversationRepo.watch().listen((list) {
      messages = list;
      notifyListeners();
    });
  }

  void setLeft(String c) {
    if (c == leftLang) return;
    leftLang = c;
    _onLangChange(leftChanged: true);
  }

  void setRight(String c) {
    if (c == rightLang) return;
    rightLang = c;
    _onLangChange(leftChanged: false);
  }

  void _onLangChange({required bool leftChanged}) {
    notifyListeners();

    final side = activeSide;
    if (side != null && side == leftChanged) {
      unawaited(_listen(side));
    }

    final text = pendingOriginal;
    final fromLeft = pendingFromLeft;
    if ((isTranslating || text != null) && text != null && fromLeft != null) {
      _msgReqId++;
      isTranslating = false;
      pendingOriginal = null;
      pendingFromLeft = null;
      notifyListeners();
      final src = fromLeft ? leftLang : rightLang;
      final tgt = fromLeft ? rightLang : leftLang;
      unawaited(_translateAndAppend(text, fromLeft, src, tgt));
    }

    unawaited(_retranslateHistoryToCurrentLangs());
  }

  int _retranslateBatch = 0;
  bool isRetranslating = false;

  Future<void> _retranslateHistoryToCurrentLangs() async {
    if (messages.isEmpty) return;
    final myBatch = ++_retranslateBatch;
    final candidates = messages
        .where((m) {
          final currentTarget = m.isLeftSpeaker ? rightLang : leftLang;
          return m.targetLang != currentTarget;
        })
        .toList(growable: false);

    if (candidates.isEmpty) return;

    isRetranslating = true;
    notifyListeners();

    try {
      for (final m in candidates) {
        if (myBatch != _retranslateBatch) return;
        final newTarget = m.isLeftSpeaker ? rightLang : leftLang;
        if (m.targetLang == newTarget) continue;
        try {
          final (out, _) = await translator.translate(
            text: m.original,
            source: m.sourceLang,
            target: newTarget,
          );
          if (myBatch != _retranslateBatch) return;
          await conversationRepo.append(
            m.copyWith(translated: out, targetLang: newTarget),
          );
        } catch (e) {
          log('Conversation: failed to re-translate message ${m.id}: $e');
        }
      }
    } finally {
      if (myBatch == _retranslateBatch) {
        isRetranslating = false;
        notifyListeners();
      }
    }
  }

  Future<void> listenLeft() => _listen(true);
  Future<void> listenRight() => _listen(false);

  Future<void> stopListening() async {
    final wasLeft = activeSide;
    final captured = partial.trim();

    _wantsListening = false;
    _listenId++;
    activeSide = null;
    partial = '';
    notifyListeners();

    try {
      await speech.stop();
    } catch (_) {}
    if (wasLeft != null && captured.isNotEmpty) {
      final src = wasLeft ? leftLang : rightLang;
      final tgt = wasLeft ? rightLang : leftLang;
      await _translateAndAppend(captured, wasLeft, src, tgt);
    }
  }

  Future<void> _listen(bool isLeft) async {
    unawaited(tts.stop());

    if (activeSide != null) {
      _wantsListening = false;
      _listenId++;
      try {
        await speech.stop();
      } catch (_) {}
      activeSide = null;
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    if (!await speech.init()) {
      error = 'Speech recogniser unavailable';
      notifyListeners();
      return;
    }
    final session = ++_listenId;
    _wantsListening = true;
    activeSide = isLeft;
    partial = '';
    error = null;
    notifyListeners();

    final src = isLeft ? leftLang : rightLang;

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
      if (finalised || session != _listenId) return;
      finalised = true;
      _wantsListening = false;
      silenceTimer?.cancel();
      restartDebounce?.cancel();
      activeSide = null;
      notifyListeners();
      try {
        await speech.stop();
      } catch (_) {}
      if (text.trim().isEmpty) return;
      final liveSrc = isLeft ? leftLang : rightLang;
      final liveTgt = isLeft ? rightLang : leftLang;
      await _translateAndAppend(text, isLeft, liveSrc, liveTgt);
    }

    void armSilenceTimer(Duration gap) {
      silenceTimer?.cancel();
      silenceTimer = Timer(gap, () async {
        if (!finalised && session == _listenId) await finalise(partial);
      });
    }

    Future<void> startInner() async {
      if (finalised || session != _listenId) return;
      if (DateTime.now().difference(sessionStart) > sessionTimeout) {
        await finalise(partial);
        return;
      }
      await speech.listen(
        localeId: src,
        onResult: (text, isFinal) async {
          if (session != _listenId || finalised || !_wantsListening) return;
          if (text.isEmpty) return;
          restartDebounce?.cancel();
          partial = smartMergeSpeech(accumulated, text);
          notifyListeners();
          armSilenceTimer(silenceGap);
        },
        onStatus: (status) async {
          if (session != _listenId || finalised || !_wantsListening) return;
          if (status == 'listening') {
            sawListening = true;
            restartDebounce?.cancel();
            return;
          }
          if ((status == 'notListening' || status == 'done') && sawListening) {
            if (partial.isNotEmpty) accumulated = partial;
            restartDebounce?.cancel();
            restartDebounce = Timer(restartDebounceGap, () async {
              if (session != _listenId || finalised || !_wantsListening) {
                return;
              }
              await startInner();
            });
          }
        },
        onError: (err) async {
          if (session != _listenId || finalised || !_wantsListening) return;
          if (!sawListening) return;
          if (partial.isNotEmpty) accumulated = partial;
          restartDebounce?.cancel();
          restartDebounce = Timer(const Duration(milliseconds: 320), () async {
            if (session != _listenId || finalised || !_wantsListening) {
              return;
            }
            await startInner();
          });
        },
      );
    }

    armSilenceTimer(initialGrace);
    await startInner();
  }

  Future<void> _translateAndAppend(
    String text,
    bool isLeft,
    String src,
    String tgt,
  ) async {
    final req = ++_msgReqId;
    isTranslating = true;
    pendingOriginal = text;
    pendingFromLeft = isLeft;
    error = null;
    notifyListeners();
    try {
      final (out, _) = await translator.translate(
        text: text,
        source: src,
        target: tgt,
      );

      if (req != _msgReqId) return;
      await conversationRepo.append(
        ConversationMessage(
          id: uuid.v4(),
          original: text,
          translated: out,
          sourceLang: src,
          targetLang: tgt,
          isLeftSpeaker: isLeft,
          timestamp: DateTime.now(),
        ),
      );

      if (currentAppSettings.autoSpeak) {
        unawaited(
          tts.speak(out, lang: tgt, rate: currentAppSettings.speechRate),
        );
      }
    } catch (e) {
      if (req == _msgReqId) error = e.toString();
    } finally {
      if (req == _msgReqId) {
        isTranslating = false;
        pendingOriginal = null;
        pendingFromLeft = null;
        notifyListeners();
      }
    }
  }

  Future<void> clear() => conversationRepo.clear();

  Future<void> resetAll() async {
    await cleanupTransient();
    await conversationRepo.clear();

    messages = [];
    notifyListeners();
  }

  Future<void> cleanupTransient() async {
    _wantsListening = false;
    _listenId++;
    _msgReqId++;
    try {
      await speech.cancel();
    } catch (_) {}
    try {
      await tts.stop();
    } catch (_) {}
    activeSide = null;
    partial = '';
    isTranslating = false;
    pendingOriginal = null;
    pendingFromLeft = null;
    error = null;
    notifyListeners();
  }

  String exportText() {
    final buf = StringBuffer();
    for (final m in messages) {
      buf.writeln(
        '[${m.isLeftSpeaker ? 'A' : 'B'} · ${m.sourceLang} → ${m.targetLang}]',
      );
      buf.writeln(m.original);
      buf.writeln('→ ${m.translated}');
      buf.writeln();
    }
    return buf.toString();
  }

  @override
  void dispose() {
    _sub?.cancel();
    try {
      unawaited(speech.cancel());
    } catch (_) {}
    try {
      unawaited(tts.stop());
    } catch (_) {}
    super.dispose();
  }
}
