import 'dart:async';
import 'dart:developer';
import 'dart:ui';

class NativeAdGate {
  static final NativeAdGate _instance = NativeAdGate._();
  factory NativeAdGate() => _instance;

  NativeAdGate._() {
    _safetyTimer = Timer(const Duration(seconds: 15), () {
      if (!_isOpen) {
        log('[NativeAdGate] safety timeout (15s) — opening gate.');
        open();
      }
    });
  }

  bool _isOpen = false;
  final List<VoidCallback> _listeners = [];
  Timer? _safetyTimer;
  bool get isOpen => _isOpen;

  void open() {
    if (_isOpen) return;
    _isOpen = true;
    _safetyTimer?.cancel();
    _safetyTimer = null;
    log('[NativeAdGate] opened — native ads can now load.');
    final snapshot = List<VoidCallback>.from(_listeners);
    _listeners.clear();
    for (final l in snapshot) {
      try {
        l();
      } catch (e, st) {
        log('[NativeAdGate] listener threw: $e\n$st');
      }
    }
  }

  Future<void> waitForOpen() {
    if (_isOpen) return Future.value();
    final completer = Completer<void>();
    _listeners.add(completer.complete);
    return completer.future;
  }
}
