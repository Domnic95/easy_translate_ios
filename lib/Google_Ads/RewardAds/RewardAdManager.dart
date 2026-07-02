import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_translate/Google_Ads/Config.dart';
import 'package:easy_translate/providers/deps.dart';

class RewardAdManager {
  RewardedAd? _ad;

  static const _loadTimeout = Duration(seconds: 8);

  Future<void> loadAndShow({
    void Function({required bool rewardEarned})? callback,
  }) async {
    var completed = false;
    var rewardEarned = false;
    void complete() {
      if (completed) return;
      completed = true;
      try {
        callback?.call(rewardEarned: rewardEarned);
      } catch (e, st) {
        log('Reward: caller callback threw: $e\n$st');
      }
    }

    final adsOn = await Config().showAds();
    if (adsOn != true) {
      log('Reward: ads disabled in config, skipping (firing callback).');
      complete();
      return;
    }

    final adUnitId = await Config().rewardAdUnitId();
    if (adUnitId == null || adUnitId.isEmpty) {
      log('Reward: no ad unit id in config, skipping (firing callback).');
      complete();
      return;
    }

    var loaderShown = false;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      log('Reward: navigator context unavailable; skipping loader.');
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
        log('Reward: failed to show loader dialog: $e');
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
        log('Reward: dismissLoader pop threw: $e');
      }
    }

    Route<void>? coverRoute;
    Future<void> pushBlackCover() async {
      final state = navigatorKey.currentState;
      if (state == null) return;
      try {
        coverRoute = PageRouteBuilder<void>(
          settings: const RouteSettings(name: '/RewardAdBlackCover'),
          opaque: true,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, _, _) =>
              const Scaffold(backgroundColor: Colors.black),
        );
        state.push(coverRoute!);
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        log('Reward: pushBlackCover threw: $e');
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
        log('Reward: popBlackCover removeRoute threw: $e');
      }
    }

    void teardown() {
      dismissLoader();
      popBlackCover();
      final ad = _ad;
      if (ad != null) {
        try {
          ad.dispose();
        } catch (_) {}
        _ad = null;
      }
    }

    Timer? watchdog;
    watchdog = Timer(_loadTimeout, () {
      if (completed) return;
      log('Reward: load timed out after ${_loadTimeout.inSeconds}s.');
      teardown();
      complete();
    });

    try {
      RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) async {
            if (completed) {
              try {
                ad.dispose();
              } catch (_) {}
              return;
            }
            watchdog?.cancel();
            log('Reward: loaded.');
            dismissLoader();
            _ad = ad;
            await pushBlackCover();

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {},
              onAdDismissedFullScreenContent: (ad) {
                teardown();
                complete();
                nativeAdGate.open();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                log('Reward: failed to show: $error');
                teardown();
                complete();
                nativeAdGate.open();
              },
            );

            try {
              ad.show(
                onUserEarnedReward: (ad, reward) {
                  log(
                    'Reward: user earned reward '
                    'amount=${reward.amount} type=${reward.type}',
                  );
                  rewardEarned = true;
                },
              );
            } catch (e) {
              log('Reward: show() threw: $e');
              teardown();
              complete();
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            watchdog?.cancel();
            log('Reward: failed to load: $error');
            dismissLoader();
            complete();
          },
        ),
      );
    } catch (e) {
      log('Reward: load() threw synchronously: $e');
      watchdog.cancel();
      teardown();
      complete();
    }
  }
}
