import 'dart:async';
import 'dart:developer';

import 'package:easy_translate/Google_Ads/Config.dart';
import 'package:easy_translate/Google_Ads/FullscreenAdCover.dart';
import 'package:easy_translate/providers/deps.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';

class RewardAdManager {
  RewardedAd? _ad;
  bool get isReady => _ad != null;

  static const _loadTimeout = Duration(seconds: 8);
  static const _showWatchdog = Duration(seconds: 15);

  Future<bool> preload() async {
    if (_ad != null) return true;

    final adsOn = await Config().showAds();
    if (adsOn != true) return false;

    final adUnitId = await Config().rewardAdUnitId();
    if (adUnitId == null || adUnitId.isEmpty) return false;

    final completer = Completer<bool>();
    Timer? watchdog;
    watchdog = Timer(_loadTimeout, () {
      if (!completer.isCompleted) completer.complete(false);
    });

    try {
      RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            watchdog?.cancel();
            _ad = ad;
            log('Reward: preloaded.');
            if (!completer.isCompleted) completer.complete(true);
          },
          onAdFailedToLoad: (err) {
            watchdog?.cancel();
            log('Reward: preload failed: $err');
            if (!completer.isCompleted) completer.complete(false);
          },
        ),
      );
    } catch (e) {
      watchdog.cancel();
      log('Reward: preload() threw: $e');
      if (!completer.isCompleted) completer.complete(false);
    }

    return completer.future;
  }

  bool showPreloaded({void Function({required bool rewardEarned})? callback}) {
    final ad = _ad;
    if (ad == null) return false;
    _ad = null;

    var rewardEarned = false;
    var completed = false;
    void complete() {
      if (completed) return;
      completed = true;
      try {
        callback?.call(rewardEarned: rewardEarned);
      } catch (e, st) {
        log('Reward: caller callback threw: $e\n$st');
      }
    }

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
        log('Reward: failed to show: $error');
        await teardown();
        complete();
      },
    );

    try {
      ad.show(
        onUserEarnedReward: (_, reward) {
          log(
            'Reward: user earned amount=${reward.amount} type=${reward.type}',
          );
          rewardEarned = true;
        },
      );
      showWatchdog = Timer(_showWatchdog, () async {
        if (completed) return;
        log(
          'Reward: dismiss did not fire within '
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
      log('Reward: show() threw: $e');
      teardown().whenComplete(complete);
    }
    return true;
  }

  void disposePreloaded() {
    final ad = _ad;
    if (ad != null) {
      try {
        ad.dispose();
      } catch (_) {}
    }
    _ad = null;
  }

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
      final ad = _ad;
      if (ad != null) {
        try {
          ad.dispose();
        } catch (_) {}
        _ad = null;
      }
      openGateOnce();
      if (c != null) await c.removeWithFade();
    }

    Timer? watchdog;
    watchdog = Timer(_loadTimeout, () {
      if (completed) return;
      log('Reward: load timed out after ${_loadTimeout.inSeconds}s.');
      teardown().whenComplete(complete);
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
                log('Reward: failed to show: $error');
                showWatchdog?.cancel();
                await teardown();
                complete();
              },
            );

            try {
              ad.show(
                onUserEarnedReward: (_, reward) {
                  log(
                    'Reward: user earned amount=${reward.amount} '
                    'type=${reward.type}',
                  );
                  rewardEarned = true;
                },
              );
              showWatchdog = Timer(_showWatchdog, () async {
                if (completed) return;
                log(
                  'Reward: dismiss did not fire within '
                  '${_showWatchdog.inSeconds}s — forcing teardown.',
                );
                cover?.removeImmediate();
                cover = null;
                try {
                  ad.dispose();
                } catch (_) {}
                _ad = null;
                openGateOnce();
                complete();
              });
            } catch (e) {
              log('Reward: show() threw: $e');
              await teardown();
              complete();
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            watchdog?.cancel();
            log('Reward: failed to load: $error');
            dismissLoader();
            openGateOnce();
            complete();
          },
        ),
      );
    } catch (e) {
      log('Reward: load() threw synchronously: $e');
      watchdog.cancel();
      teardown().whenComplete(complete);
    }
  }
}
