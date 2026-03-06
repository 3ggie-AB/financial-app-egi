// providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('themeMode') ?? 'system';
    _themeMode = mode == 'light'
        ? ThemeMode.light
        : mode == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system;
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode',
        mode == ThemeMode.light ? 'light' : mode == ThemeMode.dark ? 'dark' : 'system');
    notifyListeners();
  }
}
