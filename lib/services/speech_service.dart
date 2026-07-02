import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _ready = false;
  List<stt.LocaleName>? _locales;
  String? _systemLocaleId;

  void Function(String status)? _onStatus;
  void Function(String error)? _onError;

  int _session = 0;

  bool get isListening => _ready && _stt.isListening;

  Future<bool> init() async {
    if (_ready) return true;
    _ready = await _stt.initialize(
      onStatus: (status) => _onStatus?.call(status),
      onError: (e) => _onError?.call(e.errorMsg),
    );
    if (_ready) {
      _locales = await _stt.locales();
      _systemLocaleId = (await _stt.systemLocale())?.localeId;
    }
    return _ready;
  }

  Future<String?> resolveLocaleId(String? languageCode) async {
    if (!_ready) await init();
    if (!_ready) return null;

    final code = languageCode?.trim().toLowerCase();
    if (code == null || code.isEmpty || code == 'auto') {
      return _systemLocaleId;
    }

    final aliases = <String>{code, ..._localeAliases(code)};
    final locales = _locales ?? const <stt.LocaleName>[];
    for (final candidate in aliases) {
      final normalizedCandidate = _normalizeLocale(candidate);
      for (final locale in locales) {
        if (_normalizeLocale(locale.localeId) == normalizedCandidate) {
          return locale.localeId;
        }
      }
    }

    for (final candidate in aliases) {
      final normalizedCandidate = _normalizeLocale(candidate);
      for (final locale in locales) {
        final normalizedLocale = _normalizeLocale(locale.localeId);
        if (normalizedLocale.startsWith('${normalizedCandidate}_')) {
          return locale.localeId;
        }
      }
    }

    return code;
  }

  Future<void> listen({
    String? localeId,
    required void Function(String text, bool isFinal) onResult,
    void Function(String status)? onStatus,
    void Function(String error)? onError,
    Duration listenFor = const Duration(seconds: 90),
    Duration pauseFor = const Duration(seconds: 6),
  }) async {
    if (!_ready) await init();
    final s = ++_session;
    _onStatus = onStatus == null
        ? null
        : (status) {
            if (s == _session) onStatus(status);
          };
    _onError = onError == null
        ? null
        : (err) {
            if (s == _session) onError(err);
          };
    final resolvedLocaleId = await resolveLocaleId(localeId);
    await _stt.listen(
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        autoPunctuation: true,
        localeId: resolvedLocaleId,
        listenFor: listenFor,
        pauseFor: pauseFor,
      ),
      onResult: (r) {
        if (s == _session) onResult(r.recognizedWords, r.finalResult);
      },
    );
  }

  Future<void> stop() async {
    _session++;
    try {
      await _stt.stop();
    } catch (_) {}
    _onStatus = null;
    _onError = null;
  }

  Future<void> cancel() async {
    _session++;
    try {
      await _stt.cancel();
    } catch (_) {}
    _onStatus = null;
    _onError = null;
  }

  Set<String> _localeAliases(String code) {
    switch (code) {
      case 'he':
        return {'iw'};
      case 'iw':
        return {'he'};
      case 'jv':
        return {'jw'};
      case 'jw':
        return {'jv'};
      case 'fil':
        return {'tl'};
      case 'tl':
        return {'fil'};
      default:
        return const {};
    }
  }

  String _normalizeLocale(String locale) =>
      locale.toLowerCase().replaceAll('-', '_');
}
