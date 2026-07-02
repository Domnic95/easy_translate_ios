import 'dart:convert';

ConfigModel configModelFromJson(String str) =>
    ConfigModel.fromJson(json.decode(str));

String configModelToJson(ConfigModel data) => json.encode(data.toJson());

class ConfigModel {
  final String type;
  final String vpnOnOff;
  final String showDialogBeforeAds;
  final String googleAppOpenAds;
  final String google2AppOpenAds;
  final String googleBannerAds;
  final String google2BannerAds;
  final String google3BannerAds;
  final String googleInterAds;
  final String google2InterAds;
  final String google3InterAds;
  final String googleNativeAds;
  final String googleNative2Ads;
  final String google2NativeAds;
  final String google2Native2Ads;
  final String googleRewardAds;
  final String googleReward1Ads;
  final String fNative;
  final String fBanner;
  final String fInterstitial;
  final String fNativeBanner;
  final String vpnCarrierId;
  final String qurl;
  final String qUrlClick;
  final String country;
  final String state;
  final String city;
  final String vpnCode;
  final String clickcountry;
  final String clickcity;
  final String clickcountinter;
  final String commingSoon;
  final String isUpdate;
  final String updateUrl;
  final String privacyPolice;
  final bool error;
  final bool success;
  final ExtraParam extraParam;

  ConfigModel({
    required this.type,
    required this.vpnOnOff,
    required this.showDialogBeforeAds,
    required this.googleAppOpenAds,
    required this.google2AppOpenAds,
    required this.googleBannerAds,
    required this.google2BannerAds,
    required this.google3BannerAds,
    required this.googleInterAds,
    required this.google2InterAds,
    required this.google3InterAds,
    required this.googleNativeAds,
    required this.googleNative2Ads,
    required this.google2NativeAds,
    required this.google2Native2Ads,
    required this.googleRewardAds,
    required this.googleReward1Ads,
    required this.fNative,
    required this.fBanner,
    required this.fInterstitial,
    required this.fNativeBanner,
    required this.vpnCarrierId,
    required this.qurl,
    required this.qUrlClick,
    required this.country,
    required this.state,
    required this.city,
    required this.vpnCode,
    required this.clickcountry,
    required this.clickcity,
    required this.clickcountinter,
    required this.commingSoon,
    required this.isUpdate,
    required this.updateUrl,
    required this.privacyPolice,
    required this.error,
    required this.success,
    required this.extraParam,
  });

  static String _s(dynamic v) => v is String ? v : '';
  static bool _b(dynamic v) => v is bool ? v : false;

  factory ConfigModel.fromJson(Map<String, dynamic> json) => ConfigModel(
    type: _s(json["type"]),
    vpnOnOff: _s(json["VpnOnOff"]),
    showDialogBeforeAds: _s(json["ShowDialogBeforeAds"]),
    googleAppOpenAds: _s(json["GoogleAppOpenAds"]),
    google2AppOpenAds: _s(json["Google2AppOpenAds"]),
    googleBannerAds: _s(json["GoogleBannerAds"]),
    google2BannerAds: _s(json["Google2BannerAds"]),
    google3BannerAds: _s(json["Google3BannerAds"]),
    googleInterAds: _s(json["GoogleInterAds"]),
    google2InterAds: _s(json["Google2InterAds"]),
    google3InterAds: _s(json["Google3InterAds"]),
    googleNativeAds: _s(json["GoogleNativeAds"]),
    googleNative2Ads: _s(json["GoogleNative2Ads"]),
    google2NativeAds: _s(json["Google2NativeAds"]),
    google2Native2Ads: _s(json["Google2Native2Ads"]),
    googleRewardAds: _s(json["GoogleRewardAds"]),
    googleReward1Ads: _s(json["GoogleReward1Ads"]),
    fNative: _s(json["f_native"]),
    fBanner: _s(json["f_banner"]),
    fInterstitial: _s(json["f_interstitial"]),
    fNativeBanner: _s(json["f_native_banner"]),
    vpnCarrierId: _s(json["VpnCarrierId"]),
    qurl: _s(json["qurl"]),
    qUrlClick: _s(json["q_url_click"]),
    country: _s(json["Country"]),
    state: _s(json["State"]),
    city: _s(json["City"]),
    vpnCode: _s(json["VpnCode"]),
    clickcountry: _s(json["clickcountry"]),
    clickcity: _s(json["clickcity"]),
    clickcountinter: _s(json["clickcountinter"]),
    commingSoon: _s(json["comming_soon"]),
    isUpdate: _s(json["is_update"]),
    updateUrl: _s(json["update_url"]),
    privacyPolice: _s(json["privacy_police"]),
    error: _b(json["error"]),
    success: _b(json["success"]),
    extraParam: ExtraParam.fromJson(
      (json["extra_param"] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "VpnOnOff": vpnOnOff,
    "ShowDialogBeforeAds": showDialogBeforeAds,
    "GoogleAppOpenAds": googleAppOpenAds,
    "Google2AppOpenAds": google2AppOpenAds,
    "GoogleBannerAds": googleBannerAds,
    "Google2BannerAds": google2BannerAds,
    "Google3BannerAds": google3BannerAds,
    "GoogleInterAds": googleInterAds,
    "Google2InterAds": google2InterAds,
    "Google3InterAds": google3InterAds,
    "GoogleNativeAds": googleNativeAds,
    "GoogleNative2Ads": googleNative2Ads,
    "Google2NativeAds": google2NativeAds,
    "Google2Native2Ads": google2Native2Ads,
    "GoogleRewardAds": googleRewardAds,
    "GoogleReward1Ads": googleReward1Ads,
    "f_native": fNative,
    "f_banner": fBanner,
    "f_interstitial": fInterstitial,
    "f_native_banner": fNativeBanner,
    "VpnCarrierId": vpnCarrierId,
    "qurl": qurl,
    "q_url_click": qUrlClick,
    "Country": country,
    "State": state,
    "City": city,
    "VpnCode": vpnCode,
    "clickcountry": clickcountry,
    "clickcity": clickcity,
    "clickcountinter": clickcountinter,
    "comming_soon": commingSoon,
    "is_update": isUpdate,
    "update_url": updateUrl,
    "privacy_police": privacyPolice,
    "error": error,
    "success": success,
    "extra_param": extraParam.toJson(),
  };
}

class ExtraParam {
  bool adsOnOff;
  int interIntervalCount;
  int backInterIntervalCount;
  int whichOneSplashAppOpen;

  ExtraParam({
    required this.adsOnOff,
    required this.interIntervalCount,
    required this.backInterIntervalCount,
    required this.whichOneSplashAppOpen,
  });

  factory ExtraParam.fromJson(Map<String, dynamic> json) => ExtraParam(
    adsOnOff: json["AdsOnOff"] is bool ? json["AdsOnOff"] as bool : false,
    interIntervalCount: (json["InterIntervalCount"] as num?)?.toInt() ?? 0,
    backInterIntervalCount:
        (json["BackInterIntervalCount"] as num?)?.toInt() ?? 0,
    whichOneSplashAppOpen:
        (json["WhichOneSplashAppOpen"] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "AdsOnOff": adsOnOff,
    "InterIntervalCount": interIntervalCount,
    "BackInterIntervalCount": backInterIntervalCount,
    "WhichOneSplashAppOpen": whichOneSplashAppOpen,
  };
}
