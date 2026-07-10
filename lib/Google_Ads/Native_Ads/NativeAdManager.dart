import 'dart:developer';

import 'package:easy_translate/Google_Ads/AdPools.dart';
import 'package:easy_translate/Google_Ads/ConfigController.dart';
import 'package:easy_translate/Google_Ads/ConfigModel.dart';
import 'package:easy_translate/Google_Ads/Native_Ads/NativeAdShimmer.dart';
import 'package:easy_translate/providers/deps.dart';
import 'package:easy_translate/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdManager extends StatefulWidget {
  const NativeAdManager({super.key});

  @override
  State<NativeAdManager> createState() => _NativeAdManagerState();
}

class _NativeAdManagerState extends State<NativeAdManager> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _failed = false;
  bool? _currentIsDark;
  int _lastShutdownRev = configController.adsShutdownRevision;
  VoidCallback? _configListener;

  @override
  void initState() {
    super.initState();
    _configListener = _onConfigChanged;
    configController.addListener(_configListener!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newIsDark = Theme.of(context).brightness == Brightness.dark;

    if (_currentIsDark == null) {
      _currentIsDark = newIsDark;
      _initIfEnabled(isDark: newIsDark);
      return;
    }

    if (newIsDark != _currentIsDark) {
      _currentIsDark = newIsDark;
      _reload(newIsDark);
    }
  }

  @override
  void dispose() {
    final l = _configListener;
    if (l != null) configController.removeListener(l);
    _configListener = null;
    _detachConfigWaitListener();
    _nativeAd?.dispose();
    super.dispose();
  }

  VoidCallback? _configWaitListener;

  void _detachConfigWaitListener() {
    final l = _configWaitListener;
    if (l == null) return;
    configController.removeListener(l);
    _configWaitListener = null;
  }

  void _waitForConfigAndRetry({required bool isDark}) {
    if (_configWaitListener != null) return;
    void listener() {
      if (ConfigController.cached == null) return;
      _detachConfigWaitListener();
      log('Native: config arrived, retrying load.');
      _initIfEnabled(isDark: isDark);
    }

    _configWaitListener = listener;
    configController.addListener(listener);
    if (ConfigController.cached != null) {
      listener();
    }
  }

  void _onConfigChanged() {
    if (!mounted) return;
    final rev = configController.adsShutdownRevision;
    if (rev > _lastShutdownRev) {
      _lastShutdownRev = rev;
      _nativeAd?.dispose();
      _nativeAd = null;
      setState(() {
        _isLoaded = false;
        _failed = true;
      });
    }
  }

  Future<void> _reload(bool isDark) async {
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

  Future<void> _initIfEnabled({required bool isDark}) async {
    ConfigModel? config = ConfigController.cached;
    if (config == null) {
      config = await configController.getConfigFromSharedPreferences();
      if (!mounted) return;
    }

    if (config == null) {
      log('Native: config not loaded yet — waiting for fetchConfig.');
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
      log('Native: no ad unit id in config, skipping.');
      _markFailed();
      return;
    }

    if (!nativeAdGate.isOpen) {
      await nativeAdGate.waitForOpen();
      if (!mounted) return;
    }

    final pooled = NativeAdPool.instance.take('listTile', isDark: isDark);
    if (pooled != null) {
      if (!mounted) {
        pooled.dispose();
        return;
      }
      _nativeAd?.dispose();
      _nativeAd = pooled;
      setState(() => _isLoaded = true);
      return;
    }

    final ad = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      customOptions: {'isDark': isDark},
      listener: NativeAdListener(
        onAdLoaded: (loaded) {
          log('$loaded loaded.');
          _detachConfigWaitListener();
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
          log('Native failed to load: $err');
          ad.dispose();
          _markFailed();
        },
      ),
      factoryId: "listTile",
    );
    if (!mounted) {
      ad.dispose();
      return;
    }
    _nativeAd?.dispose();
    _nativeAd = ad;
    await ad.load();
  }

  static const double _visibleHeight = 60;
  static const double _nativeAdViewHeight = 180;

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111A33) : Colors.white;
    final borderColor = isDark
        ? AppTheme.darkSurfaceHigh
        : Colors.grey.shade200;

    final loading = !_isLoaded || _nativeAd == null;
    final inner = loading
        ? const NativeAdShimmer(height: _visibleHeight)
        : ClipRect(
            child: SizedBox(
              height: _visibleHeight,
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: _nativeAdViewHeight,
                maxHeight: _nativeAdViewHeight,
                child: RepaintBoundary(child: AdWidget(ad: _nativeAd!)),
              ),
            ),
          );

    return Container(
      height: _visibleHeight,
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 1.5, color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: inner,
    );
  }
}
