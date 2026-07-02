import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_translate/Google_Ads/Config.dart';
import 'package:easy_translate/providers/deps.dart';

class InterstitialAdManager {
  InterstitialAd? interstitialAd;
  bool isLoaded = false;
  static const _loadTimeout = Duration(seconds: 8);
  static const _showWatchdog = Duration(seconds: 45);

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
        showDialog<void>(
          // ignore: use_build_context_synchronously
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

    Route<void>? coverRoute;

    Future<void> pushBlackCover() async {
      final state = navigatorKey.currentState;
      if (state == null) return;
      try {
        coverRoute = PageRouteBuilder<void>(
          settings: const RouteSettings(name: '/AdBlackCover'),
          opaque: true,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, _, _) =>
              const Scaffold(backgroundColor: Colors.black),
        );
        state.push(coverRoute!);
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        log('Interstitial: pushBlackCover threw: $e');
        coverRoute = null;
      }
    }

    void popBlackCover() {
      final route = coverRoute;
      coverRoute = null;
      if (route == null) return;
      final state = navigatorKey.currentState;
      if (state == null) return;
      try {
        state.removeRoute(route);
      } catch (e) {
        log('Interstitial: popBlackCover removeRoute threw: $e');
      }
    }

    void teardown() {
      dismissLoader();
      popBlackCover();
      final ad = interstitialAd;
      if (ad != null) {
        try {
          ad.dispose();
        } catch (_) {}
        interstitialAd = null;
        isLoaded = false;
      }
    }

    Timer? watchdog;
    watchdog = Timer(_loadTimeout, () {
      if (completed) return;
      log('Interstitial: load timed out after ${_loadTimeout.inSeconds}s.');
      teardown();
      complete();
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
            await pushBlackCover();
            Timer? showWatchdog;

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
              },
              onAdDismissedFullScreenContent: (ad) {
                showWatchdog?.cancel();
                teardown();
                complete();
                nativeAdGate.open();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                log('Interstitial: failed to show: $error');
                showWatchdog?.cancel();
                teardown();
                complete();
                nativeAdGate.open();
              },
            );

            try {
              ad.show();
              showWatchdog = Timer(_showWatchdog, () {
                if (completed) return;
                log(
                  'Interstitial: dismiss callback did NOT fire within '
                  '${_showWatchdog.inSeconds}s — forcing teardown so the '
                  'UI is not stuck behind the black cover.',
                );
                teardown();
                complete();
                nativeAdGate.open();
              });
            } catch (e) {
              log('Interstitial: show() threw: $e');
              teardown();
              complete();
              nativeAdGate.open();
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            watchdog?.cancel();
            log('Interstitial: failed to load: $error');
            dismissLoader();
            isLoaded = false;
            complete();
          },
        ),
      );
    } catch (e) {
      log('Interstitial: load() threw synchronously: $e');
      watchdog.cancel();
      teardown();
      complete();
    }
  }
}
