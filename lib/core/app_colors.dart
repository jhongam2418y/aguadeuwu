import 'package:flutter/material.dart';
//AppColors.greyText
class AppColors {
  // Colores primarios
  static const Color primaryBlue = Color(0xFF0052CC);
  static const Color darkBlue = Color(0xFF003D99);

  // Colores secundarios/acentos
  static const Color lightBlueBackground = Color(0xFFF0F7FF);
  static const Color borderBlue = Color(0xFFCCE0FF);
  static const Color greyText = Colors.grey;
  static const Color lightGreyBackground = Color(0xFFF8F9FA);

  // Colores de estado
  static const Color successGreen = Color(0xFFE8F5E9); // Usado en impresora card
  static const Color successGreenText = Colors.green; // Para texto
  static const Color warningOrange = Colors.orange;
  static const Color warningOrangeBackground = Color(0xFFFFF8E1);
  static const Color errorRed = Colors.red;
  static const Color errorRedText = Colors.redAccent; // O un tono específico de rojo

  // Colores de texto y elementos generales
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color mediumGrey = Color(0xFF424242);
  static const Color lightGrey = Colors.grey;
  static const Color grey300 = Colors.grey; // Usado para divisores
  static const Color grey400 = Colors.grey; // Usado para QR placeholder

  // Transparencias para sombras y fondos
  static Color blackOpacity07 = Colors.black.withValues(alpha: 0.07);
  static Color blackOpacity12 = Colors.black.withValues(alpha:0.12);
  static Color blackOpacity05 = Colors.black.withValues(alpha:0.05);

  // Otros colores si son muy específicos y se repiten
  static final Color blueOpacity10 = const Color(0xFF0052CC).withValues(alpha: 0.1);
  static final Color blueOpacity09 = const Color(0xFF0052CC).withValues(alpha: 0.09);
  static final Color blueOpacity35 = const Color(0xFF0052CC).withValues(alpha: 0.35);
  static final Color blueOpacity28 = const Color(0xFF0052CC).withValues(alpha: 0.28);
}