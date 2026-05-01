import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient.dart';
import '../models/patient_type.dart';
import '../models/visit.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../widgets/patient_card.dart';
import '../theme/app_theme.dart';
import 'add_patient_screen.dart';
import 'capture_screen.dart';
import 'settings_screen.dart';
import 'typed_visit_screen.dart';
import 'village_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  final String village;
  const HomeScreen({super.key, required this.village});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Patient> _patients = [];
  List<Patient> _filtered = [];
  Map<String, Visit?> _lastVisits = {};
  bool _loading = true;
  bool _syncing = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  PatientType? _typeFilter; // null = All

  @override
  void initState() {
    super.initState();
    _loadPatients();
    SyncService.instance.syncEvents.listen(_onSyncEvent);
    SyncService.instance.pushPendingQueue();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSyncEvent(SyncEvent event) {
    if (!mounted) return;
    if (event.type == SyncEventType.visitSynced ||
        event.type == SyncEventType.queueFlushed ||
        event.type == SyncEventType.patientsPulled) {
      _loadPatients();
    }
  }

  Future<void> _loadPatients() async {
    // Check if village was cleared in Settings
    final prefs = await SharedPreferences.getInstance();
    final savedVillage = prefs.getString('selected_village');
    if ((savedVillage == null || savedVillage.isEmpty) && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VillageSelectionScreen(
            onVillageSelected: (v) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => HomeScreen(village: v)),
              );
            },
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      List<Patient> patients;
      if (_searchQuery.isNotEmpty) {
        patients = await DatabaseService.instance.searchPatients(_searchQuery, village: widget.village.isEmpty ? null : widget.village);
      } else if (widget.village.isNotEmpty) {
        patients = await DatabaseService.instance.getPatientsByVillage(widget.village);
        if (patients.isEmpty) patients = await DatabaseService.instance.getAllPatients();
      } else {
        patients = await DatabaseService.instance.getAllPatients();
      }
      final lastVisits = <String, Visit?>{};
      for (final p in patients) {
        lastVisits[p.id] = await DatabaseService.instance.getLatestVisit(p.id);
      }
      final filtered = _typeFilter == null
          ? patients
          : patients.where((p) => p.patientType == _typeFilter).toList();
      if (mounted) setState(() { _patients = patients; _filtered = filtered; _lastVisits = lastVisits; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pullFromFirestore() async {
    if (widget.village.isEmpty) { await _loadPatients(); return; }
    setState(() => _syncing = true);
    await SyncService.instance.pullPatientsForVillage(widget.village);
    await _loadPatients();
    if (mounted) setState(() => _syncing = false);
  }

  void _onSearch(String q) { _searchQuery = q; _loadPatients(); }

  Future<void> _openAddPatient() async {
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => AddPatientScreen(village: widget.village),
    ));
    if (result != null) _loadPatients();
  }

  void _startVisit(Patient patient) async {
    final visit = await DatabaseService.instance.createVisit(patient.id, type: patient.patientType);
    if (!mounted) return;
    // Maternal → existing OCR capture flow; all others → TypedVisitScreen
    if (patient.patientType == PatientType.maternal) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CaptureScreen(patient: patient, visit: visit),
      )).then((_) => _loadPatients());
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => TypedVisitScreen(patient: patient, visit: visit),
      )).then((_) => _loadPatients());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = SyncService.instance.isOnline;
    final pendingCount = _patients.where((p) => p.syncStatus == 'pending').length;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.medical_services_outlined, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text('FieldAgent'),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: isOnline ? AppColors.success : AppColors.textHint, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(isOnline ? 'Online' : 'Offline', style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ]),
          ),
          if (widget.village.isNotEmpty)
            IconButton(
              icon: _syncing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.sync_outlined),
              tooltip: 'Sync from Firestore',
              onPressed: _syncing ? null : _pullFromFirestore,
            ),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
      body: Column(children: [
        // ── Stats bar ────────────────────────────────────────
        Container(
          color: AppColors.primaryDark,
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
          child: Row(children: [
            _StatChip(icon: Icons.group_outlined, label: '${_filtered.length}/${_patients.length}'),
            const SizedBox(width: AppSpacing.sm),
            if (widget.village.isNotEmpty) _StatChip(icon: Icons.location_on_outlined, label: widget.village),
            if (pendingCount > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              _StatChip(icon: Icons.sync_outlined, label: '$pendingCount pending', color: AppColors.warning),
            ],
          ]),
        ),
        // ── Category filter chips ─────────────────────────────
        Container(
          color: AppColors.primaryDark,
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            children: [
              _FilterChip(label: 'All', selected: _typeFilter == null,
                onTap: () { setState(() => _typeFilter = null); _loadPatients(); }),
              ...PatientType.values.map((t) => _FilterChip(
                label: '${t.emoji} ${t.shortLabel}',
                selected: _typeFilter == t,
                color: Color(t.colorValue),
                onTap: () { setState(() => _typeFilter = t); _loadPatients(); },
              )),
            ],
          ),
        ),
        // ── Search ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
          child: TextField(
            controller: _searchController, onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Search patients…',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); _onSearch(''); }) : null,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // ── Patient list ──────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _filtered.isEmpty
                  ? _EmptyState(onAdd: _openAddPatient)
                  : RefreshIndicator(
                      onRefresh: _pullFromFirestore,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) => PatientCard(
                          patient: _filtered[i],
                          lastVisit: _lastVisits[_filtered[i].id],
                          onStartVisit: () => _startVisit(_filtered[i]),
                          index: i,
                        ),
                      ),
                    ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPatient,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Patient'),
      ).animate().slideY(begin: 1, end: 0, duration: 400.ms, delay: 300.ms),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon; final String label; final Color? color;
  const _StatChip({required this.icon, required this.label, this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: (color ?? Colors.white).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color ?? Colors.white70),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: color ?? Colors.white70)),
    ]),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : Colors.transparent, width: 1.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.normal, color: selected ? (color == null ? AppColors.primaryDark : Colors.white) : Colors.white70)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.group_outlined, size: 72, color: AppColors.textHint),
        const SizedBox(height: AppSpacing.md),
        Text('No patients found', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        Text('Pull-to-refresh to sync from Firestore or add a new patient.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textHint)),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.person_add_outlined), label: const Text('Add Patient')),
      ]),
    ),
  );
}
