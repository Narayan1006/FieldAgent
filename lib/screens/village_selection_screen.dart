import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';

class VillageSelectionScreen extends StatefulWidget {
  final Function(String village) onVillageSelected;

  const VillageSelectionScreen({super.key, required this.onVillageSelected});

  @override
  State<VillageSelectionScreen> createState() => _VillageSelectionScreenState();
}

class _VillageSelectionScreenState extends State<VillageSelectionScreen> {
  List<String> _villages = [];
  bool _loading = true;
  bool _syncing = false;
  String? _selected;
  String _syncStatus = '';

  @override
  void initState() {
    super.initState();
    // Show fallback villages immediately — no spinner wait
    _villages = ['Govindpur', 'Krishnanagar', 'Rampura', 'Sitapur'];
    _loading = false;
    // Then try to refresh from Firestore in background
    _refreshFromFirestore();
  }

  Future<void> _refreshFromFirestore() async {
    try {
      final villages = await SyncService.instance.fetchVillages();
      if (mounted && villages.isNotEmpty) {
        setState(() => _villages = villages);
      }
    } catch (_) {}
  }

  Future<void> _confirmVillage() async {
    if (_selected == null) return;

    setState(() {
      _syncing = true;
      _syncStatus = 'Downloading patient records…';
    });

    try {
      // Pull patients from Firestore → SQLite
      final patients = await SyncService.instance.pullPatientsForVillage(_selected!);

      setState(() =>
          _syncStatus = 'Downloaded ${patients.length} patients. Ready!');

      // Save selection
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_village', _selected!);

      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) widget.onVillageSelected(_selected!);
    } catch (e) {
      if (mounted) {
        setState(() {
          _syncing = false;
          _syncStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e. Working offline.')),
        );
        // Proceed anyway — offline mode
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selected_village', _selected!);
        widget.onVillageSelected(_selected!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // Icon + Title
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(Icons.location_on_outlined,
                          size: 40, color: AppColors.primary),
                    ).animate().scale(
                        begin: const Offset(0.7, 0.7),
                        end: const Offset(1, 1),
                        duration: 400.ms),
                    const SizedBox(height: AppSpacing.md),
                    Text('Select Your Village',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Choose the village you are assigned to.\nPatient records will be downloaded for offline use.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Village list
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _villages.length,
                        itemBuilder: (context, i) {
                          final v = _villages[i];
                          final isSelected = _selected == v;
                          return GestureDetector(
                            onTap: _syncing ? null : () => setState(() => _selected = v),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.divider,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 3)
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textHint,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Text(
                                    v,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isSelected)
                                    const Icon(Icons.check_circle,
                                        color: AppColors.primary, size: 20),
                                ],
                              ),
                            )
                                .animate(delay: Duration(milliseconds: i * 60))
                                .fadeIn(duration: 250.ms)
                                .slideX(begin: 0.05, end: 0, duration: 250.ms),
                          );
                        },
                      ),
              ),

              // Sync progress
              if (_syncStatus.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      if (_syncing)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(_syncStatus,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ),

              // Confirm button
              ElevatedButton.icon(
                onPressed:
                    (_selected == null || _syncing) ? null : _confirmVillage,
                icon: _syncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download_done_outlined),
                label: Text(_syncing ? 'Syncing…' : 'Confirm & Download Patients'),
              ),

              const SizedBox(height: AppSpacing.sm),

              Center(
                child: TextButton(
                  onPressed: _syncing ? null : () async {
                    // Skip — work fully offline with cached data
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('selected_village', '');
                    widget.onVillageSelected('');
                  },
                  child: const Text('Skip — Work Offline',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
