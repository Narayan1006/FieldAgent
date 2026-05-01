import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import '../services/speech_service.dart';
import '../tools/flag_danger_signs.dart';
import '../tools/log_visit_entry.dart';
import '../tools/get_patient_history.dart';
import '../widgets/danger_banner.dart';
import '../widgets/symptom_chip_selector.dart';
import '../widgets/bp_number_input.dart';
import '../theme/app_theme.dart';
import 'summary_screen.dart';

class VisitScreen extends StatefulWidget {
  final Patient patient;
  final Visit visit;

  const VisitScreen({super.key, required this.patient, required this.visit});

  @override
  State<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends State<VisitScreen> {
  late Visit _visit;
  DangerSignResult? _dangerResult;
  final _speechService = SpeechService();
  bool _isListening = false;
  String _patientHistory = '';
  bool _saving = false;

  final _notesController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _visit = widget.visit;
    _notesController.text = _visit.notes;
    _weightController.text = _visit.weight?.toString() ?? '';
    _loadHistory();
    _speechService.initialize();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _weightController.dispose();
    _speechService.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final h = await getPatientHistory(widget.patient.id);
    if (mounted) setState(() => _patientHistory = h);
  }

  void _onBpChanged(int? systolic, int? diastolic) {
    setState(() {
      _visit.bpSystolic = systolic;
      _visit.bpDiastolic = diastolic;
    });

    // Auto-save
    if (systolic != null) {
      logVisitEntry(visitId: _visit.id, field: 'bp_systolic', value: systolic);
    }
    if (diastolic != null) {
      logVisitEntry(visitId: _visit.id, field: 'bp_diastolic', value: diastolic);
    }

    // Real-time danger check
    final s = _visit.bpSystolic;
    final d = _visit.bpDiastolic;
    if (s != null && d != null) {
      final result = flagDangerSigns(s, d);
      setState(() => _dangerResult = result);

      // Haptic on critical
      if (result.isCritical) {
        HapticFeedback.heavyImpact();
      }

      // Save flags
      logVisitEntry(
        visitId: _visit.id,
        field: 'danger_flags',
        value: result.flagMessages,
      );
    }
  }

  Future<void> _toggleMic() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
      // Save notes
      await logVisitEntry(
          visitId: _visit.id, field: 'notes', value: _notesController.text);
    } else {
      final ok = await _speechService.initialize();
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone not available')));
        return;
      }
      setState(() => _isListening = true);
      await _speechService.startListening(
        onResult: (text) {
          setState(() {
            final current = _notesController.text;
            _notesController.text =
                current.isEmpty ? text : '$current $text';
          });
        },
        localeId: 'hi_IN',
      );
    }
  }

  Future<void> _proceedToSummary() async {
    setState(() => _saving = true);
    try {
      // Save all fields
      await logVisitEntry(
          visitId: _visit.id, field: 'notes', value: _notesController.text);
      final weight = double.tryParse(_weightController.text);
      if (weight != null) {
        await logVisitEntry(
            visitId: _visit.id, field: 'weight', value: weight);
        _visit.weight = weight;
      }
      await logVisitEntry(
          visitId: _visit.id,
          field: 'symptoms',
          value: _visit.symptoms);

      _visit.notes = _notesController.text;

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SummaryScreen(
            patient: widget.patient,
            visit: _visit,
            patientHistory: _patientHistory,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Details'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 3 / 5,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4,
          ),
        ),
      ),
      body: Column(
        children: [
          // Patient strip
          Container(
            color: AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.white70, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${widget.patient.name} • ${_visit.visitDate}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                // ── BP SECTION ──────────────────────────────────
                _SectionCard(
                  title: 'Blood Pressure',
                  icon: Icons.favorite_outline,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: BpNumberInput(
                              label: 'SYSTOLIC',
                              value: _visit.bpSystolic,
                              accentColor: AppColors.danger,
                              onChanged: (v) =>
                                  _onBpChanged(v, _visit.bpDiastolic),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm),
                            child: Text('/',
                                style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w300,
                                    color: AppColors.textHint)),
                          ),
                          Expanded(
                            child: BpNumberInput(
                              label: 'DIASTOLIC',
                              value: _visit.bpDiastolic,
                              accentColor: AppColors.primaryDark,
                              onChanged: (v) =>
                                  _onBpChanged(_visit.bpSystolic, v),
                            ),
                          ),
                        ],
                      ),
                      if (_dangerResult != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: DangerBanner(result: _dangerResult!),
                        ),
                      if (_dangerResult == null ||
                          !_dangerResult!.hasFlags)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 16, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text('BP looks normal',
                                  style: TextStyle(
                                      fontSize: 13, color: AppColors.success)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: 0.ms),

                // ── WEIGHT SECTION ──────────────────────────────
                _SectionCard(
                  title: 'Weight',
                  icon: Icons.monitor_weight_outlined,
                  child: TextFormField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,1}')),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'e.g. 62.5',
                      suffixText: 'kg',
                      suffixStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                    onChanged: (v) {
                      final w = double.tryParse(v);
                      if (w != null) {
                        logVisitEntry(
                            visitId: _visit.id, field: 'weight', value: w);
                      }
                    },
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: 80.ms),

                // ── SYMPTOMS SECTION ───────────────────────────
                _SectionCard(
                  title: 'Symptoms',
                  icon: Icons.sick_outlined,
                  child: SymptomChipSelector(
                    selected: _visit.symptoms,
                    onChanged: (s) {
                      setState(() => _visit.symptoms = s);
                      logVisitEntry(
                          visitId: _visit.id, field: 'symptoms', value: s);
                    },
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: 160.ms),

                // ── NOTES SECTION ─────────────────────────────
                _SectionCard(
                  title: 'Notes',
                  icon: Icons.notes_outlined,
                  child: Column(
                    children: [
                      TextField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Enter observations, patient complaints…',
                          suffixIcon: _isListening
                              ? Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.danger,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.stop,
                                        color: Colors.white, size: 18),
                                  ),
                                )
                              : null,
                        ),
                        onChanged: (v) {
                          _visit.notes = v;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      GestureDetector(
                        onTap: _toggleMic,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: 10),
                          decoration: BoxDecoration(
                            color: _isListening
                                ? AppColors.danger
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: _isListening
                                  ? AppColors.danger
                                  : AppColors.chipBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isListening ? Icons.stop : Icons.mic_outlined,
                                color: _isListening
                                    ? Colors.white
                                    : AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isListening
                                    ? 'Stop Recording'
                                    : '🎤 Voice Input (Hindi / English)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _isListening
                                      ? Colors.white
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: 240.ms),

                // ── HISTORY SNAPSHOT ──────────────────────────
                if (_patientHistory.isNotEmpty &&
                    _patientHistory != 'No previous visits recorded for this patient.')
                  _SectionCard(
                    title: 'Previous Visit Summary',
                    icon: Icons.history_outlined,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _patientHistory,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 320.ms),
              ],
            ),
          ),

          // Bottom CTA
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _proceedToSummary,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.summarize_outlined),
                label: Text(_saving ? 'Saving…' : 'Generate Summary'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ],
      ),
    );
  }
}
