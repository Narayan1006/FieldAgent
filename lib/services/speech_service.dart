import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize();
    return _initialized;
  }

  bool get isListening => _speech.isListening;
  bool get isAvailable => _initialized;

  Future<void> startListening({
    required Function(String text) onResult,
    String localeId = 'hi_IN',
  }) async {
    if (!_initialized) await initialize();
    if (!_initialized) return;

    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> cancel() async {
    await _speech.cancel();
  }

  void dispose() {
    _speech.cancel();
  }
}
