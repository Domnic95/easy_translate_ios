import 'dart:async';
import 'dart:developer';

import 'package:easy_translate/Google_Ads/ConfigController.dart';
import 'package:easy_translate/Google_Ads/ConfigModel.dart';
import 'package:easy_translate/providers/deps.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppOpenAdManager {
  final Duration maxCacheDuration = const Duration(hours: 4);
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  static const Duration _maxRetryDelay = Duration(seconds: 8);
  static const int _maxRetries = 20;
  static const Duration _showWaitForLoad = Duration(seconds: 10);
  static const Duration _foregroundWait = Duration(seconds: 3);

  DateTime? _appOpenLoadTime;
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool _isLoading = false;
  int _consecutiveFailures = 0;
  Timer? _retryTimer;
  VoidCallback? _configListener;

  bool get isAdAvailable => _appOpenAd != null;

  Future<bool> waitForAd({Duration timeout = const Duration(seconds: 8)}) async {
    const interval = Duration(milliseconds: 50);
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (isAdAvailable) return true;
      if (!_isLoading) {
        _consecutiveFailures = 0;
        _retryTimer?.cancel();
        _retryTimer = null;
        loadAd();
      }
      await Future.delayed(interval);
    }
    return isAdAvailable;
  }

  Future<void> loadAd({VoidCallback? onLoaded}) async {
    if (_isLoading) {
      log('AppOpenAd: load already in flight, skipping duplicate request.');
      return;
    }
    if (_appOpenAd != null) {
      log('AppOpenAd: already have an ad cached, skipping load.');
      onLoaded?.call();
      return;
    }

    ConfigModel? config = ConfigController.cached;
    config ??= await configController.getConfigFromSharedPreferences();

    if (config == null) {
      debugPrint('AppOpenAd: config not loaded yet — waiting for fetchConfig.');
      _waitForConfigAndRetry();
      return;
    }

    final canShowAds = config.extraParam.adsOnOff;
    final adUnitId = config.googleAppOpenAds;

    debugPrint(
      'AppOpenAd checking: canShowAds=$canShowAds, adUnitId=$adUnitId',
    );

    if (!canShowAds) {
      debugPrint('AppOpenAd not loading: ads master toggle off.');
      return;
    }
    if (adUnitId.isEmpty) {
      debugPrint('AppOpenAd not loading: no ad unit id in config.');
      return;
    }

    _isLoading = true;
    _retryTimer?.cancel();

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _consecutiveFailures = 0;
          _appOpenLoadTime = DateTime.now();
          _appOpenAd = ad;
          _detachConfigListener();
          debugPrint('AppOpenAd loaded successfully.');
          onLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _consecutiveFailures++;
          debugPrint(
            'AppOpenAd failed to load (attempt $_consecutiveFailures'
            '/$_maxRetries): $error',
          );
          _scheduleRetry();
        },
      ),
    );
  }

  void _waitForConfigAndRetry() {
    if (_configListener != null) return;
    void listener() {
      if (ConfigController.cached == null) return;
      _detachConfigListener();
      log('AppOpenAd: config arrived, retrying load.');
      loadAd();
    }

    _configListener = listener;
    configController.addListener(listener);
    if (ConfigController.cached != null) {
      listener();
    }
  }

  void _detachConfigListener() {
    final l = _configListener;
    if (l == null) return;
    configController.removeListener(l);
    _configListener = null;
  }

  void _scheduleRetry() {
    if (_consecutiveFailures >= _maxRetries) {
      log(
        'AppOpenAd: $_maxRetries consecutive failures — giving up until '
        'next foreground event resets the counter via a fresh load.',
      );
      return;
    }
    final exponential = _baseRetryDelay * (1 << (_consecutiveFailures - 1));
    final delay = exponential > _maxRetryDelay ? _maxRetryDelay : exponential;
    log('AppOpenAd: scheduling retry in ${delay.inSeconds}s.');
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () => loadAd());
  }

  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _detachConfigListener();
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }

  void disposeActiveAd() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _detachConfigListener();
    _consecutiveFailures = 0;
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _appOpenLoadTime = null;
    _isLoading = false;
  }

  Future<void> showAdIfAvailable({
    VoidCallback? onAdDismissed,
    VoidCallback? onBeforeShow,
  }) async {
    var beforeShowFired = false;
    void fireBeforeShow() {
      if (beforeShowFired) return;
      beforeShowFired = true;
      try {
        onBeforeShow?.call();
      } catch (e, st) {
        log('AppOpenAd: onBeforeShow threw: $e\n$st');
      }
    }

    var dismissedFired = false;
    void fireDismissed() {
      if (dismissedFired) return;
      dismissedFired = true;
      fireBeforeShow();
      try {
        onAdDismissed?.call();
      } catch (e, st) {
        log('AppOpenAd: onAdDismissed threw: $e\n$st');
      }
      nativeAdGate.open();
    }

    if (_isShowingAd) {
      log('AppOpenAd: tried to show while one was already showing.');
      return;
    }

    final loadedAt = _appOpenLoadTime;
    if (_appOpenAd != null &&
        (loadedAt == null ||
            DateTime.now().subtract(maxCacheDuration).isAfter(loadedAt))) {
      log('AppOpenAd: cached ad expired — dropping and reloading.');
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _appOpenLoadTime = null;
    }

    if (!isAdAvailable) {
      log(
        'AppOpenAd: no ad available — ensuring a load and waiting up to '
        '${_showWaitForLoad.inSeconds}s.',
      );
      final gotIt = await _ensureLoaded(_showWaitForLoad);
      if (!gotIt) {
        log(
          'AppOpenAd: could not load an ad within '
          '${_showWaitForLoad.inSeconds}s — skipping this attempt. '
          'A retry is already queued via loadAd().',
        );
        fireDismissed();
        return;
      }
    }

    final isForeground = await _waitForForeground(timeout: _foregroundWait);
    if (!isForeground) {
      log(
        'AppOpenAd: app never reached RESUMED within '
        '${_foregroundWait.inSeconds}s, skipping show(). Will retry on '
        'next foreground event.',
      );
      fireDismissed();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        log('$ad onAdShowedFullScreenContent');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        log('$ad onAdFailedToShowFullScreenContent: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        fireDismissed();
        nativeAdGate.open();
      },
      onAdDismissedFullScreenContent: (ad) {
        log('$ad onAdDismissedFullScreenContent');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _consecutiveFailures = 0;
        loadAd();
        fireDismissed();
        nativeAdGate.open();
      },
    );

    fireBeforeShow();
    _isShowingAd = true;
    _appOpenAd!.show();
  }

  Future<bool> _ensureLoaded(Duration timeout) async {
    const interval = Duration(milliseconds: 50);
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_appOpenAd != null) return true;
      if (!_isLoading) {
        _consecutiveFailures = 0;
        _retryTimer?.cancel();
        _retryTimer = null;
        loadAd();
      }
      await Future.delayed(interval);
    }
    return _appOpenAd != null;
  }

  Future<bool> _waitForForeground({
    Duration timeout = const Duration(milliseconds: 1500),
    Duration interval = const Duration(milliseconds: 30),
  }) async {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      return true;
    }
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(interval);
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        return true;
      }
    }
    return false;
  }
}
