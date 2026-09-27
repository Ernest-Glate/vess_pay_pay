import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color royalGold = Color(0xFFD4AF37);
  static const Color royalGoldLight = Color(0xFFF2D06B);
  static const Color forestDepths = Color(0xFF1B4D3E);
  static const Color deepGreen1 = Color(0xFF022C22);
  static const Color deepGreen2 = Color(0xFF0F392B);
  static const Color royalBlue = Color(0xFF0047AB);
  
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFFA0A0A0);
  
  static const Color surface = Color(0xB2141414); // 70% opacity of #141414
  static const Color surfaceBorder = Color(0x26D4AF37); // 15% opacity of royalGold
  
  static const Color inputBg = Color(0x0FFFFFFF); // 6% opacity of white
  static const Color inputBorder = Color(0x33FFFFFF); // 20% opacity of white
  
  static const Color danger = Color(0xFFD32F2F);
  static const Color error = Color(0xFFFF5252);
  static const Color errorRed = Color(0xFFFF5252); // Alias for compatibility
  static const Color success = Color(0xFF4CAF50);
  static const Color successGreen = Color(0xFF4CAF50); // Alias for compatibility
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
  
  // Additional colors for premium features
  static const Color cardBg = Color(0x1AFFFFFF); // 10% white, for cards
  static const Color darkBg = Color(0xFF0F392B); // Dark background
  static const Color borderGray = Color(0x33FFFFFF); // 20% white for borders
  
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  static const LinearGradient verticalGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepGreen1, forestDepths, deepGreen2],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1AFFFFFF), // 10% white
      Color(0x0DFFFFFF), // 5% white
    ],
  );
}
