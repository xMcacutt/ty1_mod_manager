import 'package:flutter/material.dart';

class AppColors {
  // Surface Colors
  static const Color mainBack = Color(0xff212426);
  static const Color altBack = Color(0xff343638);
  static const Color specialBack = Color(0xff4c4e50);
  static const Color mainText = Color(0xffffffff);
  static const Color altText = Color.fromARGB(255, 185, 185, 185);
  static const Color invertedText = Color(0xff000000);
  static const Color mainAccent = Color(0xffe79941);
  static const Color mainAccentOn = Color.fromARGB(255, 117, 80, 38);
  static const Color altAccent = Color(0xff29609f);
  static const Color altAccentOn = Color.fromARGB(255, 64, 83, 104);
}

ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.mainAccent,
  scaffoldBackgroundColor: AppColors.mainBack,
  appBarTheme: AppBarTheme(
    toolbarHeight: 150,
    backgroundColor: const Color.fromARGB(255, 25, 27, 28),
    titleTextStyle: TextStyle(color: AppColors.mainText, fontSize: 20),
    iconTheme: IconThemeData(color: AppColors.mainAccent),
  ),
  drawerTheme: DrawerThemeData(backgroundColor: AppColors.altBack),
  colorScheme: ColorScheme.dark(
    primary: AppColors.mainAccent,
    onPrimary: AppColors.mainAccentOn,
    secondary: const Color.fromARGB(255, 41, 41, 159),
    surface: AppColors.altAccentOn,
    onSurface: AppColors.mainText,
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: AppColors.mainText, fontSize: 16),
    bodyMedium: TextStyle(color: AppColors.altText, fontSize: 14),
    bodySmall: TextStyle(color: AppColors.specialBack, fontSize: 12),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.all(AppColors.altBack),
    ),
  ),
  dialogTheme: DialogThemeData(backgroundColor: AppColors.altBack),
  sliderTheme: SliderThemeData(
    valueIndicatorShape: PaddleSliderValueIndicatorShape(),
    valueIndicatorColor: AppColors.mainAccentOn,
    valueIndicatorTextStyle: TextStyle(
      color: AppColors.mainText,
      fontFamily: 'Komika_Hands',
      fontSize: 18,
    ),
  ),
);
