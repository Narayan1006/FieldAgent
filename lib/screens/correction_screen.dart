import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import '../services/database_service.dart';
import '../tools/log_visit_entry.dart';
import '../widgets/editable_field_card.dart';
import '../theme/app_theme.dart';
import 'visit_screen.dart';

class CorrectionScreen extends StatefulWidget {
  final Patient patient;
  final Visit visit;
  final Map<String, String> extractedFields;

  const CorrectionScreen({
    super.key,
    required this.patient,
    required this.visit,
    required this.extractedFields,
  });

  @override
  State<CorrectionScreen> createState() => _CorrectionScreenState();
}

class _CorrectionScreenState extends State<CorrectionScreen> {
  late Map<String, String> _fields;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fields = {
      'name': widget.extractedFields['name'] ?? widget.patient.name,
      'age': widget.extractedFields['age'] ?? widget.patient.age.toString(),
      'anc_number': widget.extractedFields['anc_number'] ?? widget.patient.ancNumber,
      'lmp_date': widget.extractedFields['lmp_date'] ?? widget.patient.lmpDate,
      'edd': widget.extractedFields['edd'] ?? widget.patient.edd,
      'village': widget.extractedFields['village'] ?? widget.patient.village,
    };
  }

  void _updateField(String key, String value) {
    setState(() => _fields[key] = value);
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      // Update patient record with any corrected fields
      final updatedPatient = widget.patient.copyWith(
        name: _fields['name']!.isNotEmpty ? _fields['name'] : null,
        age: int.tryParse(_fields['age'] ?? '') ?? widget.patient.age,
        village: _fields['village']!.isNotEmpty ? _fields['village'] : null,
        ancNumber: _fields['anc_number'],
        lmpDate: _fields['lmp_date'],
        edd: _fields['edd'],
      );
      await DatabaseService.instance.insertPatient(updatedPatient);

      // Log key fields to the visit record
      if (_fields['lmp_date']!.isNotEmpty) {
        await logVisitEntry(
            visitId: widget.visit.id, field: 'notes', value: 'LMP: ${_fields['lmp_date']}');
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VisitScreen(
            patient: updatedPatient,
            visit: widget.visit,
          ),
        ),
      );
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Card Details'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 2 / 5,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4,
          ),
        ),
      ),
      body: Column(
        children: [
          // Info strip
          Container(
            color: AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                const Icon(Icons.touch_app_outlined, color: Colors.white70, size: 18),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Tap any field to correct it',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                _SectionHeader(title: 'Patient Details', icon: Icons.person_outline),
                EditableFieldCard(
                  label: 'FULL NAME',
                  value: _fields['name'] ?? '',
                  hint: 'Enter patient name',
                  onChanged: (v) => _updateField('name', v),
                  index: 0,
                ).animate().fadeIn(duration: 200.ms, delay: 0.ms),
                EditableFieldCard(
                  label: 'AGE',
                  value: _fields['age'] ?? '',
                  hint: 'Enter age',
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _updateField('age', v),
                  index: 1,
                ).animate().fadeIn(duration: 200.ms, delay: 50.ms),
                EditableFieldCard(
                  label: 'VILLAGE / LOCALITY',
                  value: _fields['village'] ?? '',
                  hint: 'Enter village',
                  onChanged: (v) => _updateField('village', v),
                  index: 2,
                ).animate().fadeIn(duration: 200.ms, delay: 100.ms),

                const SizedBox(height: AppSpacing.md),
                _SectionHeader(title: 'ANC Registration', icon: Icons.assignment_outlined),
                EditableFieldCard(
                  label: 'ANC NUMBER',
                  value: _fields['anc_number'] ?? '',
                  hint: 'e.g. ANC-2024-001',
                  onChanged: (v) => _updateField('anc_number', v),
                  index: 3,
                ).animate().fadeIn(duration: 200.ms, delay: 150.ms),
                EditableFieldCard(
                  label: 'LMP DATE (Last Menstrual Period)',
                  value: _fields['lmp_date'] ?? '',
                  hint: 'YYYY-MM-DD',
                  onChanged: (v) => _updateField('lmp_date', v),
                  index: 4,
                ).animate().fadeIn(duration: 200.ms, delay: 200.ms),
                EditableFieldCard(
                  label: 'EDD (Expected Delivery Date)',
                  value: _fields['edd'] ?? '',
                  hint: 'YYYY-MM-DD',
                  onChanged: (v) => _updateField('edd', v),
                  index: 5,
                ).animate().fadeIn(duration: 200.ms, delay: 250.ms),

                const SizedBox(height: 80),
              ],
            ),
          ),

          // Bottom CTA
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _confirm,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label: Text(_saving ? 'Saving…' : 'Confirm & Continue to Visit'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
