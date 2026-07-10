import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:easy_translate/providers/deps.dart';

class FullscreenAdCover {
  FullscreenAdCover._(this._entry, this._controller);

  final OverlayEntry _entry;
  final _CoverController _controller;
  bool _removed = false;

  static const Duration _fadeOut = Duration(milliseconds: 220);

  static FullscreenAdCover? show() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      log('FullscreenAdCover: no navigator context; skipping cover.');
      return null;
    }
    final overlay = Overlay.maybeOf(ctx, rootOverlay: true);
    if (overlay == null) {
      log('FullscreenAdCover: no overlay in context; skipping cover.');
      return null;
    }
    final controller = _CoverController();
    final entry = OverlayEntry(
      builder: (_) => _CoverWidget(controller: controller),
    );
    overlay.insert(entry);
    return FullscreenAdCover._(entry, controller);
  }

  Future<void> removeWithFade() async {
    if (_removed) return;
    _removed = true;
    try {
      await _controller.fadeOut(_fadeOut);
    } catch (e) {
      log('FullscreenAdCover: fadeOut threw: $e');
    }
    try {
      _entry.remove();
    } catch (e) {
      log('FullscreenAdCover: entry.remove threw: $e');
    }
  }

  void removeImmediate() {
    if (_removed) return;
    _removed = true;
    try {
      _entry.remove();
    } catch (e) {
      log('FullscreenAdCover: immediate remove threw: $e');
    }
  }
}

class _CoverController {
  _CoverWidgetState? _state;

  Future<void> fadeOut(Duration duration) {
    final s = _state;
    if (s == null) return Future<void>.value();
    return s.fadeOut(duration);
  }
}

class _CoverWidget extends StatefulWidget {
  final _CoverController controller;
  const _CoverWidget({required this.controller});

  @override
  State<_CoverWidget> createState() => _CoverWidgetState();
}

class _CoverWidgetState extends State<_CoverWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1),
      value: 1.0,
    );
    widget.controller._state = this;
  }

  Future<void> fadeOut(Duration duration) async {
    _c.duration = duration;
    await _c.animateTo(0, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    if (widget.controller._state == this) {
      widget.controller._state = null;
    }
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: _c,
        child: const ColoredBox(color: Colors.black, child: SizedBox.expand()),
      ),
    );
  }
}
