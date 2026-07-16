import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _currency = '\$'; // Default USD Symbol
  bool _notificationsEnabled = true;
  String _languageCode = 'en'; // Ready structure for localization

  ThemeMode get themeMode => _themeMode;
  String get currency => _currency;
  bool get notificationsEnabled => _notificationsEnabled;
  String get languageCode => _languageCode;

  SettingsProvider() {
    _loadSettings();
  }

  // Load preferences from local storage
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Theme
    final themeIndex = prefs.getInt('theme_mode');
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    // Currency
    _currency = prefs.getString('currency') ?? '\$';

    // Notifications
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    // Language
    _languageCode = prefs.getString('language_code') ?? 'en';

    notifyListeners();
  }

  // Toggle Theme
  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', _themeMode.index);
  }

  // Set Currency Symbol
  Future<void> setCurrency(String symbol) async {
    _currency = symbol;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', symbol);
  }

  // Toggle Notifications
  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  // Set Language
  Future<void> setLanguage(String code) async {
    _languageCode = code;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
  }
}
