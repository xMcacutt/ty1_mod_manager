import 'package:flutter/material.dart';

class AppColors {
  // Surface Colors
  static const Color mainBack = Color(0xff212426);
  static const Color altBack = Color(0xff343638);
  static const Color specialBack = Color(0xff4c4e50);
  static const Color mainText = Color(0xffffffff);
  static const Color altText = Color(0xff999999);
  static const Color invertedText = Color(0xff000000);
  static const Color mainAccent = Color(0xffe79941);
  static const Color mainAccentOn = Color.fromARGB(255, 127, 105, 79);
  static const Color altAccent = Color(0xff29609f);
  static const Color altAccentOn = Color.fromARGB(255, 64, 83, 104);
}

ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.mainAccent,
  scaffoldBackgroundColor: AppColors.mainBack,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.altBack,
    titleTextStyle: TextStyle(color: AppColors.mainText, fontSize: 20),
    iconTheme: IconThemeData(color: AppColors.mainAccent),
  ),
  drawerTheme: DrawerThemeData(backgroundColor: AppColors.altBack),
  colorScheme: ColorScheme.dark(
    primary: AppColors.mainAccent,
    onPrimary: AppColors.mainAccentOn,
    secondary: AppColors.altAccent,
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
);
