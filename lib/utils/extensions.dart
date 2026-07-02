import 'package:flutter/material.dart';

extension Ctx on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  void snack(String message) {
    ScaffoldMessenger.of(this)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

extension Str on String {
  bool get isBlank => trim().isEmpty;

  bool get hasCensorMark =>
      contains(RegExp(r'\b(?:[A-Za-z]+\*{2,}|[A-Za-z]+\*[A-Za-z]+)\b'));

  bool get hasProfanity =>
      _profanity.isNotEmpty &&
      RegExp(
        r'\b(' + _profanity.join('|') + r')\b',
        caseSensitive: false,
      ).hasMatch(this);

  String get censored {
    if (isEmpty || _profanity.isEmpty) return this;
    return replaceAllMapped(
      RegExp(r'\b(' + _profanity.join('|') + r')\b', caseSensitive: false),
      (m) {
        final w = m.group(0)!;
        return w.length <= 1 ? w : w[0] + '*' * (w.length - 1);
      },
    );
  }
}

const _profanity = <String>[];
