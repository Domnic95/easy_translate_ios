import 'dart:async';
import 'dart:io';

import 'package:easy_translate/Google_Ads/ShowAds.dart';
import 'package:easy_translate/models/language.dart';
import 'package:easy_translate/providers/deps.dart';
import 'package:easy_translate/services/ocr_service.dart';
import 'package:easy_translate/widgets/language_picker.dart';
import 'package:easy_translate/utils/error_messages.dart';
import 'package:easy_translate/widgets/translation_overlay.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/constants.dart';

class GalleryTranslateScreen extends StatefulWidget {
  const GalleryTranslateScreen({super.key});
  @override
  State<GalleryTranslateScreen> createState() => _GalleryTranslateScreenState();
}

class _GalleryTranslateScreenState extends State<GalleryTranslateScreen> {
  final _picker = ImagePicker();

  String _source = 'auto';
  String _target = 'hi';

  String? _imagePath;
  Size? _imageSize;
  bool _busy = false;
  String? _error;
  List<TranslationOverlayBlock> _blocks = [];

  int _retransReq = 0;
  int _pickReq = 0;
  bool _openedOnce = false;
  final Set<String> _tempFiles = {};

  bool _backHandling = false;
  Timer? _backFallback;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _openedOnce) return;
      _openedOnce = true;
      _pickAndProcess();
    });
  }

  @override
  void dispose() {
    _backFallback?.cancel();
    final stale = _imagePath;
    if (stale != null) {
      imageCache.evict(FileImage(File(stale)));
    }
    unawaited(_deleteTrackedTemps());
    super.dispose();
  }

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

  Future<void> _pickAndProcess() async {
    if (_busy) return;
    final req = ++_pickReq;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (picked == null) {
        if (mounted && req == _pickReq) setState(() => _busy = false);
        if (_imagePath == null && mounted) Navigator.of(context).maybePop();
        return;
      }

      final previous = _imagePath;
      if (previous != null) {
        imageCache.evict(FileImage(File(previous)));
      }
      unawaited(_deleteTrackedTemps());

      final baked = await bakeImageOrientation(picked.path);
      _trackTemp(baked.path);
      unawaited(_safeDelete(picked.path));

      if (!mounted || req != _pickReq) return;
      setState(() {
        _imagePath = baked.path;
        _imageSize = baked.size;
        _blocks = [];
      });

      final ocrResult = await ocr.recognizeBlocksMultiRotation(
        baked.path,
        baked.size,
        source: _source,
        isCancelled: () => req != _pickReq,
      );
      if (req != _pickReq) {
        if (ocrResult.path != baked.path) {
          unawaited(_safeDelete(ocrResult.path));
        }
        return;
      }
      if (ocrResult.path != baked.path) {
        _trackTemp(ocrResult.path);
        if (!mounted) {
          unawaited(_safeDelete(ocrResult.path));
          return;
        }
        unawaited(_safeDelete(baked.path));
        setState(() {
          _imagePath = ocrResult.path;
          _imageSize = ocrResult.size;
        });
      }

      final translated = await _translateBlocks(
        ocrResult.blocks,
        source: _source,
        target: _target,
      );

      if (!mounted || req != _pickReq) return;
      setState(() {
        _blocks = translated.blocks;
        _busy = false;
        _error = translated.allFailed
            ? 'Translation unavailable — check your connection.'
            : null;
      });
    } catch (e) {
      if (mounted && req == _pickReq) {
        setState(() {
          _error = friendlyTranslationError(e);
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

  Future<void> _retranslateIfNeeded() async {
    if (_imagePath == null || _blocks.isEmpty) return;
    final req = ++_retransReq;
    final snapshot = List<TranslationOverlayBlock>.of(_blocks);
    final src = _source;
    final tgt = _target;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final unique = <String>{for (final b in snapshot) b.original};
      final r = await _translateStrings(
        unique.toList(growable: false),
        source: src,
        target: tgt,
      );
      final next = [
        for (final b in snapshot)
          b.withTranslation(r.results[b.original] ?? b.original),
      ];
      final allFailed = unique.isNotEmpty && r.successes == 0;
      if (!mounted || req != _retransReq) return;
      setState(() {
        _blocks = next;
        _error = allFailed
            ? 'Translation unavailable — check your connection.'
            : null;
      });
    } finally {
      if (mounted && req == _retransReq) {
        setState(() => _busy = false);
      }
    }
  }

  Future<({Map<String, String> results, int successes})> _translateStrings(
    List<String> unique, {
    required String source,
    required String target,
  }) async {
    const maxConcurrent = 6;
    final results = <String, String>{};
    var successes = 0;
    var index = 0;
    Future<void> worker() async {
      while (true) {
        final i = index++;
        if (i >= unique.length) break;
        final text = unique[i];
        try {
          final (out, _) = await translator.translate(
            text: text,
            source: source,
            target: target,
          );
          results[text] = out;
          successes++;
        } catch (_) {
          results[text] = text;
        }
      }
    }

    await Future.wait([for (var i = 0; i < maxConcurrent; i++) worker()]);
    return (results: results, successes: successes);
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
    final r = await _translateStrings(
      unique.toList(growable: false),
      source: source,
      target: target,
    );
    return (
      blocks: [
        for (final b in blocks)
          TranslationOverlayBlock(
            b.text,
            r.results[b.text] ?? b.text,
            b.bbox,
            b.corners,
          ),
      ],
      allFailed: unique.isNotEmpty && r.successes == 0,
    );
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
          if (_busy && _imagePath != null) const TranslatingBanner(),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  source: Languages.byCode(_source),
                  target: Languages.byCode(_target),
                  onClose: _handleBack,
                  onPickSource: _pickSource,
                  onPickTarget: _pickTarget,
                  onSwap: _swapLangs,
                ),
                const Spacer(),
                if (_error != null)
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
                        _error!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                _BottomBar(
                  hasImage: _imagePath != null,
                  busy: _busy,
                  emptyResult: _imagePath != null && _blocks.isEmpty && !_busy,
                  onPick: _pickAndProcess,
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
    if (_imagePath != null && _imageSize != null) {
      return TranslationOverlay(
        imagePath: _imagePath!,
        imageSize: _imageSize!,
        blocks: _blocks,
      );
    }
    if (_busy) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Pick a photo to translate',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final Language source;
  final Language target;
  final VoidCallback onClose;
  final VoidCallback onPickSource;
  final VoidCallback onPickTarget;
  final VoidCallback onSwap;
  const _TopBar({
    required this.source,
    required this.target,
    required this.onClose,
    required this.onPickSource,
    required this.onPickTarget,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
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
                    child: _LangPill(language: source, onTap: onPickSource),
                  ),
                  IconButton(
                    iconSize: 18,
                    color: Colors.white,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    onPressed: onSwap,
                    tooltip: 'Swap',
                  ),
                  Expanded(
                    child: _LangPill(language: target, onTap: onPickTarget),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
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
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool hasImage;
  final bool busy;
  final bool emptyResult;
  final VoidCallback onPick;
  const _BottomBar({
    required this.hasImage,
    required this.busy,
    required this.emptyResult,
    required this.onPick,
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
                  'No text detected — try another photo',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          Material(
            color: Colors.white,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: busy ? null : onPick,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasImage
                          ? Icons.photo_library_rounded
                          : Icons.photo_library_outlined,
                      color: Colors.black87,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasImage ? 'Pick another' : 'Pick photo',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
