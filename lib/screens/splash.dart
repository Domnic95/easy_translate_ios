import 'dart:async';

import 'home.dart';
import 'onboarding.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_translate/widgets/animated_gradient.dart';
import 'package:easy_translate/Google_Ads/Config.dart';
import 'package:easy_translate/Google_Ads/ConfigController.dart';
import 'package:easy_translate/providers/deps.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _maxAdWait = Duration(seconds: 5);
  static const _absoluteTimeout = Duration(seconds: 10);
  static const _reactorAttachDelay = Duration(seconds: 5);
  static const _maxConfigWait = Duration(seconds: 3);
  static const _minSplashShown = Duration(milliseconds: 700);

  bool _navigated = false;
  Timer? _absoluteTimer;
  Timer? reactorTimer;
  Timer? _configWaitCap;
  VoidCallback? _configWaitListener;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _absoluteTimer?.cancel();
    reactorTimer?.cancel();
    _configWaitCap?.cancel();
    final l = _configWaitListener;
    if (l != null) {
      try {
        configController.removeListener(l);
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (ConfigController.cached == null) {
      unawaited(configController.fetchConfig());
    }

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(K.prefOnboardingDone) ?? false;

    final minSplashShown = Future<void>.delayed(_minSplashShown);
    _absoluteTimer = Timer(_absoluteTimeout, () => _go(seen));
    reactorTimer = Timer(_reactorAttachDelay, () {
      if (!mounted || _navigated) return;
      appLifecycleReactor.listenToAppStateChanges();
    });

    await _waitForConfig(maxWait: _maxConfigWait);
    if (!mounted || _navigated) return;

    final ifOpen = await Config().ifOpenAds();
    final showAds = await Config().showAds();
    final wantsAppOpen = ifOpen == 1 && showAds == true;

    if (!wantsAppOpen) {
      await minSplashShown;
      _go(seen);
      return;
    }

    final adReady = await appOpenAdManager.waitForAd(timeout: _maxAdWait);
    if (!mounted || _navigated) return;

    await minSplashShown;
    if (!mounted || _navigated) return;

    if (adReady) {
      appOpenAdManager.showAdIfAvailable(onBeforeShow: () => _go(seen));
    } else {
      _go(seen);
    }
  }

  Future<void> _waitForConfig({required Duration maxWait}) async {
    if (ConfigController.cached != null) return;
    await configController.getConfigFromSharedPreferences();
    if (ConfigController.cached != null) {
      unawaited(configController.fetchConfig());
      return;
    }

    final completer = Completer<void>();
    Timer? cap;
    late VoidCallback listener;
    void cleanup() {
      try {
        configController.removeListener(listener);
      } catch (_) {}
      cap?.cancel();
      _configWaitListener = null;
      _configWaitCap = null;
    }

    listener = () {
      if (ConfigController.cached != null && !completer.isCompleted) {
        cleanup();
        completer.complete();
      }
    };
    _configWaitListener = listener;
    configController.addListener(listener);
    unawaited(configController.fetchConfig());

    cap = Timer(maxWait, () {
      if (!completer.isCompleted) {
        cleanup();
        completer.complete();
      }
    });
    _configWaitCap = cap;

    await completer.future;
  }

  void _go(bool onboardingSeen) {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            onboardingSeen ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: AnimatedGradient(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: context.colors.onPrimary.withValues(alpha: 0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.translate_rounded,
                        size: 64,
                        color: context.colors.primary,
                      ),
                    )
                    .animate()
                    .scale(
                      begin: const Offset(0.6, 0.6),
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(),
                const SizedBox(height: 24),
                Text(
                  S.splash,
                  style: context.text.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.colors.onPrimaryContainer,
                  ),
                ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ).animate(delay: 800.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
