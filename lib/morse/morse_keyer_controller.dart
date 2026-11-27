import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:morse_bunker/audio/morse_audio_service.dart';
import 'package:morse_bunker/morse/morse_curriculum.dart';
import 'package:morse_bunker/morse/morse_table.dart';
import 'package:morse_bunker/morse/morse_timing.dart';

/// Supported lighting atmospheres for the 3D military bunker scene.
enum BunkerAtmosphere {
  undergroundBunker('지하 벙커'),
  darkroomRed('암실 적색등'),
  nightOpsGreen('야간 작전실');

  const BunkerAtmosphere(this.label);
  final String label;
}

/// Supported 3D camera framing presets.
enum BunkerCameraPreset {
  deskOverview('전건실 기본'),
  telegraphCloseUp('전건 클로즈업'),
  bunkerWide('벙커 전체');

  const BunkerCameraPreset(this.label);
  final String label;
}

/// Unified state controller bridging manual keying, timeline playback,
/// guided tap-along learning, CW audio, and the 3D flutter_scene bunker.
class MorseKeyerController extends ChangeNotifier {
  MorseKeyerController({
    MorseAudioService? audioService,
    this.enableAudio = true,
  }) : _audio = audioService ?? MorseAudioService();

  final MorseAudioService _audio;
  final bool enableAudio;
  bool _audioInitRequested = false;

  // Audio & timing settings
  MorseTimingConfig _timing = const MorseTimingConfig(wpm: 12);
  MorseLanguageMode _languageMode = MorseLanguageMode.koreanSkats;
  double _toneFrequencyHz = 680.0;
  bool _soundEnabled = true;
  bool _ambientHumEnabled = false;

  // 3D Scene visual settings
  BunkerAtmosphere _atmosphere = BunkerAtmosphere.undergroundBunker;
  BunkerCameraPreset _cameraPreset = BunkerCameraPreset.deskOverview;

  // Live keying state
  bool _isKeyDown = false;
  DateTime? _keyDownAt;
  Timer? _charCommitTimer;
  Timer? _wordSpaceTimer;
  Timer? _liveHoldTicker;
  int _currentHoldMs = 0;

  // Decoded free-keying tape
  String _currentMorseBuffer = '';
  String _decodedText = '';
  final List<String> _recentPressLogs = [];

  // Rolling oscilloscope samples (0.0..1.0)
  static const int kWaveformLength = 96;
  final List<double> _waveformSamples = List<double>.filled(kWaveformLength, 0.0);

  // Automated demo playback state
  int _playbackSessionId = 0;
  bool _isPlayingDemo = false;
  bool _demoLampVisible = true;
  bool _demoAudioAudible = true;
  bool _externalSignalActive = false;
  int? _activePlaybackCharIndex;
  int? _activePlaybackSymbolIndex;
  String _activePlaybackLabel = '';

  // Guided practice state
  GuidedPracticeState? _guidedPractice;
  void Function(int durationMs, bool matched)? onManualPressEvaluated;

  // Drill XP & Rank stats
  int _drillScore = 0;
  int _drillStreak = 0;
  int _drillTotal = 0;
  int _drillCorrect = 0;

  // Getters
  MorseTimingConfig get timing => _timing;
  MorseLanguageMode get languageMode => _languageMode;
  double get toneFrequencyHz => _toneFrequencyHz;
  bool get soundEnabled => _soundEnabled;
  bool get ambientHumEnabled => _ambientHumEnabled;
  BunkerAtmosphere get atmosphere => _atmosphere;
  BunkerCameraPreset get cameraPreset => _cameraPreset;

  bool get isKeyDown => _isKeyDown;
  int get currentHoldMs => _currentHoldMs;
  String get currentMorseBuffer => _currentMorseBuffer;
  String get decodedText => _decodedText;
  List<String> get recentPressLogs => List.unmodifiable(_recentPressLogs);
  List<double> get waveformSamples => List.unmodifiable(_waveformSamples);

  bool get isPlayingDemo => _isPlayingDemo;
  bool get isLampActive =>
      (_isKeyDown && (!_isPlayingDemo || _demoLampVisible)) ||
      _externalSignalActive;

  /// Flashes the 3D bunker signal beacon & CRT for external audio (e.g. mic capture)
  /// without playing local sidetone to avoid acoustic feedback.
  void setExternalSignalActive(bool active) {
    if (_externalSignalActive == active) return;
    _externalSignalActive = active;
    notifyListeners();
  }
  int? get activePlaybackCharIndex => _activePlaybackCharIndex;
  int? get activePlaybackSymbolIndex => _activePlaybackSymbolIndex;
  String get activePlaybackLabel => _activePlaybackLabel;

  GuidedPracticeState? get guidedPractice => _guidedPractice;

  int get drillScore => _drillScore;
  int get drillStreak => _drillStreak;
  int get drillTotal => _drillTotal;
  int get drillCorrect => _drillCorrect;
  double get drillAccuracy =>
      _drillTotal == 0 ? 1.0 : _drillCorrect / _drillTotal;

  String get militaryRank {
    if (_drillScore >= 600) return '통신장교 (소위)';
    if (_drillScore >= 400) return '중사 · 선임무전병';
    if (_drillScore >= 250) return '하사 · 전술통신병';
    if (_drillScore >= 140) return '병장 · 정예통신병';
    if (_drillScore >= 60) return '상병 · 무전병';
    if (_drillScore >= 20) return '일병 · 통신훈련병';
    return '이등병 · 신입통신병';
  }

  /// Live preview of what [currentMorseBuffer] decodes to right now.
  String? get liveBufferCandidate {
    if (_currentMorseBuffer.isEmpty) return null;
    return decodeMorseSymbol(_currentMorseBuffer, mode: _languageMode);
  }

  /// Initializes the audio subsystem safely.
  Future<void> initAudio() async {
    if (!enableAudio) return;
    _audioInitRequested = true;
    await _audio.ensureReady(frequencyHz: _toneFrequencyHz);
  }

  Future<void> _ensureAudioOnGesture() async {
    if (!enableAudio || _audio.isAvailable) return;
    if (!_audioInitRequested) {
      _audioInitRequested = true;
    }
    await _audio.ensureReady(frequencyHz: _toneFrequencyHz);
    if (_audio.isAvailable) {
      if (_ambientHumEnabled) {
        _audio.setAmbientHum(true);
      }
      if (_isKeyDown && _soundEnabled && (!_isPlayingDemo || _demoAudioAudible)) {
        _audio.setKeyDown(true);
      }
    }
  }

  void setWpm(int wpm) {
    final clamped = wpm.clamp(5, 25);
    if (_timing.wpm == clamped) return;
    _timing = _timing.copyWith(wpm: clamped);
    if (_guidedPractice != null) {
      _guidedPractice = GuidedPracticeState(
        targetText: _guidedPractice!.targetText,
        mode: _guidedPractice!.mode,
        timing: _timing,
      );
    }
    notifyListeners();
  }

  void setFarnsworth(bool enabled) {
    if (_timing.farnsworthEnabled == enabled) return;
    _timing = _timing.copyWith(farnsworthEnabled: enabled);
    notifyListeners();
  }

  void setLanguageMode(MorseLanguageMode mode) {
    if (_languageMode == mode) return;
    _languageMode = mode;
    notifyListeners();
  }

  void setToneFrequency(double hz) {
    _toneFrequencyHz = hz.clamp(450.0, 950.0);
    _audio.setFrequency(_toneFrequencyHz);
    notifyListeners();
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (!enabled) {
      _audio.setKeyDown(false);
    }
    notifyListeners();
  }

  void setAmbientHum(bool enabled) {
    _ambientHumEnabled = enabled;
    if (enabled) {
      unawaited(_ensureAudioOnGesture());
    }
    _audio.setAmbientHum(enabled);
    notifyListeners();
  }

  void setAtmosphere(BunkerAtmosphere atmosphere) {
    if (_atmosphere == atmosphere) return;
    _atmosphere = atmosphere;
    notifyListeners();
  }

  void setCameraPreset(BunkerCameraPreset preset) {
    if (_cameraPreset == preset) return;
    _cameraPreset = preset;
    notifyListeners();
  }

  /// Advances the rolling oscilloscope waveform (called from UI/3D tick).
  void sampleOscilloscopeTick(double elapsedSeconds) {
    final active = _isKeyDown;
    final sample = active
        ? (0.5 +
            0.46 *
                math.sin(elapsedSeconds * _toneFrequencyHz * 0.085))
        : 0.0;
    _waveformSamples.removeAt(0);
    _waveformSamples.add(sample);
    // Do not spam notifyListeners unless waveform listener needs it;
    // custom painters can listen via Repaint or keyer changes.
  }

  /// Called when the user presses down the telegraph key (mouse, touch, Spacebar, or 3D raycast).
  void pressKey({bool cancelDemoIfPlaying = true}) {
    if (cancelDemoIfPlaying && _isPlayingDemo) {
      stopDemo();
    }
    if (_isKeyDown) return;

    _charCommitTimer?.cancel();
    _wordSpaceTimer?.cancel();

    _isKeyDown = true;
    _keyDownAt = DateTime.now();
    _currentHoldMs = 0;

    if (_soundEnabled && (!_isPlayingDemo || _demoAudioAudible)) {
      if (!_audio.isAvailable) {
        unawaited(_ensureAudioOnGesture());
      } else {
        _audio.setKeyDown(true);
      }
    }

    _liveHoldTicker?.cancel();
    _liveHoldTicker = Timer.periodic(const Duration(milliseconds: 24), (_) {
      if (!_isKeyDown || _keyDownAt == null) return;
      _currentHoldMs = DateTime.now().difference(_keyDownAt!).inMilliseconds;
      notifyListeners();
    });

    notifyListeners();
  }

  /// Called when the user releases the telegraph key.
  void releaseKey({bool fromDemo = false}) {
    if (!_isKeyDown) return;

    final now = DateTime.now();
    final durationMs = _keyDownAt == null
        ? _timing.ditMs
        : now.difference(_keyDownAt!).inMilliseconds.clamp(15, 5000);

    _isKeyDown = false;
    _keyDownAt = null;
    _currentHoldMs = 0;
    _liveHoldTicker?.cancel();
    _audio.setKeyDown(false);

    if (!fromDemo) {
      final symbol = durationMs >= _timing.ditDahThresholdMs ? kDah : kDit;
      _currentMorseBuffer += symbol;
      _recentPressLogs.insert(0, '$symbol (${durationMs}ms)');
      if (_recentPressLogs.length > 14) {
        _recentPressLogs.removeLast();
      }

      if (_guidedPractice != null && !_guidedPractice!.isCompleted) {
        final matched = _guidedPractice!.registerKeyPress(durationMs);
        onManualPressEvaluated?.call(durationMs, matched);
      } else {
        onManualPressEvaluated?.call(durationMs, true);
      }

      _scheduleDecodeTimers();
    }

    notifyListeners();
  }

  void _scheduleDecodeTimers() {
    _charCommitTimer?.cancel();
    _wordSpaceTimer?.cancel();

    _charCommitTimer = Timer(
      Duration(milliseconds: _timing.charCommitGapMs),
      commitBufferedCharacter,
    );
    _wordSpaceTimer = Timer(
      Duration(milliseconds: _timing.wordSpaceGapMs),
      () {
        if (_decodedText.isNotEmpty && !_decodedText.endsWith(' ')) {
          _decodedText += ' ';
          notifyListeners();
        }
      },
    );
  }

  /// Commits the current dit/dah buffer into [decodedText].
  void commitBufferedCharacter() {
    if (_currentMorseBuffer.isEmpty) return;
    final decoded =
        decodeMorseSymbol(_currentMorseBuffer, mode: _languageMode) ?? '?';
    _decodedText += decoded;
    _currentMorseBuffer = '';
    notifyListeners();
  }

  void clearDecodedText() {
    _charCommitTimer?.cancel();
    _wordSpaceTimer?.cancel();
    _currentMorseBuffer = '';
    _decodedText = '';
    _recentPressLogs.clear();
    notifyListeners();
  }

  void backspaceDecodedText() {
    if (_currentMorseBuffer.isNotEmpty) {
      _currentMorseBuffer = '';
    } else if (_decodedText.isNotEmpty) {
      _decodedText = _decodedText.substring(0, _decodedText.length - 1);
    }
    notifyListeners();
  }

  /// Starts or updates Guided Tap-Along practice for [targetText].
  void startGuidedPractice(String targetText, {MorseLanguageMode? mode}) {
    stopDemo();
    _guidedPractice = GuidedPracticeState(
      targetText: targetText,
      mode: mode ?? _languageMode,
      timing: _timing,
    );
    notifyListeners();
  }

  void exitGuidedPractice() {
    _guidedPractice = null;
    notifyListeners();
  }

  /// Plays [text] (or a single Morse symbol like `SOS` / `·−`) as an animated 3D + audio demo.
  Future<void> playTextDemo(
    String text, {
    MorseLanguageMode? mode,
    bool showLamp = true,
    bool playAudio = true,
  }) async {
    final plan = buildMorseTransmissionPlan(
      text,
      mode: mode ?? _languageMode,
      timing: _timing,
    );
    await playTransmissionPlan(
      plan,
      showLamp: showLamp,
      playAudio: playAudio,
    );
  }

  /// Plays a raw Morse pattern such as `···−−−···` directly.
  Future<void> playRawMorseDemo(
    String rawMorse, {
    String label = '',
    bool showLamp = true,
    bool playAudio = true,
  }) async {
    final normalized = normalizeMorseSymbols(rawMorse);
    final events = <MorseSignalEvent>[];
    final symbols = normalized.split('');
    for (var i = 0; i < symbols.length; i++) {
      final sym = symbols[i];
      if (sym == ' ') {
        events.add(
          MorseSignalEvent(
            isOn: false,
            durationMs: _timing.interCharGapMs,
            charIndex: 0,
            symbolIndex: i,
            symbol: ' ',
            label: '간격',
          ),
        );
        continue;
      }
      if (sym != kDit && sym != kDah) continue;
      final onMs = sym == kDah ? _timing.dahMs : _timing.ditMs;
      events.add(
        MorseSignalEvent(
          isOn: true,
          durationMs: onMs,
          charIndex: 0,
          symbolIndex: i,
          symbol: sym,
          label: label.isEmpty ? sym : '$label ($sym)',
        ),
      );
      if (i < symbols.length - 1 && symbols[i + 1] != ' ') {
        events.add(
          MorseSignalEvent(
            isOn: false,
            durationMs: _timing.intraCharGapMs,
            charIndex: 0,
            symbolIndex: i,
            symbol: ' ',
            label: '쉼',
          ),
        );
      }
    }
    await _runEvents(events, showLamp: showLamp, playAudio: playAudio);
  }

  Future<void> playTransmissionPlan(
    MorseTransmissionPlan plan, {
    bool showLamp = true,
    bool playAudio = true,
  }) async {
    await _runEvents(plan.events, showLamp: showLamp, playAudio: playAudio);
  }

  Future<void> _runEvents(
    List<MorseSignalEvent> events, {
    required bool showLamp,
    required bool playAudio,
  }) async {
    stopDemo();
    if (events.isEmpty) return;

    if (playAudio && _soundEnabled && !_audio.isAvailable) {
      await _ensureAudioOnGesture();
    }

    final session = ++_playbackSessionId;
    _isPlayingDemo = true;
    _demoLampVisible = showLamp;
    _demoAudioAudible = playAudio;
    notifyListeners();

    for (final ev in events) {
      if (session != _playbackSessionId) break;

      _activePlaybackCharIndex = ev.charIndex;
      _activePlaybackSymbolIndex = ev.symbolIndex;
      _activePlaybackLabel = ev.label;

      if (ev.isOn) {
        _isKeyDown = true;
        if (_soundEnabled && playAudio) {
          _audio.setKeyDown(true);
        }
      } else {
        _isKeyDown = false;
        _audio.setKeyDown(false);
      }
      notifyListeners();

      await Future<void>.delayed(Duration(milliseconds: ev.durationMs));
    }

    if (session == _playbackSessionId) {
      _isKeyDown = false;
      _isPlayingDemo = false;
      _demoLampVisible = true;
      _demoAudioAudible = true;
      _activePlaybackCharIndex = null;
      _activePlaybackSymbolIndex = null;
      _activePlaybackLabel = '';
      _audio.setKeyDown(false);
      notifyListeners();
    }
  }

  void stopDemo() {
    _playbackSessionId++;
    final wasPlaying = _isPlayingDemo || _isKeyDown;
    _isPlayingDemo = false;
    _isKeyDown = false;
    _demoLampVisible = true;
    _demoAudioAudible = true;
    _activePlaybackCharIndex = null;
    _activePlaybackSymbolIndex = null;
    _activePlaybackLabel = '';
    _audio.setKeyDown(false);
    if (wasPlaying) {
      notifyListeners();
    }
  }

  void recordDrillResult(bool isCorrect, {int points = 15}) {
    _drillTotal++;
    if (isCorrect) {
      _drillCorrect++;
      _drillStreak++;
      _drillScore += points + (_drillStreak > 1 ? (_drillStreak * 2) : 0);
    } else {
      _drillStreak = 0;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _playbackSessionId++;
    _charCommitTimer?.cancel();
    _wordSpaceTimer?.cancel();
    _liveHoldTicker?.cancel();
    _audio.dispose();
    super.dispose();
  }
}
