import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart' show compute;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

class OcrBlock {
  final String text;
  final Rect bbox;
  final List<Offset> corners;
  const OcrBlock(this.text, this.bbox, this.corners);
}

class OcrService {
  final Map<TextRecognitionScript, TextRecognizer> _recognizers = {};
  final Set<TextRecognitionScript> _warmedUp = {};
  Future<void>? _warmingUp;

  TextRecognizer _get(TextRecognitionScript script) {
    return _recognizers.putIfAbsent(
      script,
      () => TextRecognizer(script: script),
    );
  }

  Future<void> warmUp({String source = 'auto'}) async {
    final scripts = scriptsForLanguage(source);
    if (scripts.every(_warmedUp.contains)) return;

    final inFlight = _warmingUp;
    if (inFlight != null) {
      try {
        await inFlight;
      } catch (_) {}
    }

    final missing = scripts.where((s) => !_warmedUp.contains(s)).toList();
    if (missing.isEmpty) return;

    final future = _doWarmUp(missing).whenComplete(() {
      _warmingUp = null;
    });
    _warmingUp = future;
    return future;
  }

  Future<void> _doWarmUp(List<TextRecognitionScript> scripts) async {
    File? dummy;
    try {
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));
      final bytes = img.encodePng(image, level: 1);
      dummy = File(
        '${Directory.systemTemp.path}/ocr_warmup_'
        '${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await dummy.writeAsBytes(bytes);

      for (final script in scripts) {
        if (_warmedUp.contains(script)) continue;
        try {
          await _get(script).processImage(InputImage.fromFilePath(dummy.path));
          _warmedUp.add(script);
        } catch (_) {}
      }
    } catch (_) {
    } finally {
      try {
        if (dummy != null && await dummy.exists()) await dummy.delete();
      } catch (_) {}
    }
  }

  Future<String> recognize(
    String path, {
    TextRecognitionScript script = TextRecognitionScript.latin,
  }) async {
    final result = await _get(
      script,
    ).processImage(InputImage.fromFilePath(path));
    return result.text;
  }

  Future<String> recognizeForLanguage(
    String path, {
    String source = 'auto',
  }) async {
    final blocks = await recognizeBlocks(path, source: source);
    final ordered = List<OcrBlock>.from(blocks)
      ..sort((a, b) {
        final top = a.bbox.top.compareTo(b.bbox.top);
        if (top != 0) return top;
        return a.bbox.left.compareTo(b.bbox.left);
      });
    return ordered
        .map((b) => b.text.trim())
        .where((t) => t.isNotEmpty)
        .join('\n');
  }

  Future<List<OcrBlock>> recognizeBlocks(
    String path, {
    String source = 'auto',
    List<TextRecognitionScript>? scripts,
  }) async {
    final activeScripts = scripts ?? scriptsForLanguage(source);
    final input = InputImage.fromFilePath(path);
    final perScript = await Future.wait(
      activeScripts.map((s) async {
        try {
          final r = await _get(s).processImage(input);
          return _extractLineBlocks(r);
        } catch (_) {
          return <OcrBlock>[];
        }
      }),
    );
    return _mergeAndDeduplicate(perScript.expand((l) => l).toList());
  }

  Future<({List<OcrBlock> blocks, String path, Size size})>
  recognizeBlocksMultiRotation(
    String path,
    Size size, {
    String source = 'auto',
    bool lazy = true,
    int lazyThreshold = 3,
    bool parallel = true,
    bool Function()? isCancelled,
  }) async {
    final activeScripts = scriptsForLanguage(source);

    final originalInput = InputImage.fromFilePath(path);
    final originalPerScript = await Future.wait(
      activeScripts.map((s) async {
        try {
          final r = await _get(s).processImage(originalInput);
          return _extractLineBlocks(r);
        } catch (_) {
          return <OcrBlock>[];
        }
      }),
    );
    final original = _mergeAndDeduplicate(
      originalPerScript.expand((l) => l).toList(),
    );

    if (lazy && original.length >= lazyThreshold) {
      return (blocks: original, path: path, size: size);
    }

    if (isCancelled?.call() ?? false) {
      return (blocks: original, path: path, size: size);
    }

    const angles = [90, -90, 180];

    List<_RotatedFile> rotatedFiles;
    try {
      rotatedFiles = await compute(
        _rotateImageFiles,
        _RotateRequest(path, angles),
      );
    } catch (_) {
      return (blocks: original, path: path, size: size);
    }
    if (rotatedFiles.isEmpty) {
      return (blocks: original, path: path, size: size);
    }

    Future<({String path, Size size, List<OcrBlock> blocks})> runRotation(
      _RotatedFile file,
    ) async {
      final rotatedPath = file.path;
      final rotatedSize = Size(file.width.toDouble(), file.height.toDouble());

      if (isCancelled?.call() ?? false) {
        return (
          path: rotatedPath,
          size: rotatedSize,
          blocks: const <OcrBlock>[],
        );
      }

      final input = InputImage.fromFilePath(rotatedPath);
      final perScript = await Future.wait(
        activeScripts.map((s) async {
          try {
            final r = await _get(s).processImage(input);
            return _extractLineBlocks(r);
          } catch (_) {
            return <OcrBlock>[];
          }
        }),
      );
      final blocks = _mergeAndDeduplicate(perScript.expand((l) => l).toList());
      return (path: rotatedPath, size: rotatedSize, blocks: blocks);
    }

    final variants = <({String path, Size size, List<OcrBlock> blocks})>[];
    variants.add((path: path, size: size, blocks: original));

    if (parallel) {
      final results = await Future.wait(rotatedFiles.map(runRotation));
      variants.addAll(results);
    } else {
      for (final file in rotatedFiles) {
        variants.add(await runRotation(file));
      }
    }

    variants.sort((a, b) {
      final byCount = b.blocks.length.compareTo(a.blocks.length);
      if (byCount != 0) return byCount;
      int chars(List<OcrBlock> bl) =>
          bl.fold<int>(0, (sum, x) => sum + x.text.length);
      return chars(b.blocks).compareTo(chars(a.blocks));
    });
    final best = variants.first;

    for (final v in variants) {
      if (v.path == best.path) continue;
      if (v.path == path) continue;
      try {
        final f = File(v.path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }

    return (blocks: best.blocks, path: best.path, size: best.size);
  }

  List<TextRecognitionScript> scriptsForLanguage(String source) {
    final code = source.trim().toLowerCase();
    if (code.isEmpty || code == 'auto') {
      return const [
        TextRecognitionScript.latin,
        TextRecognitionScript.devanagiri,
      ];
    }

    if (_devanagariLanguages.contains(code)) {
      return const [
        TextRecognitionScript.devanagiri,
        TextRecognitionScript.latin,
      ];
    }
    if (_chineseLanguages.contains(code)) {
      return const [TextRecognitionScript.chinese, TextRecognitionScript.latin];
    }
    if (_japaneseLanguages.contains(code)) {
      return const [
        TextRecognitionScript.japanese,
        TextRecognitionScript.latin,
      ];
    }
    if (_koreanLanguages.contains(code)) {
      return const [TextRecognitionScript.korean, TextRecognitionScript.latin];
    }
    return const [TextRecognitionScript.latin];
  }

  List<OcrBlock> _extractLineBlocks(RecognizedText result) {
    final lines = <OcrBlock>[];
    for (final block in result.blocks) {
      if (block.lines.isEmpty) {
        if (block.text.trim().isEmpty) continue;
        lines.add(
          OcrBlock(
            block.text,
            block.boundingBox,
            block.cornerPoints
                .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
                .toList(),
          ),
        );
        continue;
      }

      for (final line in block.lines) {
        if (line.text.trim().isEmpty) continue;
        lines.add(
          OcrBlock(
            line.text,
            line.boundingBox,
            line.cornerPoints
                .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
                .toList(),
          ),
        );
      }
    }
    return lines;
  }

  List<OcrBlock> _mergeAndDeduplicate(List<OcrBlock> all) {
    if (all.isEmpty) return all;
    all.sort((a, b) => _qualityScore(b).compareTo(_qualityScore(a)));
    final kept = <OcrBlock>[];
    for (final block in all) {
      final isDup = kept.any((k) => _overlapsHeavily(block.bbox, k.bbox));
      if (!isDup) kept.add(block);
    }
    return kept;
  }

  int _qualityScore(OcrBlock b) {
    final letters = RegExp(r'\p{L}', unicode: true).allMatches(b.text).length;
    return letters * 4 + b.text.length;
  }

  bool _overlapsHeavily(Rect a, Rect b) {
    final inter = a.intersect(b);
    if (inter.width <= 0 || inter.height <= 0) return false;
    final interArea = inter.width * inter.height;
    final areaA = a.width * a.height;
    final areaB = b.width * b.height;
    final smaller = areaA < areaB ? areaA : areaB;
    if (smaller <= 0) return false;
    return interArea / smaller >= 0.6;
  }

  void dispose() {
    for (final r in _recognizers.values) {
      r.close();
    }
    _recognizers.clear();
  }
}

const _devanagariLanguages = {'hi', 'mr', 'ne'};

const _chineseLanguages = {'zh'};

const _japaneseLanguages = {'ja'};

const _koreanLanguages = {'ko'};

class _RotateRequest {
  final String path;
  final List<int> angles;
  const _RotateRequest(this.path, this.angles);
}

class _RotatedFile {
  final String path;
  final int width;
  final int height;
  const _RotatedFile(this.path, this.width, this.height);
}

List<_RotatedFile> _rotateImageFiles(_RotateRequest req) {
  final bytes = File(req.path).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return const <_RotatedFile>[];

  final out = <_RotatedFile>[];
  for (final angle in req.angles) {
    final rotated = img.copyRotate(decoded, angle: angle);
    final tag = angle.toString().replaceAll('-', 'n');
    final rotatedPath = '${req.path}_rot$tag.png';
    try {
      File(rotatedPath).writeAsBytesSync(img.encodePng(rotated, level: 1));
      out.add(_RotatedFile(rotatedPath, rotated.width, rotated.height));
    } catch (_) {}
  }
  return out;
}
