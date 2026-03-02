import 'package:flutter/material.dart';

class ThemeModeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isLightMode => _themeMode == ThemeMode.light;

  void toggleTheme(bool useLightMode) {
    _themeMode = useLightMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
