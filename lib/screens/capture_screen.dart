import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import '../services/gemma_service.dart';
import '../theme/app_theme.dart';
import 'correction_screen.dart';

class CaptureScreen extends StatefulWidget {
  final Patient patient;
  final Visit visit;

  const CaptureScreen({super.key, required this.patient, required this.visit});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _picker = ImagePicker();
  File? _capturedImage;
  Uint8List? _imageBytes;
  bool _processing = false;
  String _statusText = '';

  Future<void> _captureImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1280,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _capturedImage = File(picked.path);
        _imageBytes = bytes;
        _statusText = '';
      });
    } catch (e) {
      _showError('Camera access failed. Check permissions.');
    }
  }

  Future<void> _processCard() async {
    if (_imageBytes == null) return;

    setState(() {
      _processing = true;
      _statusText = 'Loading Gemma model…';
    });

    try {
      setState(() => _statusText = 'Reading MCP card (Hindi + English)…');

      // Call on-device Gemma for OCR (multimodal)
      final fields = await GemmaService.extractMcpCard(_imageBytes!);

      if (mounted) _goToCorrection(fields);
    } catch (e) {
      if (mounted) {
        setState(() {
          _processing = false;
          _statusText = '';
        });
        _showError('Processing failed: ${e.toString().substring(0, 80)}');
      }
    }
  }

  void _goToCorrection(Map<String, String> fields) {
    setState(() => _processing = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CorrectionScreen(
          patient: widget.patient,
          visit: widget.visit,
          extractedFields: fields,
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture MCP Card'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 1 / 5,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4,
          ),
        ),
      ),
      body: Column(
        children: [
          // Patient info strip
          Container(
            color: AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.white70, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${widget.patient.name} • ${widget.patient.village}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.primaryLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.primary, size: 22),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Photo the MCP card clearly. Gemma reads Hindi + English on-device.',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: AppSpacing.lg),

                  // Image preview / placeholder
                  GestureDetector(
                    onTap: () => _captureImage(ImageSource.camera),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 240,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: _capturedImage != null
                              ? AppColors.primary
                              : AppColors.chipBorder,
                          width: _capturedImage != null ? 2 : 1,
                        ),
                      ),
                      child: _capturedImage != null
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                              child: Image.file(_capturedImage!,
                                  fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt_outlined,
                                    size: 56, color: AppColors.primary),
                                const SizedBox(height: AppSpacing.sm),
                                Text('Tap to open camera',
                                    style: TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(
                          begin: const Offset(0.95, 0.95),
                          end: const Offset(1, 1),
                          duration: 400.ms),

                  const SizedBox(height: AppSpacing.md),

                  if (_capturedImage != null)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _processing
                                ? null
                                : () => _captureImage(ImageSource.camera),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retake'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _processing
                                ? null
                                : () => _captureImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Gallery'),
                          ),
                        ),
                      ],
                    ),

                  if (_capturedImage == null) ...[
                    OutlinedButton.icon(
                      onPressed: () => _captureImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Choose from Gallery'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => _goToCorrection({}),
                      child: const Text('Skip — Enter manually'),
                    ),
                  ],

                  if (_statusText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_processing)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary),
                            ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(_statusText,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom action
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ElevatedButton.icon(
                onPressed:
                    (_capturedImage == null || _processing) ? null : _processCard,
                icon: _processing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.document_scanner_outlined),
                label: Text(_processing ? 'Reading Card…' : 'Process Card'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _capturedImage == null ? Colors.grey : AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
