import 'dart:async';
import 'dart:developer';

import 'package:easy_translate/Google_Ads/ConfigController.dart';
import 'package:easy_translate/Google_Ads/ConfigModel.dart';
import 'package:easy_translate/Google_Ads/InterstitialAds/InterstitialAdManager.dart';
import 'package:easy_translate/Google_Ads/RewardAds/RewardAdManager.dart';
import 'package:easy_translate/providers/deps.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdPool {
  InterstitialAdPool._();
  static final InterstitialAdPool instance = InterstitialAdPool._();

  InterstitialAdManager _slot = InterstitialAdManager();
  bool _refilling = false;

  bool get isReady => _slot.isLoaded;

  Future<void> preload() async {
    if (_refilling || _slot.isLoaded) return;
    _refilling = true;
    try {
      final loaded = await _slot.preload();
      if (!loaded) {
        _slot = InterstitialAdManager();
      }
    } finally {
      _refilling = false;
    }
  }

  Future<void> show({
    VoidCallback? callback,
    VoidCallback? onBeforeShow,
  }) async {
    if (_slot.isLoaded) {
      final shown = _slot.showPreloaded(
        callback: () {
          _slot = InterstitialAdManager();
          unawaited(preload());
          callback?.call();
        },
        onBeforeShow: onBeforeShow,
      );
      if (shown) return;
    }
    final fallback = InterstitialAdManager();
    await fallback.loadAd(
      callback: () {
        unawaited(preload());
        callback?.call();
      },
      onBeforeShow: onBeforeShow,
    );
  }

  void disposeAll() {
    _slot.disposePreloaded();
    _slot = InterstitialAdManager();
  }
}

class RewardAdPool {
  RewardAdPool._();
  static final RewardAdPool instance = RewardAdPool._();

  RewardAdManager _slot = RewardAdManager();
  bool _refilling = false;

  bool get isReady => _slot.isReady;

  Future<void> preload() async {
    if (_refilling || _slot.isReady) return;
    _refilling = true;
    try {
      final loaded = await _slot.preload();
      if (!loaded) {
        _slot = RewardAdManager();
      }
    } finally {
      _refilling = false;
    }
  }

  Future<void> show({
    void Function({required bool rewardEarned})? callback,
  }) async {
    if (_slot.isReady) {
      final shown = _slot.showPreloaded(
        callback: ({required bool rewardEarned}) {
          _slot = RewardAdManager();
          unawaited(preload());
          callback?.call(rewardEarned: rewardEarned);
        },
      );
      if (shown) return;
    }
    final fallback = RewardAdManager();
    await fallback.loadAndShow(
      callback: ({required bool rewardEarned}) {
        unawaited(preload());
        callback?.call(rewardEarned: rewardEarned);
      },
    );
  }

  void disposeAll() {
    _slot.disposePreloaded();
    _slot = RewardAdManager();
  }
}

class NativeAdPool {
  NativeAdPool._();
  static final NativeAdPool instance = NativeAdPool._();

  final Map<String, NativeAd> _cache = {};
  final Set<String> _inFlight = {};

  String _key(String factoryId, bool isDark) => '$factoryId::$isDark';

  NativeAd? take(String factoryId, {required bool isDark}) {
    final key = _key(factoryId, isDark);
    final ad = _cache.remove(key);
    if (ad != null) {
      unawaited(_preload(factoryId, isDark));
    }
    return ad;
  }

  Future<void> preload(String factoryId, {required bool isDark}) =>
      _preload(factoryId, isDark);

  Future<void> _preload(String factoryId, bool isDark) async {
    final key = _key(factoryId, isDark);
    if (_cache.containsKey(key) || _inFlight.contains(key)) return;

    ConfigModel? config = ConfigController.cached;
    config ??= await configController.getConfigFromSharedPreferences();
    if (config == null) {
      log('NativeAdPool: config not ready — skipping preload of $factoryId');
      return;
    }
    if (!config.extraParam.adsOnOff) return;

    final adUnitId = config.googleNativeAds;
    if (adUnitId.isEmpty) return;

    _inFlight.add(key);
    NativeAd? ad;
    ad = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      nativeAdOptions: factoryId == 'expandedNativeAd'
          ? NativeAdOptions(mediaAspectRatio: MediaAspectRatio.landscape)
          : null,
      customOptions: {'isDark': isDark},
      listener: NativeAdListener(
        onAdLoaded: (loaded) {
          _inFlight.remove(key);
          _cache[key] = loaded as NativeAd;
          log('NativeAdPool: preloaded $key');
        },
        onAdFailedToLoad: (failedAd, err) {
          _inFlight.remove(key);
          failedAd.dispose();
          log('NativeAdPool: preload failed for $key: $err');
        },
      ),
      factoryId: factoryId,
    );
    try {
      await ad.load();
    } catch (e) {
      _inFlight.remove(key);
      log('NativeAdPool: load() threw for $key: $e');
      try {
        ad.dispose();
      } catch (_) {}
    }
  }

  void disposeAll() {
    for (final ad in _cache.values) {
      try {
        ad.dispose();
      } catch (_) {}
    }
    _cache.clear();
  }
}

void preloadAllAdsOnBoot() {
  unawaited(InterstitialAdPool.instance.preload());
  unawaited(RewardAdPool.instance.preload());
  unawaited(NativeAdPool.instance.preload('listTile', isDark: false));
  unawaited(NativeAdPool.instance.preload('listTile', isDark: true));
}

int _lastShutdownRev = 0;
void attachConfigShutdownListener() {
  configController.addListener(_onConfigChanged);
}

void _onConfigChanged() {
  final rev = configController.adsShutdownRevision;
  if (rev > _lastShutdownRev) {
    _lastShutdownRev = rev;
    log('[AdPools] adsOnOff shutdown detected — disposing pools + AppOpen ad');
    InterstitialAdPool.instance.disposeAll();
    RewardAdPool.instance.disposeAll();
    NativeAdPool.instance.disposeAll();
    appOpenAdManager.disposeActiveAd();
    return;
  }
  final config = ConfigController.cached;
  if (config != null && config.extraParam.adsOnOff) {
    unawaited(InterstitialAdPool.instance.preload());
    unawaited(RewardAdPool.instance.preload());
  }
}
