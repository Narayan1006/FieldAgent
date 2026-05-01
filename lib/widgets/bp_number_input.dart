import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class BpNumberInput extends StatelessWidget {
  final String label;
  final int? value;
  final Function(int?) onChanged;
  final Color? accentColor;

  const BpNumberInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md)),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: TextFormField(
              initialValue: value?.toString() ?? '',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -1,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '---',
                hintStyle: TextStyle(
                  fontSize: 36,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w300,
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) {
                onChanged(int.tryParse(v));
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'mmHg',
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
