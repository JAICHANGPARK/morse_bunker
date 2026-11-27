import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:morse_bunker/morse/morse_acoustic_decoder.dart';
import 'package:morse_bunker/morse/morse_keyer_controller.dart';
import 'package:record/record.dart';

/// Coordinates live microphone PCM streaming, on-device Goertzel acoustic
/// Morse decoding, and Gemini Live (`gemini-3.8-live`) real-time interpretation.
class MorseMicLiveController extends ChangeNotifier {
  MorseMicLiveController({
    required this.keyerController,
    this.enableMic = true,
  }) : decoder = MorseAcousticDecoder(
          timing: keyerController.timing,
          languageMode: keyerController.languageMode,
        );

  final MorseKeyerController keyerController;
  final bool enableMic;
  final MorseAcousticDecoder decoder;

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _micSub;
  final StreamController<Uint8List> _micBroadcastController =
      StreamController<Uint8List>.broadcast();

  bool _isListening = false;
  bool _noiseSuppressionEnabled = false;
  int _actualSampleRate = 16000;
  String _statusMessage = '마이크 감청 대기 중 (CW 비프음 또는 두드림 소리 감지)';
  DateTime _lastUiSync = DateTime.fromMillisecondsSinceEpoch(0);

  // Gemini Live state
  GoogleGenAI? _genAI;
  GeminiLiveSessionController? _liveController;
  StreamSubscription<Uint8List>? _speakerSub;
  AudioSource? _playbackSource;
  bool _voiceOutputEnabled = true;
  bool _connectingGemini = false;
  String _geminiError = '';

  static const String _defaultSystemPrompt = '''
당신은 대한민국 군 지하 벙커의 베테랑 모스부호 전신·신호 해석 교관입니다.
사용자의 마이크에서 들려오는 모스부호 비프음(CW 톤), 두드림/노크 소리, 또는 음성 질문과 DSP 측정 데이터를 실시간으로 듣고 정확히 해독하세요.
규칙:
1. 모스 신호가 감지되면 반드시 [모스 부호: · − ...] [해독 텍스트: ...] [의미/전술 설명: ...] 형식으로 간결하고 명확하게 한국어로 답변하세요.
2. 잡음이나 불완전한 리듬이 있으면 단음(·)과 장음(−) 비율(1:3) 교정 팁을 한 문장으로 덧붙이세요.
3. 사용자가 일반 음성으로 질문하면 벙커 통신 교관 말투로 친절하고 정확하게 답하세요.
''';

  /// Broadcast stream of captured PCM 16-bit LE chunks (created once).
  Stream<Uint8List> get micPcmStream => _micBroadcastController.stream;

  bool get isListening => _isListening;
  bool get noiseSuppressionEnabled => _noiseSuppressionEnabled;
  int get actualSampleRate => _actualSampleRate;
  String get statusMessage => _statusMessage;

  bool get voiceOutputEnabled => _voiceOutputEnabled;
  bool get isConnectingGemini => _connectingGemini;
  bool get isGeminiConnected => _liveController?.isConnected ?? false;
  String get geminiError => _geminiError;

  GeminiLiveSessionController? get liveController => _liveController;
  LiveSessionState get liveSessionState =>
      _liveController?.state ?? LiveSessionState.disconnected;

  /// Syncs timing/language changes from [keyerController] into the DSP decoder.
  void syncDecoderSettings() {
    decoder.timing = keyerController.timing;
    decoder.languageMode = keyerController.languageMode;
  }

  void setListenMode(AcousticListenMode mode) {
    if (decoder.mode == mode) return;
    decoder.mode = mode;
    _statusMessage = mode == AcousticListenMode.cwTone
        ? 'CW 비프음 자동 주파수 추적 모드 (400–1100 Hz)'
        : '두드림·노크 광대역 에너지 감지 모드';
    notifyListeners();
  }

  void setSensitivity(double value) {
    decoder.sensitivity = value.clamp(0.2, 1.0);
    notifyListeners();
  }

  void setNoiseSuppression(bool enabled) {
    if (_noiseSuppressionEnabled == enabled) return;
    _noiseSuppressionEnabled = enabled;
    notifyListeners();
  }

  void setVoiceOutputEnabled(bool enabled) {
    if (_voiceOutputEnabled == enabled) return;
    _voiceOutputEnabled = enabled;
    notifyListeners();
  }

  void clearDecoded() {
    decoder.reset();
    keyerController.setExternalSignalActive(false);
    notifyListeners();
  }

  void commitBuffer() {
    decoder.commitNow();
    notifyListeners();
  }

  /// Starts capturing microphone 16-bit PCM audio for DSP decoding and Gemini Live.
  Future<void> startListening() async {
    if (!enableMic || _isListening) return;
    syncDecoderSettings();

    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _statusMessage = '마이크 권한이 거부되었습니다. 시스템/브라우저 설정에서 허용해 주세요.';
        notifyListeners();
        return;
      }

      _actualSampleRate = 16000;
      decoder.sampleRate = 16000;
      await _recorder.setOnConfigChanged((cfg) {
        _actualSampleRate = cfg.sampleRate;
        decoder.sampleRate = cfg.sampleRate;
      });

      final stream = await _recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          echoCancel: _noiseSuppressionEnabled,
          noiseSuppress: _noiseSuppressionEnabled,
          autoGain: false,
        ),
      );

      _isListening = true;
      _statusMessage = '마이크 감청 활성화 · 모스부호 소리를 들려주세요';
      notifyListeners();

      _micSub = stream.listen(
        (Uint8List chunk) {
          syncDecoderSettings();
          decoder.processPcm16(chunk);
          keyerController.setExternalSignalActive(decoder.isToneActive);

          if (!_micBroadcastController.isClosed) {
            _micBroadcastController.add(chunk);
          }

          final live = _liveController;
          if (live != null && live.isConnected) {
            final pcm16k = _actualSampleRate == 16000
                ? chunk
                : resamplePcm16Mono(chunk, _actualSampleRate, 16000);
            live.sendRealtimeAudio(pcm16k);
          }

          final now = DateTime.now();
          if (now.difference(_lastUiSync).inMilliseconds >= 50) {
            _lastUiSync = now;
            notifyListeners();
          }
        },
        onError: (Object error) {
          _statusMessage = '마이크 스트림 오류: $error';
          _isListening = false;
          keyerController.setExternalSignalActive(false);
          notifyListeners();
        },
        onDone: () {
          _isListening = false;
          keyerController.setExternalSignalActive(false);
          notifyListeners();
        },
      );
    } catch (e) {
      _isListening = false;
      _statusMessage = '마이크 시작 실패: $e';
      keyerController.setExternalSignalActive(false);
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    await _micSub?.cancel();
    _micSub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    decoder.flushSilence(keyerController.timing.wordGapMs);
    keyerController.setExternalSignalActive(false);
    _liveController?.stopUserSpeaking();
    _isListening = false;
    _statusMessage = '마이크 감청 중지됨';
    notifyListeners();
  }

  /// Connects to `gemini-3.8-live` over WebSockets using the provided API key.
  Future<void> connectGeminiLive(String apiKey) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      _geminiError = 'Gemini API Key를 입력해 주세요.';
      notifyListeners();
      return;
    }

    await disconnectGeminiLive();

    _connectingGemini = true;
    _geminiError = '';
    notifyListeners();

    try {
      final genAI = GoogleGenAI(apiKey: trimmedKey);
      final liveCtrl = GeminiLiveSessionController(liveService: genAI.live);
      liveCtrl.addListener(_onLiveControllerChanged);

      _genAI = genAI;
      _liveController = liveCtrl;

      await liveCtrl.connect(
        LiveConnectParameters(
          model: LiveModels.gemini38Live,
          systemInstruction: Content(
            parts: [Part(text: _defaultSystemPrompt)],
          ),
          config: GenerationConfig(
            responseModalities: [
              _voiceOutputEnabled ? Modality.AUDIO : Modality.TEXT,
            ],
            speechConfig: _voiceOutputEnabled
                ? SpeechConfig(
                    voiceConfig: VoiceConfig(
                      prebuiltVoiceConfig: PrebuiltVoiceConfig(
                        voiceName: 'Puck',
                      ),
                    ),
                  )
                : null,
          ),
          inputAudioTranscription: AudioTranscriptionConfig(
            languageCodes: ['ko-KR', 'en-US'],
          ),
          outputAudioTranscription:
              _voiceOutputEnabled ? AudioTranscriptionConfig() : null,
          callbacks: LiveCallbacks(
            onError: (err, st) {
              _geminiError = 'Gemini Live 오류: $err';
              notifyListeners();
            },
            onClose: (code, [reason]) {
              if (code != 1000 && reason != null && reason.isNotEmpty) {
                _geminiError = '세션 종료 ($code): $reason';
              }
              _resetAudioOutput();
              notifyListeners();
            },
          ),
        ),
      );

      if (_voiceOutputEnabled) {
        await _setupAudioOutput(liveCtrl);
      }

      _statusMessage = 'Gemini Live (${LiveModels.gemini38Live}) 연결 완료';
    } catch (e) {
      _geminiError = '연결 실패: $e';
      await disconnectGeminiLive(preserveError: true);
    } finally {
      _connectingGemini = false;
      notifyListeners();
    }
  }

  Future<void> _setupAudioOutput(GeminiLiveSessionController liveCtrl) async {
    try {
      final soloud = SoLoud.instance;
      if (!soloud.isInitialized) {
        await soloud.init(lowLatency: true);
      }
      _speakerSub?.cancel();
      _speakerSub = liveCtrl.incomingAudioStream.listen((pcmChunk) {
        if (!SoLoud.instance.isInitialized) return;
        _playbackSource ??= SoLoud.instance.setBufferStream(
          sampleRate: 24000,
          channels: Channels.mono,
          format: BufferType.s16le,
          bufferingType: BufferingType.released,
        );
        final source = _playbackSource!;
        if (SoLoud.instance.getActiveVoiceCount() == 0) {
          SoLoud.instance.play(source);
        }
        SoLoud.instance.addAudioDataStream(source, pcmChunk);
      });
    } catch (e) {
      debugPrint('SoLoud 24kHz Gemini output setup skipped: $e');
    }
  }

  void _onLiveControllerChanged() {
    if (_liveController?.isInterrupted == true) {
      _resetAudioOutput();
    }
    notifyListeners();
  }

  void _resetAudioOutput() {
    final source = _playbackSource;
    _playbackSource = null;
    if (source != null) {
      try {
        SoLoud.instance.disposeSource(source);
      } catch (_) {}
    }
  }

  /// Sends the currently captured DSP Morse buffer & decoded text to Gemini Live
  /// for contextual interpretation (prosigns, typos, rhythm coaching).
  void askAiToInterpretCurrentBuffer() {
    final live = _liveController;
    if (live == null || !live.isConnected) return;
    decoder.commitNow();
    final morse = decoder.recentEvents.reversed.take(16).join(' ');
    final decoded = decoder.decodedText.trim();
    final freq = decoder.detectedFrequencyHz.round();

    final prompt = decoded.isEmpty && morse.isEmpty
        ? '지금 마이크에서 들리는 모스부호 소리를 실시간으로 듣고 해독해 주세요.'
        : '방금 마이크 DSP(${freq}Hz)로 감지한 모스 신호입니다.\n'
            '해독된 텍스트: "$decoded"\n'
            '최근 타건 로그: $morse\n'
            '이 신호가 어떤 의미인지, 오타/타이밍 오차가 있다면 무엇으로 추정되는지 한국어로 해석해 주세요.';

    live.sendRealtimeText(prompt);
    notifyListeners();
  }

  Future<void> disconnectGeminiLive({bool preserveError = false}) async {
    await _speakerSub?.cancel();
    _speakerSub = null;
    _resetAudioOutput();

    final live = _liveController;
    _liveController = null;
    if (live != null) {
      live.removeListener(_onLiveControllerChanged);
      try {
        await live.disconnect();
      } catch (_) {}
      live.dispose();
    }

    try {
      _genAI?.close();
    } catch (_) {}
    _genAI = null;

    if (!preserveError) {
      _geminiError = '';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _micSub?.cancel();
    _speakerSub?.cancel();
    _resetAudioOutput();
    _recorder.dispose();
    _liveController?.removeListener(_onLiveControllerChanged);
    _liveController?.dispose();
    _genAI?.close();
    _micBroadcastController.close();
    super.dispose();
  }
}
