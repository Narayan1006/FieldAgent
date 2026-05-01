import 'dart:typed_data';
import 'package:flutter_gemma/flutter_gemma.dart';

/// GemmaService — wraps flutter_gemma 0.14.1 for on-device inference.
/// Replaces OllamaService entirely. No HTTP, no server, no network for inference.
///
/// Model: Gemma3n E2B (~2GB, multimodal vision + text)
/// Runs 100% on-device after one-time download.
class GemmaService {
  // Gemma 4 E4B from litert-community — Apache 2.0, NO token needed
  // 3.65 GB total (text decoder 2.24 GB + embeddings 0.67 GB + vision loaded on demand)
  // Multimodal: vision + audio supported. ModelType.gemma4 required.
  static const String modelUrl =
      'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm';

  // Model filename — used as ID for isModelInstalled()
  static const String _modelId = 'gemma-4-E4B-it.litertlm';

  // ── MODEL STATUS ───────────────────────────────────────────────

  /// Check if model has been downloaded and installed on device
  static Future<bool> isModelInstalled() async {
    try {
      return await FlutterGemma.isModelInstalled(_modelId);
    } catch (_) {
      return false;
    }
  }

  // ── MODEL DOWNLOAD ─────────────────────────────────────────────

  /// Download and install model (runs once over WiFi, then offline forever).
  /// No token required — litert-community/gemma-4-E4B-it-litert-lm is Apache 2.0.
  static Future<void> installModel({
    required Function(double progress, String status) onProgress,
  }) async {
    onProgress(0.0, 'Connecting…');

    await FlutterGemma.installModel(
      modelType: ModelType.gemma4,
      fileType: ModelFileType.task, // .litertlm uses same path as .task
    ).fromNetwork(
      modelUrl,
      // No token — public Apache 2.0 model
    ).withProgress((int pct) {
      onProgress(pct / 100.0, 'Downloading Gemma 4 E4B… $pct%');
    }).install();

    onProgress(1.0, 'Gemma 4 E4B ready!');
  }

  // ── TEXT GENERATION ────────────────────────────────────────────

  /// Generate text response from a text-only prompt.
  static Future<String> generateText({
    required String systemInstruction,
    required String userPrompt,
    int maxTokens = 512,
  }) async {
    InferenceModel? model;
    try {
      model = await FlutterGemma.getActiveModel(
        maxTokens: maxTokens,
        preferredBackend: PreferredBackend.gpu,
      );

      final chat = await model.createChat(
        systemInstruction: systemInstruction,
      );

      await chat.addQueryChunk(
        Message.text(text: userPrompt, isUser: true),
      );

      return await _extractText(chat);
    } finally {
      await model?.close();
    }
  }

  // ── MULTIMODAL (IMAGE + TEXT) ──────────────────────────────────

  /// Generate text response from image + text (for MCP card OCR).
  static Future<String> generateFromImage({
    required String systemInstruction,
    required String userPrompt,
    required Uint8List imageBytes,
    int maxTokens = 300,
  }) async {
    InferenceModel? model;
    try {
      // supportImage: true required for vision modality
      model = await FlutterGemma.getActiveModel(
        maxTokens: maxTokens,
        preferredBackend: PreferredBackend.gpu,
        supportImage: true,
      );

      final chat = await model.createChat(
        systemInstruction: systemInstruction,
        supportImage: true,
      );

      await chat.addQueryChunk(
        Message.withImage(
          text: userPrompt,
          imageBytes: imageBytes,
          isUser: true,
        ),
      );

      return await _extractText(chat);
    } finally {
      await model?.close();
    }
  }

  /// Extract text from ModelResponse (sealed class: TextResponse | FunctionCallResponse | ThinkingResponse)
  static Future<String> _extractText(InferenceChat chat) async {
    final response = await chat.generateChatResponse();
    if (response is TextResponse) return response.token.trim();
    return '';
  }

  // ── MCP CARD OCR ───────────────────────────────────────────────

  static Future<Map<String, String>> extractMcpCard(Uint8List imageBytes) async {
    const systemInstruction =
        'You are an OCR assistant for Indian Maternal and Child Protection (MCP) cards. '
        'Extract structured data from card images. '
        'The card may have text in Hindi (Devanagari) and/or English. '
        'Return only valid JSON with no extra text.';

    const prompt =
        'Extract the following fields from this MCP card image.\n'
        'Return ONLY a valid JSON object with exactly these keys:\n'
        '{\n'
        '  "name": "patient full name",\n'
        '  "age": "age as number only",\n'
        '  "anc_number": "ANC registration number",\n'
        '  "lmp_date": "last menstrual period date in YYYY-MM-DD format",\n'
        '  "edd": "estimated due date in YYYY-MM-DD format",\n'
        '  "village": "village or locality name"\n'
        '}\n'
        'If a field is not visible, use empty string. '
        'Transliterate Hindi names to English. '
        'Output ONLY the JSON object.';

    try {
      final raw = await generateFromImage(
        systemInstruction: systemInstruction,
        userPrompt: prompt,
        imageBytes: imageBytes,
        maxTokens: 200,
      );
      return _parseJsonFields(raw);
    } catch (_) {
      return _emptyMcpFields();
    }
  }

  // ── REFERRAL NOTE ──────────────────────────────────────────────

  static Future<String> generateReferralNote({
    required String patientName,
    required int? bpSystolic,
    required int? bpDiastolic,
    required double? weight,
    required List<String> symptoms,
    required String notes,
    required List<String> dangerFlags,
    required String visitDate,
    required String patientHistory,
  }) async {
    final bpStr = (bpSystolic != null && bpDiastolic != null)
        ? '$bpSystolic/$bpDiastolic mmHg'
        : 'not recorded';
    final weightStr = weight != null
        ? '${weight.toStringAsFixed(1)} kg'
        : 'not recorded';
    final symptomsStr = symptoms.isEmpty ? 'none reported' : symptoms.join(', ');
    final flagsStr = dangerFlags.isEmpty ? 'none' : dangerFlags.join('; ');

    const systemInstruction =
        'You are a medical assistant helping an ASHA worker in India write '
        'a concise referral note for a pregnant patient. '
        'Write in plain English. Be clear and professional.';

    final prompt = '''Write a referral note for the following patient:
Name: $patientName
Visit Date: $visitDate
Blood Pressure: $bpStr
Weight: $weightStr
Symptoms: $symptomsStr
Danger Signs: $flagsStr
Notes: $notes
History: $patientHistory

Requirements:
- Start with "REFERRAL NOTE" heading
- 100-150 words maximum
- Mention danger signs clearly if present
- Recommend action (monitor / refer to PHC)
- Plain language, no complex jargon
Output only the referral note text.''';

    return await generateText(
      systemInstruction: systemInstruction,
      userPrompt: prompt,
      maxTokens: 300,
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────

  static Map<String, String> _emptyMcpFields() => {
        'name': '',
        'age': '',
        'anc_number': '',
        'lmp_date': '',
        'edd': '',
        'village': '',
      };

  static Map<String, String> _parseJsonFields(String raw) {
    try {
      final result = <String, String>{};
      final keys = ['name', 'age', 'anc_number', 'lmp_date', 'edd', 'village'];
      for (final key in keys) {
        final match = RegExp('"$key"\\s*:\\s*"([^"]*)"').firstMatch(raw);
        result[key] = match?.group(1) ?? '';
      }
      return result;
    } catch (_) {
      return _emptyMcpFields();
    }
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
