import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const _symptoms = [
  'Headache',
  'Swelling (Edema)',
  'Blurred Vision',
  'Bleeding',
  'Fever',
  'Fatigue',
  'Abdominal Pain',
  'Vomiting',
  'Reduced Fetal Movement',
  'None',
];

class SymptomChipSelector extends StatelessWidget {
  final List<String> selected;
  final Function(List<String>) onChanged;

  const SymptomChipSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  void _toggle(String symptom) {
    final updated = List<String>.from(selected);
    if (symptom == 'None') {
      onChanged(['None']);
      return;
    }
    updated.remove('None');
    if (updated.contains(symptom)) {
      updated.remove(symptom);
    } else {
      updated.add(symptom);
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _symptoms.map((symptom) {
        final isSelected = selected.contains(symptom);
        final isNone = symptom == 'None';

        return GestureDetector(
          onTap: () => _toggle(symptom),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isNone ? AppColors.successLight : AppColors.primaryLight.withOpacity(0.3))
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? (isNone ? AppColors.success : AppColors.primary)
                    : AppColors.chipBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      isNone ? Icons.check_circle_outline : Icons.check,
                      size: 14,
                      color: isNone ? AppColors.success : AppColors.primary,
                    ),
                  ),
                Text(
                  symptom,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? (isNone ? AppColors.success : AppColors.primary)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
