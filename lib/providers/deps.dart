import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../Google_Ads/AppOpenAds/AppLifeCycleReactor.dart';
import '../Google_Ads/BannerAds/AppOpenManager.dart';
import '../Google_Ads/ConfigController.dart';
import '../Google_Ads/NativeAdGate.dart';
import '../models/app_settings.dart';
import '../repositories/conversation_repository.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/history_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/ocr_service.dart';
import '../services/speech_service.dart';
import '../services/translator_service.dart';
import '../services/tts_service.dart';

final translator = TranslatorService();
final speech = SpeechService();
final tts = TtsService();
final ocr = OcrService();
final historyRepo = HistoryRepository();
final favoritesRepo = FavoritesRepository();
final settingsRepo = SettingsRepository();
final conversationRepo = ConversationRepository();
final configController = ConfigController();
final navigatorKey = GlobalKey<NavigatorState>();
final appOpenAdManager = AppOpenAdManager();
final AppLifecycleReactor appLifecycleReactor = AppLifecycleReactor(
  appOpenAdManager: appOpenAdManager,
);
final activeTabIndex = ValueNotifier<int>(0);
final nativeAdGate = NativeAdGate();
bool suppressAppOpenAdOnNextResume = false;
AppSettings currentAppSettings = const AppSettings();
const uuid = Uuid();
