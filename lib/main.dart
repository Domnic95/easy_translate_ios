import 'dart:async';

import 'utils/constants.dart';
import 'screens/splash.dart';
import 'utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:easy_translate/providers/conversation_provider.dart';
import 'package:easy_translate/providers/deps.dart';
import 'package:easy_translate/providers/favorites_provider.dart';
import 'package:easy_translate/providers/history_provider.dart';
import 'package:easy_translate/providers/ocr_provider.dart';
import 'package:easy_translate/providers/settings_provider.dart';
import 'package:easy_translate/providers/translation_provider.dart';
import 'package:easy_translate/providers/voice_provider.dart';
import 'package:easy_translate/Google_Ads/ConfigController.dart';
import 'package:easy_translate/Google_Ads/SpHelper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PaintingBinding.instance.imageCache
    ..maximumSize = 60
    ..maximumSizeBytes = 30 * 1024 * 1024;
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Hive.initFlutter();
  bool compactWhenDeleted(int entries, int deletedEntries) =>
      deletedEntries >= 50;

  Future<void> openWithRecovery(String name) async {
    try {
      await Hive.openBox(name, compactionStrategy: compactWhenDeleted);
      return;
    } catch (e) {
      debugPrint('[main] openBox("$name") failed: $e — deleting + retrying');
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {}
      try {
        await Hive.openBox(name, compactionStrategy: compactWhenDeleted);
        return;
      } catch (e2) {
        debugPrint('[main] openBox("$name") failed again after wipe: $e2');
      }
    }
    try {
      await Hive.openBox(name);
    } catch (e3) {
      debugPrint('[main] openBox("$name") final fallback failed: $e3');
    }
  }

  await Future.wait([
    openWithRecovery(K.boxHistory),
    openWithRecovery(K.boxFavorites),
    openWithRecovery(K.boxSettings),
    openWithRecovery(K.boxConversations),
  ]);

  try {
    currentAppSettings = settingsRepo.read();
  } catch (e) {
    debugPrint('[main] settingsRepo.read() failed: $e — using defaults');
  }

  unawaited(
    tts.warmUp().catchError((e) {
      debugPrint('[main] tts.warmUp() failed: $e');
    }),
  );
  unawaited(
    speech.init().catchError((e) {
      debugPrint('[main] speech.init() failed: $e');
      return false;
    }),
  );
  unawaited(_bootGoogleAds());

  runApp(const EasyTranslateApp());
}

Future<void> _bootGoogleAds() async {
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint('MobileAds.initialize failed: $e');
  }
  await SpHelper().initialize();
  unawaited(configController.getConfigFromSharedPreferences());
  unawaited(configController.fetchConfig());
  unawaited(appOpenAdManager.loadAd());
}

class EasyTranslateApp extends StatelessWidget {
  const EasyTranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => TranslationProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
        ChangeNotifierProvider(create: (_) => ConversationProvider()),
        ChangeNotifierProvider(create: (_) => OcrProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider<ConfigController>.value(value: configController),
      ],
      child: Consumer<SettingsProvider>(
        builder: (_, s, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: K.appName,
          navigatorKey: navigatorKey,
          themeMode: s.themeMode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
