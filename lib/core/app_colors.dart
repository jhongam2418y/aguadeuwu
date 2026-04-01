import 'package:flutter/material.dart';
//AppColors.greyText
class AppColors {
  // Colores primarios — teal profundo (evoca agua/naturaleza)
  static const Color primaryBlue = Color(0xFF00695C);
  static const Color darkBlue = Color(0xFF004D40);

  // Colores secundarios/acentos
  static const Color lightBlueBackground = Color(0xFFF1FAF8);
  static const Color borderBlue = Color(0xFFB2DFDB);
  static const Color greyText = Colors.grey;
  static const Color lightGreyBackground = Color(0xFFF5FAFA);

  // Colores de estado
  static const Color successGreen = Color(0xFFE8F5E9);
  static const Color successGreenText = Colors.green;
  static const Color warningOrange = Color(0xFFFF8F00);
  static const Color warningOrangeBackground = Color(0xFFFFF8E1);
  static const Color errorRed = Colors.red;
  static const Color errorRedText = Colors.redAccent;

  // Colores de texto y elementos generales
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color mediumGrey = Color(0xFF424242);
  static const Color lightGrey = Colors.grey;
  static const Color grey300 = Colors.grey;
  static const Color grey400 = Colors.grey;

  // Transparencias para sombras y fondos
  static Color blackOpacity07 = Colors.black.withValues(alpha: 0.07);
  static Color blackOpacity12 = Colors.black.withValues(alpha: 0.12);
  static Color blackOpacity05 = Colors.black.withValues(alpha: 0.05);

  // Opacidades primarias
  static final Color blueOpacity10 = const Color(0xFF00695C).withValues(alpha: 0.1);
  static final Color blueOpacity09 = const Color(0xFF00695C).withValues(alpha: 0.09);
  static final Color blueOpacity35 = const Color(0xFF00695C).withValues(alpha: 0.35);
  static final Color blueOpacity28 = const Color(0xFF00695C).withValues(alpha: 0.28);
}