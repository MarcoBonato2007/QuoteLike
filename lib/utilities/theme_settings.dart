import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quotelike/utilities/globals.dart';

/// A button to swap the theme between light and dark modes
class SwapThemeButton extends StatefulWidget {
  const SwapThemeButton({super.key});

  @override
  State<SwapThemeButton> createState() => _SwapThemeButtonState();
}

class _SwapThemeButtonState extends State<SwapThemeButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      label: Text("Swap color theme"), 
      icon: Provider.of<ThemeSettings>(context, listen: false)._isColorThemeLight ? Icon(Icons.light_mode) : Icon(Icons.dark_mode), 
      onPressed: () async {
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
  bool _isColorThemeLight;
  ThemeSettings(this._isColorThemeLight);

  ColorScheme get colorScheme => ColorScheme.fromSeed(
    seedColor: _isColorThemeLight ? Colors.white : Colors.black,
    brightness: _isColorThemeLight ? Brightness.light : Brightness.dark,
  );
  
  ThemeData get themeData => ThemeData(
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10)),
      elevation: 1
    )),
    filledButtonTheme: FilledButtonThemeData(style: ElevatedButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10)),
      elevation: 2
    )),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
      minimumSize: Size.zero, 
      padding: EdgeInsetsGeometry.only(left: 6, right: 6),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap
    )),
    cardTheme: CardThemeData(elevation: 2),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsetsGeometry.zero
      )
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 2,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.surface,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.primary,
      behavior: SnackBarBehavior.floating,
      showCloseIcon: true
    ),
    colorScheme: colorScheme,
  );

  Future<void> invertColorTheme() async {
    _isColorThemeLight = !_isColorThemeLight;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isColorThemeLight", _isColorThemeLight);
    notifyListeners();
  }
}
