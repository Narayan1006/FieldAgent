import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/patient.dart';
import '../models/patient_type.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';

class AddPatientScreen extends StatefulWidget {
  final String village;
  const AddPatientScreen({super.key, required this.village});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  PatientType _selectedType = PatientType.maternal;
  bool _saving = false;

  // Common fields
  final _name = TextEditingController();
  final _age  = TextEditingController();

  // Maternal
  final _ancNumber = TextEditingController();
  final _lmpDate   = TextEditingController();
  final _edd       = TextEditingController();

  // Child
  final _dob      = TextEditingController();
  String _gender  = 'Female';
  final _guardian = TextEditingController();

  // TB
  final _tbId      = TextEditingController();
  final _regimen   = TextEditingController();
  final _tbStart   = TextEditingController();
  final _tbSupport = TextEditingController();

  // Malaria/Dengue
  final _disease    = TextEditingController(text: 'Malaria');
  final _onsetDate  = TextEditingController();
  final _rdtResult  = TextEditingController();
  final _treatment  = TextEditingController();

  // Family Planning
  String _fpMethod = 'OCP';
  final _fpStart   = TextEditingController();

  // Newborn
  final _nbDob         = TextEditingController();
  String _nbGender     = 'Female';
  final _birthWeight   = TextEditingController();
  final _motherName    = TextEditingController();

  // General
  final _chiefComplaint = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _age, _ancNumber, _lmpDate, _edd, _dob, _guardian,
        _tbId, _regimen, _tbStart, _tbSupport, _disease, _onsetDate, _rdtResult,
        _treatment, _fpStart, _nbDob, _birthWeight, _motherName, _chiefComplaint]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      Map<String, dynamic> extra = {};
      String anc = '', lmp = '', edd = '';

      switch (_selectedType) {
        case PatientType.maternal:
          anc = _ancNumber.text.trim();
          lmp = _lmpDate.text.trim();
          edd = _edd.text.trim();
          break;
        case PatientType.child:
          extra = {
            'dob': _dob.text.trim(),
            'gender': _gender,
            'guardian': _guardian.text.trim(),
            'vaccines_given': <String>[],
            'next_vaccine': 'BCG',
            'next_due': '',
          };
          break;
        case PatientType.tb:
          extra = {
            'tb_id': _tbId.text.trim(),
            'regimen': _regimen.text.trim(),
            'start_date': _tbStart.text.trim(),
            'dots_supporter': _tbSupport.text.trim(),
          };
          break;
        case PatientType.malaria:
          extra = {
            'disease': _disease.text.trim(),
            'onset_date': _onsetDate.text.trim(),
            'rdt_result': _rdtResult.text.trim(),
            'treatment': _treatment.text.trim(),
          };
          break;
        case PatientType.familyPlanning:
          extra = {'method': _fpMethod, 'start_date': _fpStart.text.trim()};
          break;
        case PatientType.newborn:
          extra = {
            'dob': _nbDob.text.trim(),
            'gender': _nbGender,
            'birth_weight_kg': double.tryParse(_birthWeight.text.trim()) ?? 0,
            'mother_name': _motherName.text.trim(),
          };
          break;
        case PatientType.general:
          extra = {'chief_complaint': _chiefComplaint.text.trim()};
          break;
      }

      final patient = Patient(
        name: _name.text.trim(),
        age: int.tryParse(_age.text.trim()) ?? 0,
        village: widget.village,
        patientType: _selectedType,
        ancNumber: anc,
        lmpDate: lmp,
        edd: edd,
        extraData: extra,
      );

      await DatabaseService.instance.insertPatient(patient);
      await SyncService.instance.pushPatient(patient);

      if (mounted) {
        Navigator.pop(context, patient);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedType.emoji} ${patient.name} added'),
            backgroundColor: Color(_selectedType.colorValue),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add Patient')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── Type Selector ──────────────────────────────────
            _SectionHeader('Patient Category'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PatientType.values.map((t) {
                final selected = t == _selectedType;
                return ChoiceChip(
                  label: Text('${t.emoji} ${t.shortLabel}'),
                  selected: selected,
                  selectedColor: Color(t.colorValue).withValues(alpha: 0.85),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                  onSelected: (_) => setState(() => _selectedType = t),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Common fields ──────────────────────────────────
            _SectionHeader('Basic Information'),
            const SizedBox(height: AppSpacing.sm),
            _Field(label: 'Full Name', controller: _name, required: true),
            _Field(label: 'Age (years)', controller: _age, keyboardType: TextInputType.number),

            const SizedBox(height: AppSpacing.lg),

            // ── Type-specific fields ───────────────────────────
            _buildTypeFields(),

            const SizedBox(height: AppSpacing.xl),

            // ── Save button ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(_selectedType.colorValue),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Add ${_selectedType.label} Patient', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFields() {
    switch (_selectedType) {
      case PatientType.maternal:
        return Column(children: [
          _SectionHeader('Maternal Health'),
          const SizedBox(height: AppSpacing.sm),
          _Field(label: 'ANC Number', controller: _ancNumber),
          _Field(label: 'LMP Date (YYYY-MM-DD)', controller: _lmpDate),
          _Field(label: 'Expected Delivery Date', controller: _edd),
        ]);

      case PatientType.child:
        return Column(children: [
          _SectionHeader('Child Details'),
          const SizedBox(height: AppSpacing.sm),
          _Field(label: 'Date of Birth (YYYY-MM-DD)', controller: _dob, required: true),
          _Field(label: "Guardian's Name", controller: _guardian),
          _DropdownField(
            label: 'Gender',
            value: _gender,
            items: const ['Female', 'Male'],
            onChanged: (v) => setState(() => _gender = v!),
          ),
        ]);

      case PatientType.tb:
        return Column(children: [
          _SectionHeader('TB Details'),
          const SizedBox(height: AppSpacing.sm),
          _Field(label: 'TB Patient ID', controller: _tbId, required: true),
          _Field(label: 'Treatment Regimen', controller: _regimen, hint: 'e.g. Category 1'),
          _Field(label: 'Treatment Start Date (YYYY-MM-DD)', controller: _tbStart),
          _Field(label: 'DOTS Supporter Name', controller: _tbSupport),
        ]);

      case PatientType.malaria:
        return Column(children: [
          _SectionHeader('Malaria/Dengue Details'),
          const SizedBox(height: AppSpacing.sm),
          _DropdownField(
            label: 'Disease',
            value: _disease.text.isEmpty ? 'Malaria' : _disease.text,
            items: const ['Malaria', 'Dengue', 'Malaria+Dengue', 'Fever (Unknown)'],
            onChanged: (v) => setState(() => _disease.text = v!),
          ),
          _Field(label: 'Onset Date (YYYY-MM-DD)', controller: _onsetDate),
          _Field(label: 'RDT Result', controller: _rdtResult, hint: 'e.g. Positive (P.vivax)'),
          _Field(label: 'Treatment Prescribed', controller: _treatment),
        ]);

      case PatientType.familyPlanning:
        return Column(children: [
          _SectionHeader('Family Planning Details'),
          const SizedBox(height: AppSpacing.sm),
          _DropdownField(
            label: 'Contraceptive Method',
            value: _fpMethod,
            items: const ['OCP', 'Condom', 'IUCD', 'Injectable', 'Sterilization', 'Natural'],
            onChanged: (v) => setState(() => _fpMethod = v!),
          ),
          _Field(label: 'Start Date (YYYY-MM-DD)', controller: _fpStart),
        ]);

      case PatientType.newborn:
        return Column(children: [
          _SectionHeader('Newborn Details'),
          const SizedBox(height: AppSpacing.sm),
          _Field(label: 'Date of Birth (YYYY-MM-DD)', controller: _nbDob, required: true),
          _Field(label: "Mother's Name", controller: _motherName, required: true),
          _Field(label: 'Birth Weight (kg)', controller: _birthWeight, keyboardType: TextInputType.number),
          _DropdownField(
            label: 'Gender',
            value: _nbGender,
            items: const ['Female', 'Male'],
            onChanged: (v) => setState(() => _nbGender = v!),
          ),
        ]);

      case PatientType.general:
        return Column(children: [
          _SectionHeader('Visit Reason'),
          const SizedBox(height: AppSpacing.sm),
          _Field(label: 'Chief Complaint', controller: _chiefComplaint, required: true),
        ]);
    }
  }
}

// ── Helper widgets ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5),
      );
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool required;
  final String? hint;
  final TextInputType keyboardType;

  const _Field({
    required this.label,
    required this.controller,
    this.required = false,
    this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide.none),
        ),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final void Function(String?) onChanged;

  const _DropdownField({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
