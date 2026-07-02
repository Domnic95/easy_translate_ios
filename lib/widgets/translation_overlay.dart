import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image/image.dart' as img;

class TranslationOverlayBlock {
  final String original;
  final String translated;
  final Rect bbox;
  final List<Offset> corners;
  const TranslationOverlayBlock(
    this.original,
    this.translated,
    this.bbox,
    this.corners,
  );

  TranslationOverlayBlock withTranslation(String newTranslated) =>
      TranslationOverlayBlock(original, newTranslated, bbox, corners);
}

class TranslationOverlay extends StatelessWidget {
  final String imagePath;
  final Size imageSize;
  final List<TranslationOverlayBlock> blocks;
  const TranslationOverlay({
    super.key,
    required this.imagePath,
    required this.imageSize,
    required this.blocks,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final imgAspect = imageSize.width / imageSize.height;
        final boxAspect = constraints.maxWidth / constraints.maxHeight;
        late final double dispW, dispH;
        if (imgAspect > boxAspect) {
          dispW = constraints.maxWidth;
          dispH = dispW / imgAspect;
        } else {
          dispH = constraints.maxHeight;
          dispW = dispH * imgAspect;
        }
        final offX = (constraints.maxWidth - dispW) / 2;
        final offY = (constraints.maxHeight - dispH) / 2;
        final sx = dispW / imageSize.width;
        final sy = dispH / imageSize.height;
        return Stack(
          children: [
            Positioned.fill(
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
            for (final b in blocks)
              _RotatedLabel(block: b, offX: offX, offY: offY, sx: sx, sy: sy),
          ],
        );
      },
    );
  }
}

class _RotatedLabel extends StatelessWidget {
  final TranslationOverlayBlock block;
  final double offX, offY, sx, sy;
  const _RotatedLabel({
    required this.block,
    required this.offX,
    required this.offY,
    required this.sx,
    required this.sy,
  });

  @override
  Widget build(BuildContext context) {
    if (block.corners.length < 4) {
      final bx = offX + block.bbox.left * sx;
      final by = offY + block.bbox.top * sy;
      final bw = (block.bbox.width * sx).clamp(40.0, double.infinity);
      final bh = (block.bbox.height * sy).clamp(12.0, double.infinity);
      return _floating(bx, by, bw, bh, 0);
    }
    final c = block.corners
        .map((p) => Offset(offX + p.dx * sx, offY + p.dy * sy))
        .toList();
    final topVec = c[1] - c[0];
    final leftVec = c[3] - c[0];
    final width = topVec.distance.clamp(40.0, double.infinity);
    final height = leftVec.distance.clamp(12.0, double.infinity);
    final angle = math.atan2(topVec.dy, topVec.dx);
    return _floating(c[0].dx, c[0].dy, width, height, angle);
  }

  Widget _floating(
    double pivotX,
    double pivotY,
    double width,
    double height,
    double angle,
  ) {
    final boxWidth = width.clamp(48.0, double.infinity);
    const fontSize = 12.0;
    return Positioned(
      left: pivotX,
      top: pivotY,
      child: Transform.rotate(
        angle: angle,
        alignment: Alignment.topLeft,
        child:
            Container(
                  width: boxWidth,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 3,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    block.translated,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF111111),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                )
                .animate(key: ValueKey(block.translated))
                .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                .scaleXY(
                  begin: 0.94,
                  end: 1,
                  duration: 260.ms,
                  curve: Curves.easeOutBack,
                ),
      ),
    );
  }
}

class TranslatingBanner extends StatelessWidget {
  const TranslatingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 108),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Translating…',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 180.ms),
        ),
      ),
    );
  }
}

class _BakeArgs {
  final String inputPath;
  final int physicalOrientationIndex;
  const _BakeArgs(this.inputPath, this.physicalOrientationIndex);
}

class _BakeResult {
  final String? path;
  final double width;
  final double height;
  final int exifIndex;
  const _BakeResult(this.path, this.width, this.height, this.exifIndex);
}

_BakeResult _bakeOnWorker(_BakeArgs args) {
  final bytes = File(args.inputPath).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return const _BakeResult(null, 0, 0, -1);
  }

  int? exifValue;
  try {
    exifValue = decoded.exif.imageIfd.orientation;
  } catch (_) {
    exifValue = null;
  }
  final exifIdx = _exifToIndex(exifValue);
  final exifDevice = _indexToDeviceOrientation(exifIdx);
  final physicalDevice = _indexToDeviceOrientation(
    args.physicalOrientationIndex,
  );
  final resolved = physicalDevice ?? exifDevice;

  img.Image baked = img.bakeOrientation(decoded);

  if (resolved != null) {
    final imgIsLandscape = baked.width > baked.height;
    final orientationIsLandscape =
        resolved == DeviceOrientation.landscapeLeft ||
        resolved == DeviceOrientation.landscapeRight;

    if (imgIsLandscape != orientationIsLandscape) {
      final int angle;
      if (orientationIsLandscape) {
        angle = resolved == DeviceOrientation.landscapeLeft ? -90 : 90;
      } else {
        angle = resolved == DeviceOrientation.portraitDown ? -90 : 90;
      }
      baked = img.copyRotate(baked, angle: angle);
    } else if (resolved == DeviceOrientation.portraitDown && !imgIsLandscape) {
      baked = img.copyRotate(baked, angle: 180);
    }
  }

  baked = img.adjustColor(baked, contrast: 1.15);
  baked = img.convolution(
    baked,
    filter: const <num>[0, -1, 0, -1, 5, -1, 0, -1, 0],
    div: 1,
    offset: 0,
  );

  final pngBytes = img.encodePng(baked, level: 1);
  final outPath = '${args.inputPath}_baked.png';
  File(outPath).writeAsBytesSync(pngBytes);
  return _BakeResult(
    outPath,
    baked.width.toDouble(),
    baked.height.toDouble(),
    exifIdx,
  );
}

int _exifToIndex(int? exif) {
  switch (exif) {
    case 1:
      return DeviceOrientation.portraitUp.index;
    case 3:
      return DeviceOrientation.portraitDown.index;
    case 6:
      return DeviceOrientation.landscapeRight.index;
    case 8:
      return DeviceOrientation.landscapeLeft.index;
    default:
      return -1;
  }
}

DeviceOrientation? _indexToDeviceOrientation(int idx) {
  if (idx < 0 || idx >= DeviceOrientation.values.length) return null;
  return DeviceOrientation.values[idx];
}

Future<({String path, Size size, DeviceOrientation? exifOrientation})>
bakeImageOrientation(
  String inputPath, {
  DeviceOrientation? physicalOrientation,
}) async {
  final result = await compute(
    _bakeOnWorker,
    _BakeArgs(inputPath, physicalOrientation?.index ?? -1),
  );

  if (result.path != null) {
    return (
      path: result.path!,
      size: Size(result.width, result.height),
      exifOrientation: _indexToDeviceOrientation(result.exifIndex),
    );
  }

  final bytes = await File(inputPath).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final size = Size(image.width.toDouble(), image.height.toDouble());
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (png == null) {
    return (path: inputPath, size: size, exifOrientation: null);
  }
  final outPath = '${inputPath}_baked.png';
  await File(outPath).writeAsBytes(png.buffer.asUint8List());
  return (path: outPath, size: size, exifOrientation: null);
}
