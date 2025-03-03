import 'package:flutter/material.dart';

class AppColors {
  // Netflix color palette
  static const Color netflixRed = Color(0xFFE50914);
  static const Color netflixBlack = Color(0xFF000000);
  static const Color netflixDarkGrey = Color(0xFF221F1F);
  static const Color netflixLightGrey = Color(0xFF8C8787);
  static const Color netflixWhite = Color(0xFFFFFFFF);
  
  // Background gradients
  static const LinearGradient blackGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Colors.black87,
      Colors.black,
    ],
  );
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.netflixBlack,
    primaryColor: AppColors.netflixRed,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.netflixRed,
      secondary: AppColors.netflixRed,
      background: AppColors.netflixBlack,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.netflixBlack,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.netflixWhite,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: AppColors.netflixWhite,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: AppColors.netflixWhite,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        color: AppColors.netflixWhite,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: AppColors.netflixLightGrey,
        fontSize: 14,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.netflixBlack,
      selectedItemColor: AppColors.netflixWhite,
      unselectedItemColor: AppColors.netflixLightGrey,
    ),
  );
}