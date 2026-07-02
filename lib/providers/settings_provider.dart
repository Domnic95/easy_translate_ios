import 'dart:async';

import 'deps.dart';
import 'package:easy_translate/models/app_settings.dart';
import 'package:flutter/material.dart';

export 'package:easy_translate/models/app_settings.dart' show ConversationMode;

class SettingsProvider extends ChangeNotifier {
  AppSettings settings = const AppSettings();
  ThemeMode get themeMode => settings.themeMode;

  void load() {
    settings = settingsRepo.read();
    currentAppSettings = settings;
    notifyListeners();
  }

  void _save(AppSettings next) {
    settings = next;
    currentAppSettings = next;
    notifyListeners();
    unawaited(
      settingsRepo.write(next).catchError((e) {
        debugPrint(
          '[settings] write failed: $e — change will revert on next launch',
        );
      }),
    );
  }

  void setTheme(ThemeMode m) => _save(settings.copyWith(themeMode: m));
  void setSource(String c) => _save(settings.copyWith(defaultSource: c));
  void setTarget(String c) => _save(settings.copyWith(defaultTarget: c));
  void setAutoSpeak(bool v) => _save(settings.copyWith(autoSpeak: v));
  void setRate(double v) => _save(settings.copyWith(speechRate: v));
  void setSaveHistory(bool v) => _save(settings.copyWith(saveHistory: v));
  void setConversationMode(ConversationMode m) =>
      _save(settings.copyWith(conversationMode: m));
  void resetToDefaults() => _save(const AppSettings());
}
