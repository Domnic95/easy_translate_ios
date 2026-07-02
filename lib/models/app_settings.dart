import 'package:flutter/material.dart';

enum ConversationMode { face, chat }

class AppSettings {
  final ThemeMode themeMode;
  final String defaultSource;
  final String defaultTarget;
  final bool autoSpeak;
  final double speechRate;
  final bool saveHistory;
  final ConversationMode conversationMode;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.defaultSource = 'auto',
    this.defaultTarget = 'hi',
    this.autoSpeak = false,
    this.speechRate = 0.5,
    this.saveHistory = true,
    this.conversationMode = ConversationMode.face,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? defaultSource,
    String? defaultTarget,
    bool? autoSpeak,
    double? speechRate,
    bool? saveHistory,
    ConversationMode? conversationMode,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    defaultSource: defaultSource ?? this.defaultSource,
    defaultTarget: defaultTarget ?? this.defaultTarget,
    autoSpeak: autoSpeak ?? this.autoSpeak,
    speechRate: speechRate ?? this.speechRate,
    saveHistory: saveHistory ?? this.saveHistory,
    conversationMode: conversationMode ?? this.conversationMode,
  );

  static const schemaVersion = 3;

  Map<String, dynamic> toMap() => {
    'schemaVersion': schemaVersion,
    'themeMode': themeMode.index,
    'defaultSource': defaultSource,
    'defaultTarget': defaultTarget,
    'autoSpeak': autoSpeak,
    'speechRate': speechRate,
    'saveHistory': saveHistory,
    'conversationMode': conversationMode.index,
  };

  factory AppSettings.fromMap(Map m) => AppSettings(
    themeMode:
        ThemeMode.values[((m['themeMode'] as int?) ?? 0).clamp(
          0,
          ThemeMode.values.length - 1,
        )],
    defaultSource: (m['defaultSource'] as String?) ?? 'auto',
    defaultTarget: (m['defaultTarget'] as String?) ?? 'hi',
    autoSpeak: (m['autoSpeak'] as bool?) ?? false,
    speechRate: (m['speechRate'] as num?)?.toDouble() ?? 0.5,
    saveHistory: (m['saveHistory'] as bool?) ?? true,
    conversationMode:
        ConversationMode.values[((m['conversationMode'] as int?) ?? 0).clamp(
          0,
          ConversationMode.values.length - 1,
        )],
  );
}
