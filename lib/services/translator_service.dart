import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:translator/translator.dart' as gt;

class TranslatorService {
  final gt.GoogleTranslator _translator = gt.GoogleTranslator();
  final LanguageIdentifier _identifier = LanguageIdentifier(
    confidenceThreshold: 0.5,
  );

  static const int _chunkLimit = 800;
  static const int _perCallTimeoutSec = 10;
  static const int _maxAttempts = 3;
  static const int _backoffBaseMs = 200;

  Future<(String, String)> translate({
    required String text,
    required String source,
    required String target,
  }) async {
    final input = text;
    if (input.trim().isEmpty) return ('', source);
    final normalizedSource = _normalizeTranslatorCode(source, isTarget: false);
    final normalizedTarget = _normalizeTranslatorCode(target, isTarget: true);
    final trimmed = input.trim();
    if (trimmed.length <= 220 && !trimmed.contains('\n')) {
      try {
        final res = await _translator
            .translate(trimmed, from: normalizedSource, to: normalizedTarget)
            .timeout(const Duration(seconds: 5));
        final cleaned = _decodeHtmlEntities(res.text);
        if (cleaned.trim().isNotEmpty) {
          return (cleaned, _normalizeAppCode(res.sourceLanguage.code));
        }
      } catch (_) {}
    }

    final paragraphs = input.split(RegExp(r'\n\n+'));
    final outParagraphs = <String>[];
    String detected = source;
    var firstPiece = true;

    for (final paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) {
        outParagraphs.add('');
        continue;
      }
      final lines = paragraph.split('\n');
      final outLines = <String>[];
      for (final line in lines) {
        if (line.trim().isEmpty) {
          outLines.add('');
          continue;
        }
        final units = _splitIntoUnits(line, _chunkLimit);
        final outUnits = <String>[];
        for (final unit in units) {
          final res = await _translateUnit(
            unit,
            source: normalizedSource,
            target: normalizedTarget,
          );
          outUnits.add(res.text);
          if (firstPiece) {
            detected = _normalizeAppCode(res.detected);
            firstPiece = false;
          }
        }
        outLines.add(_joinUnits(outUnits));
      }
      outParagraphs.add(outLines.join('\n'));
    }
    return (outParagraphs.join('\n\n'), detected);
  }

  Future<({String text, String detected})> _translateUnit(
    String unit, {
    required String source,
    required String target,
  }) async {
    Object? lastErr;
    String? best;
    String? bestDetected;
    int bestScore = -1;
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      try {
        final res = await _translator
            .translate(unit, from: source, to: target)
            .timeout(Duration(seconds: _perCallTimeoutSec));
        final cleaned = _decodeHtmlEntities(res.text);
        final score = _completenessScore(unit, cleaned);
        if (score > bestScore) {
          best = cleaned;
          bestDetected = _normalizeAppCode(res.sourceLanguage.code);
          bestScore = score;
        }
        if (score >= 2) {
          return (
            text: cleaned,
            detected: _normalizeAppCode(res.sourceLanguage.code),
          );
        }
        if (attempt < _maxAttempts - 1) {
          await Future.delayed(
            Duration(milliseconds: _backoffBaseMs * (attempt + 1)),
          );
        }
      } catch (e) {
        lastErr = e;
        if (attempt < _maxAttempts - 1) {
          await Future.delayed(
            Duration(milliseconds: _backoffBaseMs * (attempt + 1)),
          );
        }
      }
    }
    if (best != null) {
      return (text: best, detected: _normalizeAppCode(bestDetected ?? source));
    }
    throw lastErr ?? Exception('Translation failed');
  }

  String _normalizeTranslatorCode(String code, {required bool isTarget}) {
    final normalized = code.trim().toLowerCase();
    switch (normalized) {
      case 'auto':
        return isTarget ? 'en' : 'auto';
      case 'zh':
        return 'zh-cn';
      case 'he':
        return 'iw';
      case 'jv':
        return 'jw';
      case 'fil':
        return 'tl';
      default:
        return normalized;
    }
  }

  String _normalizeAppCode(String code) {
    final normalized = code.trim().toLowerCase();
    switch (normalized) {
      case 'zh-cn':
      case 'zh-tw':
        return 'zh';
      case 'he':
        return 'iw';
      case 'jv':
        return 'jw';
      case 'fil':
        return 'tl';
      default:
        return normalized;
    }
  }

  List<String> _splitIntoUnits(String text, int limit) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [];
    if (trimmed.length <= limit) return [trimmed];

    final result = <String>[];
    final sentences = trimmed.split(RegExp(r'(?<=[.!?।॥।。!?…])\s+'));
    var buf = StringBuffer();

    void flushBuf() {
      final s = buf.toString().trim();
      if (s.isNotEmpty) result.add(s);
      buf = StringBuffer();
    }

    for (final sentence in sentences) {
      final s = sentence.trim();
      if (s.isEmpty) continue;
      if (s.length > limit) {
        flushBuf();
        final pieces = s.split(RegExp(r'(?<=[,،;:])\s+'));
        var inner = StringBuffer();
        void flushInner() {
          final x = inner.toString().trim();
          if (x.isNotEmpty) result.add(x);
          inner = StringBuffer();
        }

        for (final piece in pieces) {
          final p = piece.trim();
          if (p.isEmpty) continue;
          if (p.length > limit) {
            flushInner();
            var i = 0;
            while (i < p.length) {
              final end = (i + limit).clamp(0, p.length);
              result.add(p.substring(i, end));
              i = end;
            }
            continue;
          }
          if (inner.length + p.length + 1 > limit) flushInner();
          if (inner.isNotEmpty) inner.write(' ');
          inner.write(p);
        }
        flushInner();
        continue;
      }
      if (buf.length + s.length + 1 > limit) flushBuf();
      if (buf.isNotEmpty) buf.write(' ');
      buf.write(s);
    }
    flushBuf();
    return result;
  }

  String _joinUnits(List<String> units) {
    if (units.isEmpty) return '';
    final out = StringBuffer();
    for (var i = 0; i < units.length; i++) {
      final u = units[i].trim();
      if (u.isEmpty) continue;
      if (out.isNotEmpty) {
        out.write(' ');
      }
      out.write(u);
    }
    return out.toString();
  }

  int _completenessScore(String input, String output) {
    final out = output.trim();
    if (out.isEmpty) return 0;
    final inp = input.trim();
    if (inp.isEmpty) return 2;
    final inputWords = inp
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final outputChars = out.length;
    final inputChars = inp.length;
    if (inputWords <= 3) {
      return outputChars > 0 ? 2 : 0;
    }
    if (outputChars * 4 < inputChars) return 1;

    if (!RegExp(r'\p{L}', unicode: true).hasMatch(out)) return 1;
    return 2;
  }

  String _decodeHtmlEntities(String input) {
    if (input.isEmpty || !input.contains('&')) return input;
    final replacements = <String, String>{
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#39;': "'",
      '&apos;': "'",
      '&nbsp;': ' ',
      '&hellip;': '…',
      '&mdash;': '—',
      '&ndash;': '–',
      '&laquo;': '«',
      '&raquo;': '»',
      '&lsquo;': '‘',
      '&rsquo;': '’',
      '&ldquo;': '“',
      '&rdquo;': '”',
    };
    var s = input;
    replacements.forEach((k, v) => s = s.replaceAll(k, v));
    s = s.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final code = int.tryParse(m.group(1) ?? '');
      if (code == null) return m.group(0)!;
      return String.fromCharCode(code);
    });
    s = s.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
      final code = int.tryParse(m.group(1) ?? '', radix: 16);
      if (code == null) return m.group(0)!;
      return String.fromCharCode(code);
    });
    return s;
  }

  Future<String> detect(String text) async {
    if (text.trim().isEmpty) return 'und';
    return _identifier.identifyLanguage(text);
  }
}
