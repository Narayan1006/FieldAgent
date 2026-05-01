import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/patient_type.dart';
import '../models/visit.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'summary_screen.dart';

/// Universal visit screen for all 7 patient types.
/// Shows type-specific form fields, computes danger flags,
/// then navigates to SummaryScreen for approval.
class TypedVisitScreen extends StatefulWidget {
  final Patient patient;
  final Visit visit;
  const TypedVisitScreen({super.key, required this.patient, required this.visit});

  @override
  State<TypedVisitScreen> createState() => _TypedVisitScreenState();
}

class _TypedVisitScreenState extends State<TypedVisitScreen> {
  late Visit _visit;
  final Map<String, TextEditingController> _ctrl = {};
  final Map<String, bool> _bools = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _visit = widget.visit;
    _initControllers();
  }

  void _initControllers() {
    switch (widget.patient.patientType) {
      case PatientType.maternal:
        _ctrl['systolic']  = TextEditingController(text: _visit.bpSystolic?.toString() ?? '');
        _ctrl['diastolic'] = TextEditingController(text: _visit.bpDiastolic?.toString() ?? '');
        _ctrl['weight']    = TextEditingController(text: _visit.weight?.toString() ?? '');
        _ctrl['notes']     = TextEditingController(text: _visit.notes);
        break;

      case PatientType.child:
        _ctrl['weight']  = TextEditingController(text: _visit.weight?.toString() ?? '');
        _ctrl['notes']   = TextEditingController(text: _visit.notes);
        final vd = _visit.visitData;
        for (final v in ['BCG','OPV0','OPV1','OPV2','DPT1','DPT2','DPT3','Measles','Vitamin_A']) {
          _bools[v] = vd[v] == true;
        }
        _bools['adverse_reaction'] = vd['adverse_reaction'] == true;
        _ctrl['reaction_detail'] = TextEditingController(text: vd['reaction_detail'] ?? '');
        break;

      case PatientType.tb:
        _ctrl['notes']    = TextEditingController(text: _visit.notes);
        _ctrl['weight']   = TextEditingController(text: _visit.weight?.toString() ?? '');
        _ctrl['cough_weeks'] = TextEditingController(text: _visit.visitData['cough_weeks']?.toString() ?? '');
        _bools['dose_taken']    = _visit.visitData['dose_taken'] != false;
        _bools['hemoptysis']    = _visit.visitData['hemoptysis'] == true;
        _bools['night_sweats']  = _visit.visitData['night_sweats'] == true;
        _bools['weight_loss']   = _visit.visitData['weight_loss'] == true;
        break;

      case PatientType.malaria:
        _ctrl['temperature']  = TextEditingController(text: _visit.temperature?.toString() ?? '');
        _ctrl['notes']        = TextEditingController(text: _visit.notes);
        _bools['vomiting']      = _visit.visitData['vomiting'] == true;
        _bools['unconscious']   = _visit.visitData['unconscious'] == true;
        _bools['convulsions']   = _visit.visitData['convulsions'] == true;
        _bools['treatment_taken'] = _visit.visitData['treatment_taken'] != false;
        _ctrl['day'] = TextEditingController(text: _visit.visitData['treatment_day']?.toString() ?? '1');
        break;

      case PatientType.familyPlanning:
        _ctrl['notes']    = TextEditingController(text: _visit.notes);
        _bools['using_method']    = _visit.visitData['using_method'] != false;
        _bools['side_effects']    = _visit.visitData['side_effects'] == true;
        _bools['wants_change']    = _visit.visitData['wants_change'] == true;
        _ctrl['side_detail'] = TextEditingController(text: _visit.visitData['side_detail'] ?? '');
        _ctrl['next_followup'] = TextEditingController(text: _visit.visitData['next_followup'] ?? '');
        break;

      case PatientType.newborn:
        _ctrl['weight']    = TextEditingController(text: _visit.weight?.toString() ?? '');
        _ctrl['notes']     = TextEditingController(text: _visit.notes);
        _bools['breastfeeding'] = _visit.visitData['breastfeeding'] != false;
        _bools['jaundice']      = _visit.visitData['jaundice'] == true;
        _bools['breathing_issue'] = _visit.visitData['breathing_issue'] == true;
        _bools['not_feeding']   = _visit.visitData['not_feeding'] == true;
        _bools['cord_ok']       = _visit.visitData['cord_ok'] != false;
        break;

      case PatientType.general:
        _ctrl['temperature'] = TextEditingController(text: _visit.temperature?.toString() ?? '');
        _ctrl['notes']       = TextEditingController(text: _visit.notes);
        _ctrl['symptoms']    = TextEditingController(text: _visit.symptoms.join(', '));
        _bools['high_fever']     = _visit.visitData['high_fever'] == true;
        _bools['difficulty_breathing'] = _visit.visitData['difficulty_breathing'] == true;
        _bools['chest_pain']    = _visit.visitData['chest_pain'] == true;
        _bools['altered_consciousness'] = _visit.visitData['altered_consciousness'] == true;
        break;
    }
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _computeDangerFlags() {
    final flags = <String>[];
    switch (widget.patient.patientType) {
      case PatientType.maternal:
        final sys = int.tryParse(_ctrl['systolic']?.text ?? '') ?? 0;
        final dia = int.tryParse(_ctrl['diastolic']?.text ?? '') ?? 0;
        if (sys >= 140 || dia >= 90) flags.add('HIGH BP — Risk of Pre-eclampsia');
        if (sys <= 80 && sys > 0)    flags.add('LOW BP — Shock risk');
        final w = double.tryParse(_ctrl['weight']?.text ?? '') ?? 0;
        if (w > 0 && w < 40)        flags.add('Critically low weight');
        break;

      case PatientType.child:
        if (_bools['adverse_reaction'] == true) flags.add('Adverse vaccine reaction reported');
        break;

      case PatientType.tb:
        if (_bools['dose_taken'] == false)  flags.add('MISSED DOTS DOSE — Follow up urgently');
        if (_bools['hemoptysis'] == true)   flags.add('Hemoptysis (blood in sputum) — Refer immediately');
        final cw = int.tryParse(_ctrl['cough_weeks']?.text ?? '') ?? 0;
        if (cw >= 3)                        flags.add('Persistent cough ≥3 weeks');
        if (_bools['weight_loss'] == true)  flags.add('Significant weight loss reported');
        break;

      case PatientType.malaria:
        final temp = double.tryParse(_ctrl['temperature']?.text ?? '') ?? 0;
        if (temp >= 39.5)                    flags.add('High fever ≥39.5°C — Danger zone');
        if (_bools['unconscious'] == true)   flags.add('UNCONSCIOUS — Emergency referral');
        if (_bools['convulsions'] == true)   flags.add('Convulsions — Emergency referral');
        if (_bools['vomiting'] == true)      flags.add('Persistent vomiting — Cannot take medicine');
        if (_bools['treatment_taken'] == false) flags.add('Treatment NOT taken — Non-compliance');
        break;

      case PatientType.familyPlanning:
        if (_bools['side_effects'] == true)  flags.add('Side effects reported — Review method');
        if (_bools['wants_change'] == true)  flags.add('Patient wants to change method');
        break;

      case PatientType.newborn:
        if (_bools['jaundice'] == true)      flags.add('Jaundice detected — Phototherapy needed');
        if (_bools['breathing_issue'] == true) flags.add('Breathing difficulty — Emergency referral');
        if (_bools['not_feeding'] == true)   flags.add('Not feeding — Urgent nutrition support');
        break;

      case PatientType.general:
        final temp = double.tryParse(_ctrl['temperature']?.text ?? '') ?? 0;
        if (temp >= 39.0)                    flags.add('High fever ≥39°C');
        if (_bools['difficulty_breathing'] == true) flags.add('Difficulty breathing — Refer');
        if (_bools['chest_pain'] == true)    flags.add('Chest pain — Cardiac risk');
        if (_bools['altered_consciousness'] == true) flags.add('Altered consciousness — Emergency');
        break;
    }
    return flags;
  }

  Future<void> _next() async {
    setState(() => _saving = true);
    try {
      final vd = <String, dynamic>{};
      switch (widget.patient.patientType) {
        case PatientType.maternal:
          _visit.bpSystolic  = int.tryParse(_ctrl['systolic']!.text);
          _visit.bpDiastolic = int.tryParse(_ctrl['diastolic']!.text);
          _visit.weight      = double.tryParse(_ctrl['weight']!.text);
          _visit.notes       = _ctrl['notes']!.text;
          break;
        case PatientType.child:
          _visit.weight = double.tryParse(_ctrl['weight']!.text);
          _visit.notes  = _ctrl['notes']!.text;
          for (final k in _bools.keys) vd[k] = _bools[k];
          vd['reaction_detail'] = _ctrl['reaction_detail']!.text;
          break;
        case PatientType.tb:
          _visit.weight = double.tryParse(_ctrl['weight']!.text);
          _visit.notes  = _ctrl['notes']!.text;
          vd['cough_weeks']  = int.tryParse(_ctrl['cough_weeks']!.text);
          for (final k in _bools.keys) vd[k] = _bools[k];
          break;
        case PatientType.malaria:
          _visit.temperature = double.tryParse(_ctrl['temperature']!.text);
          _visit.notes       = _ctrl['notes']!.text;
          vd['treatment_day'] = int.tryParse(_ctrl['day']!.text) ?? 1;
          for (final k in _bools.keys) vd[k] = _bools[k];
          break;
        case PatientType.familyPlanning:
          _visit.notes = _ctrl['notes']!.text;
          vd['next_followup'] = _ctrl['next_followup']!.text;
          vd['side_detail']   = _ctrl['side_detail']!.text;
          for (final k in _bools.keys) vd[k] = _bools[k];
          break;
        case PatientType.newborn:
          _visit.weight = double.tryParse(_ctrl['weight']!.text);
          _visit.notes  = _ctrl['notes']!.text;
          for (final k in _bools.keys) vd[k] = _bools[k];
          break;
        case PatientType.general:
          _visit.temperature = double.tryParse(_ctrl['temperature']!.text);
          _visit.notes       = _ctrl['notes']!.text;
          _visit.symptoms    = _ctrl['symptoms']!.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          for (final k in _bools.keys) vd[k] = _bools[k];
          break;
      }
      _visit.visitData   = vd;
      _visit.dangerFlags = _computeDangerFlags();
      await DatabaseService.instance.updateVisit(_visit);

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => SummaryScreen(patient: widget.patient, visit: _visit),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.patient.patientType;
    final color = Color(type.colorValue);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${type.emoji} ${type.shortLabel} Visit'),
        backgroundColor: color.withValues(alpha: 0.9),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Patient info card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Text(type.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.patient.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                Text('${widget.patient.age}y • ${widget.patient.village}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ]),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Type-specific fields
          ..._buildFields(color),

          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Review & Approve →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  List<Widget> _buildFields(Color color) {
    switch (widget.patient.patientType) {
      case PatientType.maternal:
        return [
          _cardSection('Vital Signs', color, [
            _numField('Systolic BP (mmHg)', _ctrl['systolic']!),
            _numField('Diastolic BP (mmHg)', _ctrl['diastolic']!),
            _numField('Weight (kg)', _ctrl['weight']!),
          ]),
          _cardSection('Notes', color, [_notesField(_ctrl['notes']!)]),
        ];

      case PatientType.child:
        return [
          _cardSection('Weight', color, [_numField('Current Weight (kg)', _ctrl['weight']!)]),
          _cardSection('Vaccines Given Today', color,
            ['BCG','OPV0','OPV1','OPV2','DPT1','DPT2','DPT3','Measles','Vitamin_A']
              .map((v) => _boolTile(v.replaceAll('_', ' '), v, color)).toList()
          ),
          _cardSection('Adverse Reaction', color, [
            _boolTile('Adverse Reaction Noted', 'adverse_reaction', color),
            if (_bools['adverse_reaction'] == true)
              _textField('Reaction Details', _ctrl['reaction_detail']!),
          ]),
          _cardSection('Notes', color, [_notesField(_ctrl['notes']!)]),
        ];

      case PatientType.tb:
        return [
          _cardSection('DOTS Check', color, [
            _boolTile('Dose Taken Today', 'dose_taken', color),
            _numField('Cough Duration (weeks)', _ctrl['cough_weeks']!),
            _numField('Weight (kg)', _ctrl['weight']!),
          ]),
          _cardSection('Danger Signs', color, [
            _boolTile('Hemoptysis (blood in cough)', 'hemoptysis', color),
            _boolTile('Night Sweats', 'night_sweats', color),
            _boolTile('Significant Weight Loss', 'weight_loss', color),
          ]),
          _cardSection('Notes', color, [_notesField(_ctrl['notes']!)]),
        ];

      case PatientType.malaria:
        return [
          _cardSection('Vitals', color, [_numField('Temperature (°C)', _ctrl['temperature']!)]),
          _cardSection('Treatment', color, [
            _boolTile('Treatment Taken Today', 'treatment_taken', color),
            _numField('Treatment Day #', _ctrl['day']!),
          ]),
          _cardSection('Danger Signs', color, [
            _boolTile('Vomiting', 'vomiting', color),
            _boolTile('Unconscious/Semi-conscious', 'unconscious', color),
            _boolTile('Convulsions', 'convulsions', color),
          ]),
          _cardSection('Notes', color, [_notesField(_ctrl['notes']!)]),
        ];

      case PatientType.familyPlanning:
        return [
          _cardSection('Compliance', color, [
            _boolTile('Currently Using Method', 'using_method', color),
            _boolTile('Side Effects Reported', 'side_effects', color),
            if (_bools['side_effects'] == true)
              _textField('Side Effect Details', _ctrl['side_detail']!),
            _boolTile('Wants to Change Method', 'wants_change', color),
          ]),
          _cardSection('Follow-up', color, [
            _textField('Next Follow-up Date (YYYY-MM-DD)', _ctrl['next_followup']!),
          ]),
          _cardSection('Notes', color, [_notesField(_ctrl['notes']!)]),
        ];

      case PatientType.newborn:
        return [
          _cardSection('Growth', color, [_numField('Current Weight (kg)', _ctrl['weight']!)]),
          _cardSection('Feeding', color, [_boolTile('Breastfeeding', 'breastfeeding', color)]),
          _cardSection('Danger Signs', color, [
            _boolTile('Jaundice (yellow skin/eyes)', 'jaundice', color),
            _boolTile('Breathing Difficulty', 'breathing_issue', color),
            _boolTile('Not Feeding Well', 'not_feeding', color),
            _boolTile('Cord Healthy', 'cord_ok', color),
          ]),
          _cardSection('Notes', color, [_notesField(_ctrl['notes']!)]),
        ];

      case PatientType.general:
        return [
          _cardSection('Vitals', color, [_numField('Temperature (°C)', _ctrl['temperature']!)]),
          _cardSection('Symptoms', color, [_textField('Symptoms (comma-separated)', _ctrl['symptoms']!)]),
          _cardSection('Danger Signs', color, [
            _boolTile('High Fever', 'high_fever', color),
            _boolTile('Difficulty Breathing', 'difficulty_breathing', color),
            _boolTile('Chest Pain', 'chest_pain', color),
            _boolTile('Altered Consciousness', 'altered_consciousness', color),
          ]),
          _cardSection('Notes', color, [_notesField(_ctrl['notes']!)]),
        ];
    }
  }

  Widget _cardSection(String title, Color color, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
      const Divider(height: 16),
      ...children,
    ]),
  );

  Widget _numField(String label, TextEditingController ctrl) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, filled: true, fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide.none)),
    ),
  );

  Widget _textField(String label, TextEditingController ctrl) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, filled: true, fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide.none)),
    ),
  );

  Widget _notesField(TextEditingController ctrl) => TextFormField(
    controller: ctrl,
    maxLines: 3,
    decoration: InputDecoration(labelText: 'ASHA Notes', filled: true, fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide.none)),
  );

  Widget _boolTile(String label, String key, Color color) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    title: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
    value: _bools[key] ?? false,
    activeThumbColor: color,
    onChanged: (v) => setState(() => _bools[key] = v),
  );
}
