import 'package:flutter/material.dart';
import '../../../../core/app_colors.dart';

/// Botón con flecha grande usado en los contadores de adultos/niños.
class FlechaBtn extends StatelessWidget {
  final IconData icono;
  final bool habilitado;
  final VoidCallback onTap;

  const FlechaBtn({
    super.key,
    required this.icono,
    required this.habilitado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: habilitado ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: habilitado ? AppColors.primaryBlue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
          boxShadow: habilitado
              ? [
                  BoxShadow(
                      color: AppColors.blueOpacity35,
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : const [],
        ),
        child: Icon(
          icono,
          color: habilitado ? Colors.white : Colors.grey.shade400,
          size: 28,
        ),
      ),
    );
  }
}
