import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../tools/flag_danger_signs.dart';
import '../theme/app_theme.dart';

class DangerBanner extends StatelessWidget {
  final DangerSignResult result;

  const DangerBanner({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (!result.hasFlags) return const SizedBox.shrink();

    final isCritical = result.isCritical;
    final bgColor = isCritical ? AppColors.dangerLight : AppColors.warningLight;
    final borderColor = isCritical ? AppColors.danger : AppColors.warning;
    final textColor = isCritical ? AppColors.danger : AppColors.warning;
    final icon = isCritical ? Icons.emergency_rounded : Icons.warning_amber_rounded;

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isCritical ? 'DANGER SIGNS DETECTED' : 'CAUTION',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...result.flags.map((flag) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(flag.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        flag.message,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: flag.level == DangerLevel.critical
                              ? AppColors.danger
                              : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          if (isCritical) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Refer to PHC immediately',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .shake(duration: isCritical ? 400.ms : 0.ms, hz: 3, offset: const Offset(4, 0));
  }
}
