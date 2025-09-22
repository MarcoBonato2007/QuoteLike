import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quotelike/utilities/globals.dart';
import 'package:quotelike/widgets/standard_widgets.dart';

/// A button to swap the theme between light and dark modes
class SwapThemeButton extends StatefulWidget {
  const SwapThemeButton({super.key});

  @override
  State<SwapThemeButton> createState() => _SwapThemeButtonState();
}

class _SwapThemeButtonState extends State<SwapThemeButton> {
  @override
  Widget build(BuildContext context) {
    return StandardSettingsButton(
      "Swap color theme", 
      Provider.of<ThemeSettings>(context, listen: false).isColorThemeLight ? Icon(Icons.light_mode) : Icon(Icons.dark_mode), 
      () async {
        showLoadingIcon();
        await Provider.of<ThemeSettings>(context, listen: false).invertColorTheme();
        setState(() {});
        hideLoadingIcon();
      }
    );
  }
}

/// Used to keep track of theme settings for the program.
/// 
/// Only one instance exists, in main()
class ThemeSettings extends ChangeNotifier {
  bool isColorThemeLight;
  double elevation = 2;

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
    await prefs.setBool("isColorThemeLight", isColorThemeLight);
    notifyListeners();
  }
}
