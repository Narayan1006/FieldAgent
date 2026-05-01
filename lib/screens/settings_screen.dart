import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemma_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'village_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _checking = true;
  bool _modelInstalled = false;

  @override
  void initState() {
    super.initState();
    _checkModel();
  }

  Future<void> _checkModel() async {
    setState(() => _checking = true);
    final installed = await GemmaService.isModelInstalled();
    if (mounted) {
      setState(() {
        _modelInstalled = installed;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // AI Model Status
                _SettingsSection(
                  title: 'AI Model (On-Device)',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (_modelInstalled
                                      ? AppColors.success
                                      : AppColors.warning)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _modelInstalled
                                  ? Icons.check_circle_outline
                                  : Icons.download_outlined,
                              color: _modelInstalled
                                  ? AppColors.success
                                  : AppColors.warning,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _modelInstalled
                                      ? 'Model Ready'
                                      : 'Model Not Downloaded',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _modelInstalled
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                                Text(
                                  'Gemma 3n E2B • On-device • Offline',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Divider(),
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(label: 'Model', value: 'Gemma 3n E2B (Multimodal)'),
                      _InfoRow(label: 'Size', value: '~2 GB'),
                      _InfoRow(label: 'Vision', value: 'MCP card OCR (Hindi + English)'),
                      _InfoRow(label: 'Inference', value: '100% on-device, no server'),
                      _InfoRow(label: 'Source', value: 'HuggingFace (one-time download)'),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: AppSpacing.md),

                // About section
                _SettingsSection(
                  title: 'About',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _InfoRow(label: 'App', value: 'FieldAgent v1.0.0'),
                      _InfoRow(label: 'Storage', value: 'SQLite (offline-first)'),
                      _InfoRow(label: 'Target', value: 'ASHA Workers, India'),
                      _InfoRow(label: 'Internet', value: 'Only for model download'),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

                const SizedBox(height: AppSpacing.md),

                // Village
                _SettingsSection(
                  title: 'Village Assignment',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _InfoRow(label: 'Status', value: 'Village saved on device'),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.location_on_outlined, size: 18),
                          label: const Text('Change Village'),
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('selected_village');
                            if (!context.mounted) return;
                            // Push VillageSelectionScreen directly, replacing everything
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => VillageSelectionScreen(
                                  onVillageSelected: (v) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (_) => HomeScreen(village: v),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                ),
                              ),
                              (route) => false,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: 150.ms),

                const SizedBox(height: AppSpacing.md),


                // Privacy
                _SettingsSection(
                  title: 'Privacy & Data',
                  child: Column(
                    children: [
                      _PrivacyPoint(
                        icon: Icons.smartphone_outlined,
                        text:
                            'All patient data stored locally on this device only.',
                      ),
                      _PrivacyPoint(
                        icon: Icons.psychology_outlined,
                        text:
                            'AI runs on-device — no data sent to any cloud server.',
                      ),
                      _PrivacyPoint(
                        icon: Icons.wifi_off_outlined,
                        text:
                            'App works fully offline after model download.',
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
              ],
            ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _SettingsSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.5)),
          const Divider(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

class _PrivacyPoint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PrivacyPoint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
