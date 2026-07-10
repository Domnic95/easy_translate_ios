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
}
