import 'dart:developer';

import 'package:easy_translate/Google_Ads/Config.dart';
import 'package:easy_translate/providers/deps.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdManager extends StatefulWidget {
  final bool initLoad;
  const BannerAdManager({super.key, this.initLoad = true});

  @override
  State<BannerAdManager> createState() => _BannerAdManagerState();
}

class _BannerAdManagerState extends State<BannerAdManager> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _loadStarted = false;
  bool _shutOff = false;
  int _lastShutdownRev = configController.adsShutdownRevision;
  VoidCallback? _configListener;

  @override
  void initState() {
    super.initState();
    _configListener = _onConfigChanged;
    configController.addListener(_configListener!);
    _maybeStartLoad();
  }

  @override
  void didUpdateWidget(BannerAdManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initLoad && !oldWidget.initLoad) {
      _maybeStartLoad();
    }
  }

  @override
  void dispose() {
    final l = _configListener;
    if (l != null) configController.removeListener(l);
    _configListener = null;
    _bannerAd?.dispose();
    super.dispose();
  }

  void _onConfigChanged() {
    if (!mounted) return;
    final rev = configController.adsShutdownRevision;
    if (rev > _lastShutdownRev) {
      _lastShutdownRev = rev;
      _bannerAd?.dispose();
      _bannerAd = null;
      setState(() {
        _isLoaded = false;
        _shutOff = true;
      });
    }
  }

  void _maybeStartLoad() {
    if (!widget.initLoad || _loadStarted) return;
    _loadStarted = true;
    _initIfEnabled();
  }

  Future<void> _initIfEnabled() async {
    final adsOn = await Config().showAds();
    if (!mounted || adsOn != true) return;

    final adUnitId = await Config().bannerAdUnitId();
    if (!mounted) return;
    if (adUnitId == null || adUnitId.isEmpty) {
      log('Banner: no ad unit id in config, skipping.');
      return;
    }

    final ad = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (loaded) {
          log('$loaded loaded.');
          if (!mounted) {
            loaded.dispose();
            return;
          }
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          log('BannerAd failed to load: $err');
          ad.dispose();
        },
      ),
    );
    if (!mounted) {
      ad.dispose();
      return;
    }
    _bannerAd = ad;
    await ad.load();
  }

  @override
  Widget build(BuildContext context) {
    if (_shutOff) return const SizedBox.shrink();
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
