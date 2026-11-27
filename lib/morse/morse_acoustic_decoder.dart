import 'dart:math' as math;
import 'dart:typed_data';

import 'package:morse_bunker/morse/morse_table.dart';
import 'package:morse_bunker/morse/morse_timing.dart';

/// Acoustic detection strategy for incoming microphone audio.
enum AcousticListenMode {
  /// Narrowband Goertzel frequency tracker (ideal for radio/phone CW beeps 400-1100 Hz).
  cwTone('CW 비프음 (자동 주파수)'),

  /// Broadband RMS energy envelope (ideal for table knocks, clapping, or mechanical clicks).
  broadbandTap('두드림·노크 (광대역)');

  const AcousticListenMode(this.label);
  final String label;
}

/// Resamples mono 16-bit little-endian PCM from [fromRate] to [toRate] using linear interpolation.
Uint8List resamplePcm16Mono(Uint8List input, int fromRate, int toRate) {
  if (fromRate <= 0 || toRate <= 0 || fromRate == toRate || input.length < 4) {
    return input;
  }
  final inSamples = input.lengthInBytes ~/ 2;
  if (inSamples < 2) return input;

  final inView = ByteData.sublistView(input);
  final outSamples = ((inSamples * toRate) / fromRate).round().clamp(1, 1 << 20);
  final outBytes = Uint8List(outSamples * 2);
  final outView = ByteData.view(outBytes.buffer);
  final ratio = (inSamples - 1) / math.max(1, outSamples - 1);

  for (var i = 0; i < outSamples; i++) {
    final srcPos = i * ratio;
    final idx0 = srcPos.floor().clamp(0, inSamples - 1);
    final idx1 = (idx0 + 1).clamp(0, inSamples - 1);
    final frac = srcPos - idx0;
    final s0 = inView.getInt16(idx0 * 2, Endian.little);
    final s1 = inView.getInt16(idx1 * 2, Endian.little);
    final interpolated = (s0 + (s1 - s0) * frac).round().clamp(-32768, 32767);
    outView.setInt16(i * 2, interpolated, Endian.little);
  }
  return outBytes;
}

/// Real-time on-device acoustic Morse code decoder using Goertzel tone detection
/// and adaptive noise-floor hysteresis.
class MorseAcousticDecoder {
  MorseAcousticDecoder({
    this.sampleRate = 16000,
    this.mode = AcousticListenMode.cwTone,
    this.timing = const MorseTimingConfig(wpm: 12),
    this.languageMode = MorseLanguageMode.romanized,
    this.sensitivity = 0.55,
  });

  static const int _frameSize = 256;
  static const List<double> _candidateFreqs = [
    400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100,
  ];

  int sampleRate;
  AcousticListenMode mode;
  MorseTimingConfig timing;
  MorseLanguageMode languageMode;

  /// Detection sensitivity in `[0.2, 1.0]`. Higher values lower the trigger threshold.
  double sensitivity;

  final List<double> _pendingSamples = [];
  double _noiseFloor = 0.008;
  double _peakEnvelope = 0.02;

  bool _isToneActive = false;
  int _stateDurationMs = 0;
  bool _charCommittedForGap = false;
  bool _wordSpaceInserted = false;

  double _detectedFrequencyHz = 700.0;
  double _signalSnrDb = 0.0;
  double _currentLevel = 0.0;

  String _currentMorseBuffer = '';
  String _decodedText = '';
  final List<String> _recentEvents = [];

  bool get isToneActive => _isToneActive;
  double get detectedFrequencyHz => _detectedFrequencyHz;
  double get signalSnrDb => _signalSnrDb;
  double get currentLevel => _currentLevel;
  String get currentMorseBuffer => _currentMorseBuffer;
  String get decodedText => _decodedText;
  List<String> get recentEvents => List.unmodifiable(_recentEvents);

  void reset() {
    _pendingSamples.clear();
    _noiseFloor = 0.008;
    _peakEnvelope = 0.02;
    _isToneActive = false;
    _stateDurationMs = 0;
    _charCommittedForGap = false;
    _wordSpaceInserted = false;
    _currentLevel = 0.0;
    _signalSnrDb = 0.0;
    _currentMorseBuffer = '';
    _decodedText = '';
    _recentEvents.clear();
  }

  /// Processes raw 16-bit little-endian mono PCM audio bytes.
  void processPcm16(Uint8List bytes) {
    if (bytes.lengthInBytes < 2) return;
    final data = ByteData.sublistView(bytes);
    final count = bytes.lengthInBytes ~/ 2;
    for (var i = 0; i < count; i++) {
      _pendingSamples.add(data.getInt16(i * 2, Endian.little) / 32768.0);
    }

    while (_pendingSamples.length >= _frameSize) {
      final frame = _pendingSamples.sublist(0, _frameSize);
      _pendingSamples.removeRange(0, _frameSize);
      _processFrame(frame);
    }
  }

  /// Advances silence duration artificially (useful when mic stops or in tests).
  void flushSilence(int silenceMs) {
    if (silenceMs <= 0) return;
    if (_isToneActive) {
      _finishToneOn(_stateDurationMs);
      _isToneActive = false;
      _stateDurationMs = 0;
    }
    _advanceSilence(silenceMs);
  }

  /// Forces immediate commit of any buffered `·`/`−` symbols into [decodedText].
  void commitNow() {
    if (_currentMorseBuffer.isEmpty) return;
    final decoded =
        decodeMorseSymbol(_currentMorseBuffer, mode: languageMode) ?? '?';
    _decodedText += decoded;
    _currentMorseBuffer = '';
    _charCommittedForGap = true;
  }

  void _processFrame(List<double> frame) {
    final frameMs = ((_frameSize * 1000) / sampleRate).round().clamp(4, 50);

    var sumSq = 0.0;
    for (final s in frame) {
      sumSq += s * s;
    }
    final rms = math.sqrt(sumSq / frame.length);
    _currentLevel = (rms * 4.5).clamp(0.0, 1.0);

    bool detected;
    if (mode == AcousticListenMode.cwTone) {
      detected = _detectCwTone(frame, rms);
    } else {
      detected = _detectBroadband(rms);
    }

    if (detected == _isToneActive) {
      _stateDurationMs += frameMs;
      if (!_isToneActive) {
        _advanceSilence(frameMs);
      }
      return;
    }

    // Transition occurred
    if (detected) {
      // OFF -> ON
      _isToneActive = true;
      _stateDurationMs = frameMs;
      _charCommittedForGap = false;
      _wordSpaceInserted = false;
    } else {
      // ON -> OFF
      _finishToneOn(_stateDurationMs);
      _isToneActive = false;
      _stateDurationMs = frameMs;
      _advanceSilence(frameMs);
    }
  }

  bool _detectCwTone(List<double> frame, double rms) {
    var bestPower = 0.0;
    var bestFreq = _detectedFrequencyHz;
    var totalPower = 0.0;

    for (final freq in _candidateFreqs) {
      final p = _goertzelPower(frame, freq, sampleRate);
      totalPower += p;
      if (p > bestPower) {
        bestPower = p;
        bestFreq = freq;
      }
    }

    final avgOther = math.max(
      1e-9,
      (totalPower - bestPower) / (_candidateFreqs.length - 1),
    );
    final snrRatio = bestPower / avgOther;
    _signalSnrDb = (10.0 * math.log(math.max(1.0, snrRatio)) / math.ln10);

    final normAmp = math.sqrt(bestPower) / (frame.length * 0.5);
    final sensFactor = 1.45 - sensitivity.clamp(0.2, 1.0); // ~0.45..1.25
    final minSnr = 2.6 + (1.0 - sensitivity) * 3.0;
    final minAmp = math.max(_noiseFloor * (2.2 * sensFactor), 0.008 * sensFactor);

    final isStrongTone = normAmp > minAmp && snrRatio > minSnr;

    if (isStrongTone) {
      _detectedFrequencyHz = bestFreq;
      _peakEnvelope = _peakEnvelope * 0.85 + normAmp * 0.15;
    } else {
      _noiseFloor = _noiseFloor * 0.96 + rms * 0.04;
    }

    if (_isToneActive) {
      // Hysteresis: hold ON slightly lower than attack threshold
      return normAmp > minAmp * 0.58 && snrRatio > (minSnr * 0.65);
    }
    return isStrongTone;
  }

  bool _detectBroadband(double rms) {
    final sensFactor = 1.5 - sensitivity.clamp(0.2, 1.0);
    final attackThreshold = math.max(_noiseFloor * (2.8 * sensFactor), 0.014 * sensFactor);
    final releaseThreshold = attackThreshold * 0.55;

    if (rms < attackThreshold * 0.8) {
      _noiseFloor = _noiseFloor * 0.95 + rms * 0.05;
    }
    return _isToneActive ? rms > releaseThreshold : rms > attackThreshold;
  }

  double _goertzelPower(List<double> samples, double targetFreq, int rate) {
    final omega = 2.0 * math.pi * targetFreq / rate;
    final coeff = 2.0 * math.cos(omega);
    var q0 = 0.0;
    var q1 = 0.0;
    var q2 = 0.0;
    for (var i = 0; i < samples.length; i++) {
      q0 = coeff * q1 - q2 + samples[i];
      q2 = q1;
      q1 = q0;
    }
    return q1 * q1 + q2 * q2 - q1 * q2 * coeff;
  }

  void _finishToneOn(int durationMs) {
    final minPulseMs = mode == AcousticListenMode.cwTone ? 28 : 20;
    if (durationMs < minPulseMs) {
      // Ignore tiny microphone clicks/glitches
      return;
    }
    final symbol = durationMs >= timing.ditDahThresholdMs ? kDah : kDit;
    _currentMorseBuffer += symbol;
    _recentEvents.insert(0, '$symbol (${durationMs}ms)');
    if (_recentEvents.length > 14) {
      _recentEvents.removeLast();
    }
  }

  void _advanceSilence(int ms) {
    if (!_charCommittedForGap &&
        _currentMorseBuffer.isNotEmpty &&
        _stateDurationMs >= timing.charCommitGapMs) {
      commitNow();
    }
    if (!_wordSpaceInserted &&
        _decodedText.isNotEmpty &&
        !_decodedText.endsWith(' ') &&
        _stateDurationMs >= timing.wordSpaceGapMs) {
      _decodedText += ' ';
      _wordSpaceInserted = true;
    }
  }
}
