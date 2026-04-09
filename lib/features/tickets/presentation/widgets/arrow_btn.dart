import 'package:flutter/material.dart';
import '../../../../core/app_colors.dart';

/// Botón de flecha pequeño para el panel de pago dividido.
class ArrowBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const ArrowBtn({
    super.key,
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 52,
        height: 46,
        decoration: BoxDecoration(
          color: enabled ? AppColors.blueOpacity10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? AppColors.primaryBlue.withValues(alpha: 0.35)
                : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 30,
          color: enabled ? AppColors.primaryBlue : Colors.grey.shade400,
        ),
      ),
    );
  }
}
