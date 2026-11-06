import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:scioly_codebusters/library.dart';

//import 'package:flutter_riverpod/flutter_riverpod.dart';

// Button dimensions for game controls (new quote, etc)
const buttonWidth = 200.0;
// inset padding
const insetPadding = 16.0;
//styling for cells
const containerWidth = 20.0;
const containerHeight = containerWidth * 1.25;
const decorationHeight = containerWidth * 0.7;
const containerFS = 15.0;
const decorationTextFS = 10.0;
const padding = 4.0;
// might need to change if screen size changes (rotation)
double get screenW => GameSetup.width;
double get screenH => GameSetup.height;
double get maxLength => (screenW * 0.9) - insetPadding * 2;
//styling for keyboard
const double spacing = 4;
const double undoButtonHeight = 40;
const double horizontalBuffer = 20;
double get safeWidth => screenW - horizontalBuffer;
final maxKeysInRow = 10;
double get keyWidth =>
    (safeWidth - (maxKeysInRow - 1) * spacing) / maxKeysInRow;
double get keyboardH => screenH * 0.25; // Height of the keyboard widget
const double desktopCommandsHeight = 56;
// dictionary styling
const borderWidth = 2.0;
const searchPadding = 12.0;
//panel height for timer etc.
const double panelHeight = 60.0;

AudioController? audioCont; // Audio controller to play soundeffects
String buttonClickAsset = "assets/music/sound_effects/button_click.mp3";
String keyboardClickAsset = "assets/music/sound_effects/keyboard_click.mp3";

Color gameCellColor = AppTheme.logoGreen;

String bgMusicFile = "assets/music/bg.mp3";
Box? settingsBox;
// user preference on whether the background should have teh matrix or not
bool bgMatrixOn = true;

/// ThemeProvider for the app. Exposes ThemeData globally via Riverpod.
final appThemeProvider = AppTheme.theme;

Map<int, String> months = {
  1: "January",
  2: "February",
  3: "March",
  4: "April",
  5: "May",
  6: "June",
  7: "July",
  8: "August",
  9: "September",
  10: "October",
  11: "November",
  12: "December",
};
Map<int, String> weekday = {
  1: "Monday",
  2: "Tuesday",
  3: "Wednesday",
  4: "Thursday",
  5: "Friday",
  6: "Saturday",
  7: "Sunday",
};

class AppTheme {
  static const Color primary = Color(0xFF00FF41);
  static const Color primaryLight = Color(0xFFD32F2F);
  static const Color primaryDark = Color(0xFF7F0000);
  static const Color background = Color(0xFF0a0a0a);
  static const Color appBarBackground = Colors.transparent;
  static const Color surface = Color(0xFFF5F5F5);
  static const Color accent = Color(0xFFEF5350); // Softer red
  static const Color logoGreen = Color(0xFF00FF41); // Also used for logo
  static const Color keyboardKey = Color(0xFFFAFAFA);
  static const Color keyboardKeyText = logoGreen;

  static const backgroundColors = [
    Color(0xFF0a0a0a),
    Color(0xFF1a0a2e),
    Color(0xFF16213e),
  ];
  static const BoxDecoration backgroundGradient = BoxDecoration(
    gradient: LinearGradient(
      colors: backgroundColors,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static final TextTheme textTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: logoGreen,
      fontFamily: 'JetBrainsMono',
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: logoGreen,
      fontFamily: 'JetBrainsMono',
    ),
    headlineSmall: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade700,
      wordSpacing: 5,
      fontFamily: 'JetBrainsMono',
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontFamily: 'JetBrainsMono',
      color: Colors.black87,
    ),
    labelLarge: TextStyle(fontSize: 14, color: primaryDark),
  );

  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    fontFamily: 'JetBrainsMono',
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      error: Colors.red,
      onError: Colors.white,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: appBarBackground,
      foregroundColor: logoGreen,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      labelStyle: TextStyle(color: primaryDark),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
    ),
  );

  // Custom widget styles
  static BoxDecoration customContainer = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
    ],
  );

  static BoxDecoration keyboardKeyDecoration = BoxDecoration(
    color: keyboardKey,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey.shade300),
  );

  static TextStyle keyboardKeyTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: gameCellColor,
  );

  static TextStyle decorationTextStyle = TextStyle(
    fontSize: decorationTextFS,
    fontWeight: FontWeight.w600,
    color: gameCellColor,
  );

  static ButtonStyle flatRedButton = TextButton.styleFrom(
    foregroundColor: primary,
    textStyle: const TextStyle(fontWeight: FontWeight.bold),
  );
}

String toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      })
      .join(' ');
}

Future<void> buttonClickSound() async {
  return audioCont?.playSound(buttonClickAsset);
}

Future<void> keyboardClickSound() async {
  return audioCont?.playSound(keyboardClickAsset);
}
