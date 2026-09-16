import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class FloatingAiButton extends StatelessWidget {
  final VoidCallback onPressed;

  const FloatingAiButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.fabGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.mic, color: Colors.white, size: 28),
      ),
    );
  }
}
