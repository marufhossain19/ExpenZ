import 'package:flutter/material.dart';
import '../services/hive_service.dart';

/// Manages dark/light theme state and persists user preference.
class ThemeProvider extends ChangeNotifier {
  final HiveService _hiveService;
  bool _isDarkMode = false;

  ThemeProvider(this._hiveService) {
    _loadTheme();
  }

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Load saved theme preference from Hive
  void _loadTheme() {
    _isDarkMode = _hiveService.getSetting('isDarkMode', defaultValue: false);
  }

  /// Toggle between dark and light theme
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _hiveService.saveSetting('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  /// Set theme explicitly
  void setDarkMode(bool value) {
    _isDarkMode = value;
    _hiveService.saveSetting('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}
