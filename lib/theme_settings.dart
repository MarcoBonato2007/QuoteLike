import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeSettings extends ChangeNotifier {
  bool isColorThemeLight;

  ThemeSettings(this.isColorThemeLight);

  ThemeData get themeData {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: isColorThemeLight ? Colors.white : Colors.black,
        brightness: isColorThemeLight ? Brightness.light : Brightness.dark,
      ),
    );
  }

  Future<void> invertColorTheme() async {
    isColorThemeLight = !isColorThemeLight;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isColorThemeLight", !isColorThemeLight);
    notifyListeners();
  }
}