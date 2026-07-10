import 'dart:async';
import 'dart:developer';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:easy_translate/Google_Ads/BannerAds/AppOpenManager.dart';
import 'package:easy_translate/providers/deps.dart';

class AppLifecycleReactor {
  final AppOpenAdManager appOpenAdManager;
  StreamSubscription<AppState>? _sub;

  AppLifecycleReactor({required this.appOpenAdManager});

  void listenToAppStateChanges() {
    _sub?.cancel();
    AppStateEventNotifier.startListening();
    _sub = AppStateEventNotifier.appStateStream.listen(_onAppStateChanged);
  }

  Future<void> cancel() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _onAppStateChanged(AppState appState) {
    log('New AppState state: $appState');
    if (appState == AppState.background) {
      if (!appOpenAdManager.isAdAvailable) {
        appOpenAdManager.loadAd();
      }
      return;
    }
    if (appState == AppState.foreground) {
      if (suppressAppOpenAdOnNextResume) {
        suppressAppOpenAdOnNextResume = false;
        log('AppLifecycleReactor: suppressed AppOpen ad on this resume.');
        return;
      }
      appOpenAdManager.showAdIfAvailable();
    }
  }
}
