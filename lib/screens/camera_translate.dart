import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:easy_translate/Google_Ads/ShowAds.dart';
import 'package:easy_translate/models/language.dart';
import 'package:easy_translate/providers/deps.dart';
import 'package:easy_translate/services/ocr_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';
import '../widgets/language_picker.dart';
import '../widgets/translation_overlay.dart';

class CameraTranslateScreen extends StatefulWidget {
  const CameraTranslateScreen({super.key});
  @override
  State<CameraTranslateScreen> createState() => _CameraTranslateScreenState();
}

class _CameraTranslateScreenState extends State<CameraTranslateScreen>
    with WidgetsBindingObserver {
  CameraController? _ctrl;
  bool _initFailed = false;
  String? _initError;
  bool _torchOn = false;
  bool _initInFlight = false;
  bool _disposingController = false;
  Future<void>? _disposeFuture;

  String _source = 'auto';
  String _target = 'hi';

  String? _capturedPath;
  Size? _capturedSize;
  DeviceOrientation? _capturedOrientation;
  bool _busy = false;
  String? _runtimeError;
  List<TranslationOverlayBlock> _blocks = [];
  int _captureReq = 0;
  final Set<String> _tempFiles = {};

  bool _backHandling = false;
  Timer? _backFallback;

  Future<void> _handleBack() async {
    if (_backHandling) return;
    _backHandling = true;

    final navigator = Navigator.of(context);

    void doPop() {
      _backFallback?.cancel();
      _backFallback = null;
      if (!mounted) return;
      if (navigator.canPop()) navigator.pop();
      _backHandling = false;
    }

    _backFallback = Timer(const Duration(milliseconds: 2500), doPop);
    ShowInterstitialAds().showBackInterstitialAds(onBeforeShow: doPop);
  }

  void _trackTemp(String path) {
    _tempFiles.add(path);
  }

  Future<void> _deleteTrackedTemps() async {
    final paths = _tempFiles.toList(growable: false);
    _tempFiles.clear();
    for (final p in paths) {
      await _safeDelete(p);
    }
  }

  static const _orientationChannel = MethodChannel(
    'easy_translate/device_orientation',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isIOS) {
      unawaited(
        _orientationChannel.invokeMethod<void>('start').catchError((_) {}),
      );
    }
    _initCamera();
  }

  Future<DeviceOrientation?> _physicalOrientation() async {
    if (!Platform.isIOS) return null;
    try {
      final s = await _orientationChannel.invokeMethod<String>('get');
      switch (s) {
        case 'portraitUp':
          return DeviceOrientation.portraitUp;
        case 'portraitDown':
          return DeviceOrientation.portraitDown;
        case 'landscapeLeft':
          return DeviceOrientation.landscapeLeft;
        case 'landscapeRight':
          return DeviceOrientation.landscapeRight;
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      unawaited(_disposeController());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_resumeCamera());
    }
  }

  Future<void> _resumeCamera() async {
    final disposing = _disposeFuture;
    if (disposing != null) {
      try {
        await disposing;
      } catch (_) {}
    }
    if (!mounted) return;
    final ctrl = _ctrl;
    if (ctrl == null || !ctrl.value.isInitialized) {
      _initCamera();
    }
  }

  Future<void> _disposeController() {
    final existing = _disposeFuture;
    if (existing != null) return existing;
    final ctrl = _ctrl;
    if (ctrl == null) return Future<void>.value();
    _disposingController = true;
    _ctrl = null;
    if (mounted) {
      setState(() {});
    }
    final future = () async {
      try {
        await ctrl.dispose();
      } catch (_) {
      } finally {
        _disposingController = false;
        _disposeFuture = null;
      }
    }();
    _disposeFuture = future;
    return future;
  }

  Future<void> _initCamera() async {
    if (_initInFlight || _disposingController) return;
    _initInFlight = true;

    unawaited(ocr.warmUp(source: _source));

    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() {
          _initFailed = true;
          _initError = 'No cameras available on this device.';
        });
        return;
      }
      final backCams = cams
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .toList();
      final back = backCams.isEmpty
          ? cams.first
          : backCams.firstWhere(
              (c) => c.name == '0',
              orElse: () => backCams.first,
            );
      final ctrl = CameraController(
        back,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      try {
        await ctrl.lockCaptureOrientation(DeviceOrientation.portraitUp);
      } catch (_) {}
      final preview = ctrl.value.previewSize;
      if (preview != null) {
        debugPrint(
          '[camera] preview size after init: '
          '${preview.width.toInt()}x${preview.height.toInt()} '
          '(requested veryHigh = 1920x1080)',
        );
      }
      setState(() {
        _ctrl = ctrl;
        _initFailed = false;
        _initError = null;
      });
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _initFailed = true;
          _initError = _friendlyCameraError(e);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initFailed = true;
          _initError = e.toString();
        });
      }
    } finally {
      _initInFlight = false;
    }
  }

  String _friendlyCameraError(CameraException e) {
    final code = e.code.toLowerCase();
    if (code.contains('permission') ||
        code.contains('denied') ||
        code.contains('access')) {
      return 'Camera permission denied. Open Settings to enable it for this app.';
    }
    if (code.contains('inuse') || code.contains('busy')) {
      return 'Camera is in use by another app. Close it and try again.';
    }
    return e.description ?? e.toString();
  }

  @override
  void dispose() {
    _backFallback?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isIOS) {
      unawaited(
        _orientationChannel.invokeMethod<void>('stop').catchError((_) {}),
      );
    }
    final p = _capturedPath;
    if (p != null) {
      imageCache.evict(FileImage(File(p)));
    }
    unawaited(_deleteTrackedTemps());
    _ctrl?.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    final c = _ctrl;
    if (c == null || !c.value.isInitialized) return;
    final next = !_torchOn;
    try {
      await c.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      setState(() => _torchOn = next);
    } catch (_) {}
  }

  void _swapLangs() {
    if (_source == 'auto') return;
    setState(() {
      final tmp = _source;
      _source = _target;
      _target = tmp;
    });
    _retranslateIfNeeded();
  }

  Future<void> _pickSource() async {
    final l = await pickLanguage(context, includeAuto: true, selected: _source);
    if (l != null && mounted) {
      setState(() => _source = l.code);
      unawaited(ocr.warmUp(source: _source));
      _retranslateIfNeeded();
    }
  }

  Future<void> _pickTarget() async {
    final l = await pickLanguage(context, selected: _target);
    if (l != null && mounted) {
      setState(() => _target = l.code);
      _retranslateIfNeeded();
    }
  }

  int _retransReq = 0;

  Future<void> _retranslateIfNeeded() async {
    if (_capturedPath == null || _blocks.isEmpty) return;
    final req = ++_retransReq;
    final snapshot = List<TranslationOverlayBlock>.of(_blocks);
    final src = _source;
    final tgt = _target;
    setState(() {
      _busy = true;
      _runtimeError = null;
    });
    try {
      final unique = {for (final b in snapshot) b.original};
      const maxConcurrent = 6;
      final results = <String, String>{};
      var successCount = 0;
      final queue = unique.toList(growable: false);
      var index = 0;
      Future<void> worker() async {
        while (true) {
          final i = index++;
          if (i >= queue.length) break;
          final text = queue[i];
          try {
            final (out, _) = await translator.translate(
              text: text,
              source: src,
              target: tgt,
            );
            results[text] = out;
            successCount++;
          } catch (_) {
            results[text] = text;
          }
        }
      }

      await Future.wait([for (var i = 0; i < maxConcurrent; i++) worker()]);
      final next = [
        for (final b in snapshot)
          b.withTranslation(results[b.original] ?? b.original),
      ];
      final allFailed = unique.isNotEmpty && successCount == 0;
      if (!mounted || req != _retransReq) return;
      setState(() {
        _blocks = next;
        _runtimeError = allFailed
            ? 'Translation unavailable — check your connection.'
            : null;
      });
    } finally {
      if (mounted && req == _retransReq) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _disposeOldCapture() async {
    final old = _capturedPath;
    if (old == null) return;
    await _safeDelete(old);
  }

  Future<void> _capture() async {
    final c = _ctrl;
    if (c == null || !c.value.isInitialized || _busy) return;
    final req = ++_captureReq;
    setState(() {
      _busy = true;
      _runtimeError = null;
    });
    try {
      if (_torchOn) {
        try {
          await c.setFlashMode(FlashMode.off);
        } catch (_) {}
      }
      await _disposeOldCapture();

      final channel = await _physicalOrientation();
      final pluginOrientation = c.value.deviceOrientation;
      final hintOrientation = channel ?? pluginOrientation;

      final shot = await c.takePicture();
      if (!mounted || req != _captureReq) {
        unawaited(_safeDelete(shot.path));
        return;
      }

      if (_torchOn) {
        setState(() => _torchOn = false);
      }

      final baked = await bakeImageOrientation(
        shot.path,
        physicalOrientation: hintOrientation,
      );
      _trackTemp(baked.path);
      unawaited(_safeDelete(shot.path));
      if (!mounted || req != _captureReq) {
        unawaited(_safeDelete(baked.path));
        return;
      }

      if (!mounted || req != _captureReq) {
        unawaited(_safeDelete(baked.path));
        return;
      }
      try {
        await precacheImage(FileImage(File(baked.path)), context);
      } catch (_) {}
      if (!mounted || req != _captureReq) {
        unawaited(_safeDelete(baked.path));
        return;
      }

      setState(() {
        _capturedPath = baked.path;
        _capturedSize = baked.size;
        _capturedOrientation = hintOrientation;
        _blocks = [];
      });

      final ocrResult = await ocr.recognizeBlocksMultiRotation(
        baked.path,
        baked.size,
        source: _source,
        isCancelled: () => req != _captureReq,
      );
      if (req != _captureReq) {
        if (ocrResult.path != baked.path) {
          unawaited(_safeDelete(ocrResult.path));
        }
        return;
      }
      final blocks = ocrResult.blocks;
      if (ocrResult.path != baked.path) {
        _trackTemp(ocrResult.path);
        if (!mounted) {
          unawaited(_safeDelete(ocrResult.path));
          return;
        }
        try {
          await precacheImage(FileImage(File(ocrResult.path)), context);
        } catch (_) {}
        if (!mounted) {
          unawaited(_safeDelete(ocrResult.path));
          return;
        }
        unawaited(_safeDelete(baked.path));
        setState(() {
          _capturedPath = ocrResult.path;
          _capturedSize = ocrResult.size;
        });
      }

      final translated = await _translateBlocks(
        blocks,
        source: _source,
        target: _target,
      );
      if (req != _captureReq) return;

      if (!mounted || req != _captureReq) return;
      setState(() {
        _blocks = translated.blocks;
        _busy = false;
        _runtimeError = translated.allFailed
            ? 'Translation unavailable — check your connection.'
            : null;
      });
    } catch (e) {
      if (mounted && req == _captureReq) {
        setState(() {
          _runtimeError = e.toString();
          _busy = false;
        });
      }
    }
  }

  Future<void> _safeDelete(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      /* swallow */
    }
  }

  Future<({List<TranslationOverlayBlock> blocks, bool allFailed})>
  _translateBlocks(
    List<OcrBlock> blocks, {
    required String source,
    required String target,
  }) async {
    if (blocks.isEmpty) {
      return (blocks: const <TranslationOverlayBlock>[], allFailed: false);
    }

    final unique = <String>{for (final b in blocks) b.text};

    const maxConcurrent = 6;
    final results = <String, String>{};
    var successCount = 0;
    final queue = unique.toList(growable: false);
    var index = 0;

    Future<void> worker() async {
      while (true) {
        final i = index++;
        if (i >= queue.length) break;
        final text = queue[i];
        try {
          final (out, _) = await translator.translate(
            text: text,
            source: source,
            target: target,
          );
          results[text] = out;
          successCount++;
        } catch (_) {
          results[text] = text;
        }
      }
    }

    await Future.wait([for (var i = 0; i < maxConcurrent; i++) worker()]);

    final allFailed = unique.isNotEmpty && successCount == 0;
    return (
      blocks: [
        for (final b in blocks)
          TranslationOverlayBlock(
            b.text,
            results[b.text] ?? b.text,
            b.bbox,
            b.corners,
          ),
      ],
      allFailed: allFailed,
    );
  }

  void _retake() {
    _captureReq++;
    _retransReq++;
    final stale = _capturedPath;
    if (stale != null) {
      imageCache.evict(FileImage(File(stale)));
    }
    unawaited(_deleteTrackedTemps());
    setState(() {
      _capturedPath = null;
      _capturedSize = null;
      _capturedOrientation = null;
      _blocks = [];
      _runtimeError = null;
      _busy = false;
    });

    final c = _ctrl;
    if (c == null || !c.value.isInitialized) {
      _initCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _viewport(),
          if (_busy && _capturedPath != null) const TranslatingBanner(),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  sourceCode: _source,
                  targetCode: _target,
                  torchOn: _torchOn,
                  showTorch: _capturedPath == null && _ctrl != null,
                  onClose: _handleBack,
                  onPickSource: _pickSource,
                  onPickTarget: _pickTarget,
                  onSwap: _swapLangs,
                  onToggleTorch: _toggleTorch,
                ),
                const Spacer(),
                if (_runtimeError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _runtimeError!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                _BottomBar(
                  hasCaptured: _capturedPath != null,
                  busy: _busy,
                  emptyResult:
                      _capturedPath != null && _blocks.isEmpty && !_busy,
                  onCapture: _capture,
                  onRetake: _retake,
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _viewport() {
    if (_capturedPath != null && _capturedSize != null) {
      return _rotatedCaptureView(
        TranslationOverlay(
          imagePath: _capturedPath!,
          imageSize: _capturedSize!,
          blocks: _blocks,
        ),
      );
    }
    if (_capturedPath != null) {
      return _rotatedCaptureView(
        Center(child: Image.file(File(_capturedPath!), fit: BoxFit.contain)),
      );
    }
    if (_initFailed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _initError ?? 'Camera unavailable',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final c = _ctrl;
    if (c == null || !c.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    final preview = c.value.previewSize;
    if (preview == null) return CameraPreview(c);
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: preview.height,
          height: preview.width,
          child: CameraPreview(c),
        ),
      ),
    );
  }

  Widget _rotatedCaptureView(Widget child) {
    final turns = _displayTurnsForOrientation(_capturedOrientation);
    return turns == 0 ? child : RotatedBox(quarterTurns: turns, child: child);
  }

  int _displayTurnsForOrientation(DeviceOrientation? o) {
    switch (o) {
      case DeviceOrientation.landscapeRight:
        return 3;
      case DeviceOrientation.landscapeLeft:
        return 1;
      case DeviceOrientation.portraitDown:
        return 2;
      case DeviceOrientation.portraitUp:
      default:
        return 0;
    }
  }
}

class _TopBar extends StatelessWidget {
  final String sourceCode;
  final String targetCode;
  final bool torchOn;
  final bool showTorch;
  final VoidCallback onClose;
  final VoidCallback onPickSource;
  final VoidCallback onPickTarget;
  final VoidCallback onSwap;
  final VoidCallback onToggleTorch;
  const _TopBar({
    required this.sourceCode,
    required this.targetCode,
    required this.torchOn,
    required this.showTorch,
    required this.onClose,
    required this.onPickSource,
    required this.onPickTarget,
    required this.onSwap,
    required this.onToggleTorch,
  });

  @override
  Widget build(BuildContext context) {
    final src = Languages.byCode(sourceCode);
    final tgt = Languages.byCode(targetCode);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          _CircleButton(icon: Icons.close_rounded, onTap: onClose),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: _LangPill(language: src, onTap: onPickSource),
                  ),
                  IconButton(
                    iconSize: 18,
                    color: Colors.white,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    onPressed: onSwap,
                    tooltip: 'Swap',
                  ),
                  Expanded(
                    child: _LangPill(language: tgt, onTap: onPickTarget),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (showTorch)
            _CircleButton(
              icon: torchOn
                  ? Icons.flashlight_on_rounded
                  : Icons.flashlight_off_rounded,
              onTap: onToggleTorch,
              highlighted: torchOn,
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  final Language language;
  final VoidCallback onTap;
  const _LangPill({required this.language, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(language.flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                language.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted
          ? const Color(0xFFFACC15)
          : Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: highlighted ? Colors.black : Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool hasCaptured;
  final bool busy;
  final bool emptyResult;
  final VoidCallback onCapture;
  final VoidCallback onRetake;
  const _BottomBar({
    required this.hasCaptured,
    required this.busy,
    required this.emptyResult,
    required this.onCapture,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emptyResult)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'No text detected — try again',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          if (!hasCaptured)
            _ShutterButton(busy: busy, onTap: onCapture)
          else
            _PillButton(
              icon: Icons.refresh_rounded,
              label: 'Retake',
              onTap: onRetake,
            ),
        ],
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onTap;
  const _ShutterButton({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: busy ? 32 : 60,
            height: busy ? 32 : 60,
            decoration: BoxDecoration(
              color: busy ? Colors.white24 : Colors.white,
              shape: BoxShape.circle,
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(6),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.black87, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
