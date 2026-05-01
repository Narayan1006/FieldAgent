import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/gemma_service.dart';
import '../theme/app_theme.dart';

/// Shown on first launch when the Gemma model hasn't been downloaded yet.
/// Downloads ~2GB model once over WiFi, then runs offline forever.
class ModelDownloadScreen extends StatefulWidget {
  final VoidCallback onModelReady;

  const ModelDownloadScreen({super.key, required this.onModelReady});

  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen> {
  bool _downloading = false;
  bool _error = false;
  double _progress = 0.0;
  String _statusText = '';
  String _errorMessage = '';

  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _error = false;
      _errorMessage = '';
      _statusText = 'Connecting…';
    });

    try {
      await GemmaService.installModel(
        onProgress: (progress, status) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _statusText = status;
            });
          }
        },
      );
      if (mounted) widget.onModelReady();
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = true;
          _errorMessage = e.toString();
        });
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
            children: [
              const Spacer(),

              // Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(45),
                ),
                child: const Icon(Icons.psychology_outlined,
                    size: 48, color: AppColors.primary),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1)),

              const SizedBox(height: AppSpacing.lg),

              Text(
                'AI Model Required',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: AppSpacing.sm),

              Text(
                'FieldAgent uses Gemma 4 E4B for on-device MCP card reading '
                'and referral note generation — fully on your device, no server needed.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: AppSpacing.xl),

              // Info cards
              _InfoCard(
                icon: Icons.wifi_outlined,
                title: 'Download Once',
                subtitle: '~500 MB over WiFi. Takes 2–5 minutes.',
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: AppSpacing.sm),
              _InfoCard(
                icon: Icons.lock_outline,
                title: 'Runs Offline Forever',
                subtitle:
                    'After download, works with no internet. All data stays on device.',
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: AppSpacing.sm),
              _InfoCard(
                icon: Icons.memory_outlined,
                title: 'Needs 1 GB+ Free Storage',
                subtitle: 'Ensure enough space before starting.',
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: AppSpacing.xl),

              // Progress
              if (_downloading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    backgroundColor: AppColors.divider,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _statusText,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],

              // Error
              if (_error) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error_outline, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text('Download Failed',
                              style: TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _errorMessage.length > 120
                            ? '${_errorMessage.substring(0, 120)}…'
                            : _errorMessage,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.danger),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: AppSpacing.sm),
              ],

              const Spacer(),

              // Action button
              if (!_downloading)
                ElevatedButton.icon(
                  onPressed: _startDownload,
                  icon: const Icon(Icons.download_outlined),
                  label: Text(
                      _error ? 'Retry Download' : 'Download AI Model (2 GB)'),
                ).animate().fadeIn(delay: 700.ms),

              if (_downloading && !_error)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      ),
                      SizedBox(width: 8),
                      Text('Downloading — keep app open',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Connect to WiFi for faster download.\nMobile data will work but may be slow.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textHint),
              ),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
