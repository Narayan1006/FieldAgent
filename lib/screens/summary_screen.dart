import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/patient.dart';
import '../models/patient_type.dart';
import '../models/visit.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../tools/draft_referral_note.dart';
import '../tools/log_visit_entry.dart';
import '../tools/flag_danger_signs.dart';
import '../widgets/danger_banner.dart';
import '../theme/app_theme.dart';

class SummaryScreen extends StatefulWidget {
  final Patient patient;
  final Visit visit;
  final String patientHistory;

  const SummaryScreen({
    super.key,
    required this.patient,
    required this.visit,
    this.patientHistory = '',
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _generating = true;
  bool _approving = false;
  bool _approved = false;
  String _statusText = 'Loading Gemma 4 E4B…';
  String _error = '';
  late TextEditingController _noteController;
  DangerSignResult? _dangerResult;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _computeDangerFlags();
    _generateNote();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _computeDangerFlags() {
    // Maternal: BP-based flags via existing tool
    if (widget.patient.patientType == PatientType.maternal) {
      final s = widget.visit.bpSystolic;
      final d = widget.visit.bpDiastolic;
      if (s != null && d != null) {
        setState(() => _dangerResult = flagDangerSigns(s, d));
      }
    } else {
      // Other types: danger flags already computed in TypedVisitScreen
      if (widget.visit.dangerFlags.isNotEmpty) {
        final dangerFlags = widget.visit.dangerFlags.map((msg) => DangerFlag(
          message: msg,
          level: (msg.contains('Emergency') || msg.contains('UNCONSCIOUS') || msg.contains('HIGH BP'))
              ? DangerLevel.critical
              : DangerLevel.warning,
          emoji: msg.contains('Emergency') || msg.contains('UNCONSCIOUS') ? '🔴' : '🟡',
        )).toList();
        final hasCritical = dangerFlags.any((f) => f.level == DangerLevel.critical);
        setState(() => _dangerResult = DangerSignResult(
          flags: dangerFlags,
          overallLevel: hasCritical ? DangerLevel.critical : DangerLevel.warning,
        ));
      }
    }
  }

  Future<void> _generateNote() async {
    setState(() {
      _generating = true;
      _error = '';
      _statusText = 'Drafting referral note…';
    });
    try {
      final note = await draftReferralNote(widget.visit.id);
      if (mounted) {
        setState(() {
          _noteController.text = note;
          _generating = false;
          _statusText = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generating = false;
          _error = e.toString();
          _noteController.text =
              'REFERRAL NOTE\n\nPatient: ${widget.patient.name}\nDate: ${widget.visit.visitDate}\n\nPlease write referral details here.';
        });
      }
    }
  }

  Future<void> _approve() async {
    setState(() => _approving = true);
    try {
      final note = _noteController.text.trim();

      // Save approved referral note to SQLite
      await logVisitEntry(visitId: widget.visit.id, field: 'referral_note', value: note);
      await logVisitEntry(visitId: widget.visit.id, field: 'approved', value: true);
      if (_dangerResult != null) {
        await logVisitEntry(visitId: widget.visit.id, field: 'danger_flags', value: _dangerResult!.flagMessages);
      }

      // Refresh visit object
      final savedVisit = await DatabaseService.instance.getVisit(widget.visit.id);
      final visit = savedVisit ?? widget.visit;

      // Sync to Firestore in background
      final syncResult = await SyncService.instance.pushVisit(visit, widget.patient);

      setState(() { _approved = true; _approving = false; });

      // Show sync feedback
      if (mounted) {
        final msg = syncResult == SyncResult.synced
            ? '✅ Visit saved & synced to cloud'
            : '🔄 Visit saved — will sync when online';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      setState(() => _approving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    }
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Summary'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _approved ? 1.0 : 4 / 5,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4,
          ),
        ),
      ),
      body: _approved ? _ApprovedView(onHome: _goHome) : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
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
                '${widget.patient.name} • ${widget.visit.visitDate}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              // Danger flags at top
              if (_dangerResult != null && _dangerResult!.hasFlags) ...[
                const SizedBox(height: AppSpacing.sm),
                DangerBanner(result: _dangerResult!)
                    .animate()
                    .fadeIn(duration: 300.ms),
              ],

              // Visit data summary
              _VisitDataCard(visit: widget.visit)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 100.ms),

              // Referral note
              Container(
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
                          const Icon(Icons.description_outlined,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          const Text(
                            'AI-Drafted Referral Note',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Needs Approval',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (_generating)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(
                                color: AppColors.primary),
                            const SizedBox(height: AppSpacing.md),
                            Text(_statusText,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          children: [
                            if (_error.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_outlined,
                                        size: 16, color: AppColors.danger),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Gemma inference failed — template note provided. Edit as needed.',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.danger),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            TextField(
                              controller: _noteController,
                              maxLines: null,
                              style: const TextStyle(
                                  fontSize: 14, height: 1.6),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Referral note…',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                const Icon(Icons.edit_outlined,
                                    size: 14, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text(
                                  'Edit the note above if needed before approving.',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textHint),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            OutlinedButton.icon(
                              onPressed: _generating ? null : _generateNote,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Re-generate'),
                              style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 40)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
            ],
          ),
        ),

        // Approve button
        if (!_generating)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ElevatedButton.icon(
                onPressed: _approving ? null : _approve,
                icon: _approving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label: Text(_approving ? 'Saving…' : '✅ Approve & Save Visit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VisitDataCard extends StatelessWidget {
  final Visit visit;
  const _VisitDataCard({required this.visit});

  @override
  Widget build(BuildContext context) {
    final bp = (visit.bpSystolic != null && visit.bpDiastolic != null)
        ? '${visit.bpSystolic}/${visit.bpDiastolic} mmHg'
        : 'Not recorded';
    final weight = visit.weight != null
        ? '${visit.weight!.toStringAsFixed(1)} kg'
        : 'Not recorded';
    final symptoms = visit.symptoms.isEmpty ? 'None' : visit.symptoms.join(', ');

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text('Visit Summary',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ],
          ),
          const Divider(height: 16),
          _DataRow(label: 'Blood Pressure', value: bp),
          _DataRow(label: 'Weight', value: weight),
          _DataRow(label: 'Symptoms', value: symptoms),
          if (visit.notes.isNotEmpty) _DataRow(label: 'Notes', value: visit.notes),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  const _DataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _ApprovedView extends StatelessWidget {
  final VoidCallback onHome;
  const _ApprovedView({required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 90, color: AppColors.success)
                .animate()
                .scale(begin: const Offset(0.3, 0.3), end: const Offset(1, 1),
                    curve: Curves.elasticOut, duration: 800.ms),
            const SizedBox(height: AppSpacing.lg),
            Text('Visit Saved!',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.success,
                    ))
                .animate()
                .fadeIn(delay: 400.ms, duration: 400.ms),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'The visit record and referral note have been saved locally.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: onHome,
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to Home'),
            ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
