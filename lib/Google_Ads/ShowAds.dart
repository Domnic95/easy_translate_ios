import 'dart:developer';
import 'dart:ui';

import 'package:easy_translate/Google_Ads/AdPools.dart';
import 'package:easy_translate/Google_Ads/Config.dart';
import 'package:easy_translate/Google_Ads/SpHelper.dart';

class ShowInterstitialAds {
  Future<void> showClickInterstitialAds({
    VoidCallback? callback,
    VoidCallback? onBeforeShow,
  }) async {
    await SpHelper().initialize();
    await SpHelper.incrementClick();

    final currentClick = await SpHelper.getclick();
    final interval = await Config().intersClick();
    final adsOn = await Config().showAds();

    if (interval != 0 && currentClick % interval == 0 && adsOn) {
      await InterstitialAdPool.instance.show(
        callback: callback,
        onBeforeShow: onBeforeShow,
      );
      await SpHelper.resetClick();
    } else {
      log(
        '[ShowInterstitialAds] click skip: '
        'click=$currentClick interval=$interval adsOn=$adsOn',
      );
      onBeforeShow?.call();
      callback?.call();
    }
  }

  Future<void> showAlwaysInterstitialAds({
    VoidCallback? callback,
    VoidCallback? onBeforeShow,
  }) {
    return InterstitialAdPool.instance.show(
      callback: callback,
      onBeforeShow: onBeforeShow,
    );
  }

  Future<void> showBackInterstitialAds({
    VoidCallback? callback,
    VoidCallback? onBeforeShow,
  }) async {
    await SpHelper().initialize();
    await SpHelper.incrementBackClick();

    final currentClick = await SpHelper.getBackClick();
    final interval = await Config().backInterClick();
    final adsOn = await Config().showAds();

    if (interval != 0 && currentClick % interval == 0 && adsOn) {
      log(
        '[ShowInterstitialAds] back show: '
        'click=$currentClick interval=$interval',
      );
      await InterstitialAdPool.instance.show(
        callback: callback,
        onBeforeShow: onBeforeShow,
      );
      await SpHelper.resetBackClick();
    } else {
      log(
        '[ShowInterstitialAds] back skip: '
        'click=$currentClick interval=$interval adsOn=$adsOn',
      );
      onBeforeShow?.call();
      callback?.call();
    }
  }
}
