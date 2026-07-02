import 'package:easy_translate/Google_Ads/ConfigController.dart';
import 'package:easy_translate/Google_Ads/ConfigModel.dart';
import 'package:easy_translate/providers/deps.dart' as deps;

class Config {
  ConfigController configController = deps.configController;

  Future<String?>? openAdUnitId() async {
    ConfigModel? config = await configController
        .getConfigFromSharedPreferences();
    return config?.googleAppOpenAds;
  }

  Future<String?>? interstitialAdUnitId() async {
    ConfigModel? config = await configController
        .getConfigFromSharedPreferences();
    return config?.googleInterAds;
  }

  Future<String?>? nativeAdUnitId() async {
    ConfigModel? config = await configController
        .getConfigFromSharedPreferences();
    return config?.googleNativeAds;
  }

  Future<String?>? bannerAdUnitId() async {
    ConfigModel? config = await configController
        .getConfigFromSharedPreferences();
    return config?.googleBannerAds;
  }

  Future<String?>? rewardAdUnitId() async {
    ConfigModel? config = await configController
        .getConfigFromSharedPreferences();
    return config?.googleRewardAds;
  }

  Future<bool> showAds() async {
    ConfigModel? config = await configController
        .getConfigFromSharedPreferences();
    return config?.extraParam.adsOnOff ?? false;
  }

  Future<int?>? ifOpenAds() async {
    final ConfigModel? config = await configController
        .getConfigFromSharedPreferences();
    if (config != null) {
      return config.extraParam.whichOneSplashAppOpen;
    } else {
      await Future.delayed(const Duration(seconds: 2));
      final ConfigModel? configRetry = await configController
          .getConfigFromSharedPreferences();
      return configRetry?.extraParam.whichOneSplashAppOpen;
    }
  }

  Future<int> intersClick() async {
    ConfigModel? config = await configController
        .getConfigFromSharedPreferences();
    return config?.extraParam.interIntervalCount ?? 0;
  }

  Future<int> backInterClick() async {
    ConfigModel? config = await configController
        .getConfigFromSharedPreferences();
    return config?.extraParam.backInterIntervalCount ?? 0;
  }
}
