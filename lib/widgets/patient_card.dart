import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/patient.dart';
import '../models/patient_type.dart';
import '../models/visit.dart';
import '../theme/app_theme.dart';

class PatientCard extends StatelessWidget {
  final Patient patient;
  final Visit? lastVisit;
  final VoidCallback onStartVisit;
  final int index;

  const PatientCard({
    super.key,
    required this.patient,
    this.lastVisit,
    required this.onStartVisit,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final lastVisitText = lastVisit != null
        ? 'Last: ${lastVisit!.visitDate}'
        : 'No visits yet';
    final isSynced = patient.syncStatus == 'synced';
    final typeColor = Color(patient.patientType.colorValue);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onStartVisit,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(children: [
            // Avatar: type emoji with category color ring
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: typeColor.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Center(
                child: Text(patient.patientType.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Details
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Name + sync badge
                Row(children: [
                  Expanded(
                    child: Text(patient.name, style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 4),
                  Text(isSynced ? '✅' : '🔄', style: const TextStyle(fontSize: 12)),
                ]),
                const SizedBox(height: 3),
                // Type chip + location + age
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(patient.patientType.shortLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: typeColor)),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 2),
                  Flexible(child: Text(patient.village, style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 4),
                  Text('• ${patient.age}y', style: Theme.of(context).textTheme.bodyMedium),
                ]),
                const SizedBox(height: 4),
                // Last visit
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textHint),
                  const SizedBox(width: 3),
                  Text(lastVisitText, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                ]),
              ]),
            ),
            // Arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_forward_ios, size: 16, color: typeColor),
            ),
          ]),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0, duration: 300.ms);
  }
}
