import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:easy_translate/Google_Ads/ConfigController.dart';
import 'package:easy_translate/Google_Ads/ConfigModel.dart';
import 'package:easy_translate/Google_Ads/Native_Ads/ExpandedNativeAdShimmer.dart';
import 'package:easy_translate/providers/deps.dart';
import 'package:easy_translate/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ExpandedNativeAdManager extends StatefulWidget {
  const ExpandedNativeAdManager({super.key, this.height = 336});

  final double height;

  @override
  State<ExpandedNativeAdManager> createState() =>
      _ExpandedNativeAdManagerState();
}

class _ExpandedNativeAdManagerState extends State<ExpandedNativeAdManager> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _failed = false;
  bool? _currentIsDark;
  int _retryCount = 0;
  Timer? _retryTimer;
  VoidCallback? _configListener;

  static const int _maxRetries = 5;

  Duration _nextRetryDelay() {
    final seconds = 2 * (1 << _retryCount);
    return Duration(seconds: seconds > 30 ? 30 : seconds);
  }

  @override
  void initState() {
    super.initState();
    final isDark =
        PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    _currentIsDark = isDark;
    _initIfEnabled(isDark: isDark);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newIsDark = Theme.of(context).brightness == Brightness.dark;
    if (newIsDark != _currentIsDark) {
      _currentIsDark = newIsDark;
      _reload(newIsDark);
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _detachConfigListener();
    _nativeAd?.dispose();
    super.dispose();
  }

  void _detachConfigListener() {
    final l = _configListener;
    if (l == null) return;
    configController.removeListener(l);
    _configListener = null;
  }

  void _waitForConfigAndRetry({required bool isDark}) {
    if (_configListener != null) return;
    void listener() {
      if (ConfigController.cached == null) return;
      _detachConfigListener();
      log('ExpandedNative: config arrived, retrying load.');
      _initIfEnabled(isDark: isDark);
    }

    _configListener = listener;
    configController.addListener(listener);
    if (ConfigController.cached != null) {
      listener();
    }
  }

  Future<void> _reload(bool isDark) async {
    _retryTimer?.cancel();
    _retryCount = 0;
    _nativeAd?.dispose();
    _nativeAd = null;
    if (mounted) {
      setState(() {
        _isLoaded = false;
        _failed = false;
      });
    }
    await _initIfEnabled(isDark: isDark);
  }

  void _markFailed() {
    if (!mounted) return;
    setState(() => _failed = true);
  }

  void _scheduleRetry({required bool isDark}) {
    if (!mounted) return;
    if (_retryCount >= _maxRetries) {
      log('ExpandedNative: $_maxRetries retries reached — giving up.');
      _markFailed();
      return;
    }
    final delay = _nextRetryDelay();
    _retryCount++;
    log('ExpandedNative: retry #$_retryCount scheduled in ${delay.inSeconds}s');
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (!mounted) return;
      _initIfEnabled(isDark: isDark);
    });
  }

  Future<void> _initIfEnabled({required bool isDark}) async {
    ConfigModel? config = ConfigController.cached;
    if (config == null) {
      config = await configController.getConfigFromSharedPreferences();
      if (!mounted) return;
    }

    if (config == null) {
      log('ExpandedNative: config not loaded yet — waiting for fetchConfig.');
      _waitForConfigAndRetry(isDark: isDark);
      return;
    }

    final adsOn = config.extraParam.adsOnOff;
    if (!adsOn) {
      _markFailed();
      return;
    }

    final adUnitId = config.googleNativeAds;
    if (adUnitId.isEmpty) {
      log('ExpandedNative: no ad unit id in config, skipping.');
      _markFailed();
      return;
    }

    if (!nativeAdGate.isOpen) {
      await nativeAdGate.waitForOpen();
      if (!mounted) return;
    }

    final ad = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      nativeAdOptions: NativeAdOptions(
        mediaAspectRatio: MediaAspectRatio.landscape,
      ),
      customOptions: {'isDark': isDark},
      listener: NativeAdListener(
        onAdLoaded: (loaded) {
          log('$loaded loaded (expanded).');
          _retryCount = 0;
          _retryTimer?.cancel();
          _detachConfigListener();
          if (!mounted) {
            loaded.dispose();
            return;
          }
          final stillCurrent =
              Theme.of(context).brightness ==
              (isDark ? Brightness.dark : Brightness.light);
          if (!stillCurrent) {
            loaded.dispose();
            _reload(_currentIsDark ?? isDark);
            return;
          }
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          log('ExpandedNative failed to load: $err — will retry.');
          ad.dispose();
          _scheduleRetry(isDark: isDark);
        },
      ),
      factoryId: "expandedNativeAd",
    );
    if (!mounted) {
      ad.dispose();
      return;
    }
    _nativeAd?.dispose();
    _nativeAd = ad;
    await ad.load();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();

    final loading = !_isLoaded || _nativeAd == null;
    if (loading) {
      return ExpandedNativeAdShimmer(height: widget.height - 5);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111A33) : Colors.white;
    final borderColor = isDark
        ? AppTheme.darkSurfaceHigh
        : Colors.grey.shade200;

    return Container(
      height: widget.height - 22,
      margin: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: RepaintBoundary(child: AdWidget(ad: _nativeAd!)),
    );
  }
}
