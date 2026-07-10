import 'dart:async';
import 'dart:developer';

import 'package:easy_translate/Google_Ads/Config.dart';
import 'package:easy_translate/Google_Ads/FullscreenAdCover.dart';
import 'package:easy_translate/providers/deps.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';

class InterstitialAdManager {
  InterstitialAd? interstitialAd;
  bool isLoaded = false;

  static const _loadTimeout = Duration(seconds: 8);
  static const _showWatchdog = Duration(seconds: 15);

  Future<bool> preload() async {
    if (isLoaded && interstitialAd != null) return true;

    final adsOn = await Config().showAds();
    if (adsOn != true) return false;

    final adUnitId = await Config().interstitialAdUnitId();
    if (adUnitId == null || adUnitId.isEmpty) return false;

    final completer = Completer<bool>();
    Timer? watchdog;
    watchdog = Timer(_loadTimeout, () {
      if (!completer.isCompleted) completer.complete(false);
    });

    try {
      InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            watchdog?.cancel();
            interstitialAd = ad;
            isLoaded = true;
            log('Interstitial: preloaded.');
            if (!completer.isCompleted) completer.complete(true);
          },
          onAdFailedToLoad: (err) {
            watchdog?.cancel();
            log('Interstitial: preload failed: $err');
            isLoaded = false;
            if (!completer.isCompleted) completer.complete(false);
          },
        ),
      );
    } catch (e) {
      watchdog.cancel();
      log('Interstitial: preload() threw: $e');
      if (!completer.isCompleted) completer.complete(false);
    }

    return completer.future;
  }

  bool showPreloaded({VoidCallback? callback, VoidCallback? onBeforeShow}) {
    final ad = interstitialAd;
    if (ad == null || !isLoaded) return false;

    var beforeShowFired = false;
    void fireBeforeShow() {
      if (beforeShowFired) return;
      beforeShowFired = true;
      try {
        onBeforeShow?.call();
      } catch (e, st) {
        log('Interstitial: onBeforeShow threw: $e\n$st');
      }
    }

    var completed = false;
    void complete() {
      if (completed) return;
      completed = true;
      fireBeforeShow();
      try {
        callback?.call();
      } catch (e, st) {
        log('Interstitial: caller callback threw: $e\n$st');
      }
    }

    interstitialAd = null;
    isLoaded = false;

    fireBeforeShow();
    final cover = FullscreenAdCover.show();

    Timer? showWatchdog;
    var gateOpened = false;
    void openGateOnce() {
      if (gateOpened) return;
      gateOpened = true;
      nativeAdGate.open();
    }

    Future<void> teardown() async {
      showWatchdog?.cancel();
      showWatchdog = null;
      try {
        ad.dispose();
      } catch (_) {}
      openGateOnce();
      await cover?.removeWithFade();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {},
      onAdDismissedFullScreenContent: (_) async {
        await teardown();
        complete();
      },
      onAdFailedToShowFullScreenContent: (_, error) async {
        log('Interstitial: failed to show: $error');
        await teardown();
        complete();
      },
    );

    try {
      ad.show();
      showWatchdog = Timer(_showWatchdog, () async {
        if (completed) return;
        log(
          'Interstitial: dismiss did not fire within '
          '${_showWatchdog.inSeconds}s — forcing teardown.',
        );
        cover?.removeImmediate();
        try {
          ad.dispose();
        } catch (_) {}
        openGateOnce();
        complete();
      });
    } catch (e) {
      log('Interstitial: show() threw: $e');
      teardown().whenComplete(complete);
    }
    return true;
  }

  void disposePreloaded() {
    final ad = interstitialAd;
    if (ad != null) {
      try {
        ad.dispose();
      } catch (_) {}
    }
    interstitialAd = null;
    isLoaded = false;
  }

  Future<void> loadAd({
    VoidCallback? callback,
    VoidCallback? onBeforeShow,
  }) async {
    var beforeShowFired = false;
    void fireBeforeShow() {
      if (beforeShowFired) return;
      beforeShowFired = true;
      try {
        onBeforeShow?.call();
      } catch (e, st) {
        log('Interstitial: onBeforeShow threw: $e\n$st');
      }
    }

    var completed = false;
    void complete() {
      if (completed) return;
      completed = true;
      fireBeforeShow();
      try {
        callback?.call();
      } catch (e, st) {
        log('Interstitial: caller callback threw: $e\n$st');
      }
    }

    final adsOn = await Config().showAds();
    if (adsOn != true) {
      log('Interstitial: ads disabled in config, skipping.');
      complete();
      return;
    }

    final adUnitId = await Config().interstitialAdUnitId();
    if (adUnitId == null || adUnitId.isEmpty) {
      log('Interstitial: no ad unit id in config, skipping.');
      complete();
      return;
    }

    var loaderShown = false;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      log('Interstitial: navigator context unavailable; skipping loader.');
    } else {
      try {
        if (!ctx.mounted) return;
        showDialog<void>(
          context: ctx,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.8),
          builder: (_) => Center(
            child: Container(
              padding: const EdgeInsets.all(50),
              child: Lottie.asset(
                'assets/lottie/loading_spinner.json',
                errorBuilder: (_, _, _) =>
                    const CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
        );
        loaderShown = true;
      } catch (e) {
        log('Interstitial: failed to show loader dialog: $e');
      }
    }

    void dismissLoader() {
      if (!loaderShown) return;
      loaderShown = false;
      final navCtx = navigatorKey.currentContext;
      if (navCtx == null) return;
      try {
        if (Navigator.canPop(navCtx)) Navigator.of(navCtx).pop();
      } catch (e) {
        log('Interstitial: dismissLoader pop threw: $e');
      }
    }

    FullscreenAdCover? cover;
    var gateOpened = false;
    void openGateOnce() {
      if (gateOpened) return;
      gateOpened = true;
      nativeAdGate.open();
    }

    Future<void> teardown() async {
      dismissLoader();
      final c = cover;
      cover = null;
      final ad = interstitialAd;
      if (ad != null) {
        try {
          ad.dispose();
        } catch (_) {}
        interstitialAd = null;
        isLoaded = false;
      }
      openGateOnce();
      if (c != null) await c.removeWithFade();
    }

    Timer? watchdog;
    watchdog = Timer(_loadTimeout, () {
      if (completed) return;
      log('Interstitial: load timed out after ${_loadTimeout.inSeconds}s.');
      teardown().whenComplete(complete);
    });

    try {
      InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) async {
            if (completed) {
              try {
                ad.dispose();
              } catch (_) {}
              return;
            }
            watchdog?.cancel();
            log('Interstitial: loaded.');
            dismissLoader();
            isLoaded = true;
            interstitialAd = ad;

            fireBeforeShow();
            cover = FullscreenAdCover.show();

            Timer? showWatchdog;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (_) {},
              onAdDismissedFullScreenContent: (_) async {
                showWatchdog?.cancel();
                await teardown();
                complete();
              },
              onAdFailedToShowFullScreenContent: (_, error) async {
                log('Interstitial: failed to show: $error');
                showWatchdog?.cancel();
                await teardown();
                complete();
              },
            );

            try {
              ad.show();
              showWatchdog = Timer(_showWatchdog, () async {
                if (completed) return;
                log(
                  'Interstitial: dismiss callback did NOT fire within '
                  '${_showWatchdog.inSeconds}s — forcing teardown.',
                );
                cover?.removeImmediate();
                cover = null;
                try {
                  ad.dispose();
                } catch (_) {}
                interstitialAd = null;
                isLoaded = false;
                openGateOnce();
                complete();
              });
            } catch (e) {
              log('Interstitial: show() threw: $e');
              await teardown();
              complete();
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            watchdog?.cancel();
            log('Interstitial: failed to load: $error');
            dismissLoader();
            isLoaded = false;
            openGateOnce();
            complete();
          },
        ),
      );
    } catch (e) {
      log('Interstitial: load() threw synchronously: $e');
      watchdog.cancel();
      teardown().whenComplete(complete);
    }
  }
}
