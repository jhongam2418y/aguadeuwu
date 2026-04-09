import 'package:flutter/material.dart';

class AppColors {
  // Colores primarios (teal)
  static const Color primaryBlue         = Color(0xFF00695C);
  static const Color darkBlue            = Color(0xFF004D40);
  static const Color primaryLight        = Color(0xFFE0F2F1);
  static const Color lightBlueBackground = Color(0xFFF1FAF8);
  static const Color panelBg             = Color(0xFFD0EEEA);

  // Bordes
  static const Color blueBorder      = Color(0xFF80CBC4);
  static const Color tealBorderLight = Color(0xFFB2DFDB);

  // Texto
  static const Color text     = Color(0xFF1A1A1A);
  static const Color textSoft = Color(0xFF4E6D68);
  static const Color lightGrey = Color(0xFF9E9E9E);

  // Semánticos
  static const Color green        = Color(0xFF2E7D32);
  static const Color greenLight   = Color(0xFFE8F5E9);
  static const Color errorLight   = Color(0xFFFFF0F0);
  static const Color warmYellowBg = Color(0xFFFFF8E1);

  // Opacidades del primaryBlue
  static final Color blueOpacity09 = const Color(0xFF00695C).withValues(alpha: 0.09);
  static final Color blueOpacity10 = const Color(0xFF00695C).withValues(alpha: 0.1);
  static final Color blueOpacity28 = const Color(0xFF00695C).withValues(alpha: 0.28);
  static final Color blueOpacity35 = const Color(0xFF00695C).withValues(alpha: 0.35);
}