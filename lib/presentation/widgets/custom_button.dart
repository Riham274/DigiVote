import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isSecondary;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: isSecondary
              ? null
              : const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryContainer],
                ),
          color: isSecondary ? AppColors.surfaceContainerHigh : null,
          boxShadow: isSecondary
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primaryContainer.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isSecondary ? AppColors.onSurface : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 12),
              Icon(
                icon,
                color: isSecondary ? AppColors.onSurface : Colors.white,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
