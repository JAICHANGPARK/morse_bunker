import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Synthesizes a short 16-bit mono PCM WAV buffer simulating the metallic
/// brass-on-brass contact strike ([isDown] = true) or spring-return snap
/// ([isDown] = false) of a physical J-38 military telegraph key.
Uint8List synthesizeMechanicalClickWav({
  required bool isDown,
  int sampleRate = 22050,
}) {
  final durationMs = isDown ? 18 : 14;
  final numSamples = (sampleRate * durationMs) ~/ 1000;
  final dataSize = numSamples * 2;
  final byteRate = sampleRate * 2;
  final totalSize = 44 + dataSize;
  final bytes = Uint8List(totalSize);
  final view = ByteData.view(bytes.buffer);

  // RIFF header
  view.setUint8(0, 0x52); // 'R'
  view.setUint8(1, 0x49); // 'I'
  view.setUint8(2, 0x46); // 'F'
  view.setUint8(3, 0x46); // 'F'
  view.setUint32(4, 36 + dataSize, Endian.little);
  view.setUint8(8, 0x57); // 'W'
  view.setUint8(9, 0x41); // 'A'
  view.setUint8(10, 0x56); // 'V'
  view.setUint8(11, 0x45); // 'E'

  // fmt chunk
  view.setUint8(12, 0x66); // 'f'
  view.setUint8(13, 0x6D); // 'm'
  view.setUint8(14, 0x74); // 't'
  view.setUint8(15, 0x20); // ' '
  view.setUint32(16, 16, Endian.little);
  view.setUint16(20, 1, Endian.little); // PCM
  view.setUint16(22, 1, Endian.little); // Mono
  view.setUint32(24, sampleRate, Endian.little);
  view.setUint32(28, byteRate, Endian.little);
  view.setUint16(32, 2, Endian.little);
  view.setUint16(34, 16, Endian.little);

  // data chunk
  view.setUint8(36, 0x64); // 'd'
  view.setUint8(37, 0x61); // 'a'
  view.setUint8(38, 0x74); // 't'
  view.setUint8(39, 0x61); // 'a'
  view.setUint32(40, dataSize, Endian.little);

  final rng = math.Random(isDown ? 38 : 79);
  final f1 = isDown ? 2600.0 : 1900.0;
  final f2 = isDown ? 4150.0 : 3100.0;
  final decayRate = isDown ? 280.0 : 340.0;

  for (var i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final env = math.exp(-t * decayRate);
    final noise = (rng.nextDouble() * 2.0 - 1.0) * 0.28;
    final metallic =
        0.58 * math.sin(2.0 * math.pi * f1 * t) +
        0.34 * math.sin(2.0 * math.pi * f2 * t);
    final thud = isDown ? 0.30 * math.sin(2.0 * math.pi * 240.0 * t) : 0.0;
    final sample = ((metallic + thud + noise) * env).clamp(-1.0, 1.0);
    view.setInt16(44 + i * 2, (sample * 32767).round(), Endian.little);
  }
  return bytes;
}

/// Low-latency CW Morse tone, mechanical key click/clack, & bunker hum generator.
class MorseAudioService {
  Future<void>? _initFuture;
  bool _available = false;
  double _frequencyHz = 680.0;
  bool _lastKeyDown = false;

  AudioSource? _toneSource;
  SoundHandle? _toneHandle;

  AudioSource? _humSource;
  SoundHandle? _humHandle;
  bool _humEnabled = false;

  AudioSource? _keyDownClickSource;
  AudioSource? _keyUpClickSource;

  bool get isAvailable => _available;

  /// Initializes the SoLoud audio engine safely (supports lazy gesture-unlock on Web).
  Future<void> init({double frequencyHz = 680.0}) {
    _frequencyHz = frequencyHz;
    if (_available) return Future.value();
    return _initFuture ??= _doInit();
  }

  /// Ensures SoLoud is ready before playback on Web or native.
  Future<void> ensureReady({double? frequencyHz}) =>
      init(frequencyHz: frequencyHz ?? _frequencyHz);

  Future<void> _doInit() async {
    try {
      final soloud = SoLoud.instance;
      if (!soloud.isInitialized) {
        await soloud.init(lowLatency: true);
      }

      _toneSource = await soloud.loadWaveform(WaveForm.sin, false, 1.0, 0.0);
      soloud.setWaveformFreq(_toneSource!, _frequencyHz);
      _toneHandle = soloud.play(
        _toneSource!,
        volume: 0.0,
        looping: true,
      );

      _humSource = await soloud.loadWaveform(WaveForm.triangle, false, 1.0, 0.0);
      soloud.setWaveformFreq(_humSource!, 62.0);
      _humHandle = soloud.play(
        _humSource!,
        volume: _humEnabled ? 0.03 : 0.0,
        looping: true,
      );

      _keyDownClickSource = await soloud.loadMem(
        'key_down.wav',
        synthesizeMechanicalClickWav(isDown: true),
      );
      _keyUpClickSource = await soloud.loadMem(
        'key_up.wav',
        synthesizeMechanicalClickWav(isDown: false),
      );

      _available = true;
    } catch (e) {
      debugPrint('MorseAudioService init skipped/unavailable: $e');
      _available = false;
      _initFuture = null; // Allow retry after a user gesture on Web.
    }
  }

  /// Ramps CW tone volume smoothly and triggers mechanical key click/release clack.
  void setKeyDown(bool down) {
    if (!_available || _toneHandle == null) {
      _lastKeyDown = down;
      return;
    }
    try {
      if (down != _lastKeyDown) {
        _lastKeyDown = down;
        final clickSource = down ? _keyDownClickSource : _keyUpClickSource;
        if (clickSource != null) {
          SoLoud.instance.play(
            clickSource,
            volume: down ? 0.52 : 0.32,
          );
        }
      }
      SoLoud.instance.fadeVolume(
        _toneHandle!,
        down ? 0.62 : 0.0,
        Duration(milliseconds: down ? 5 : 8),
      );
    } catch (_) {
      // Ignore if handle became invalid during teardown.
    }
  }

  /// Updates the CW sidetone pitch (Hz).
  void setFrequency(double hz) {
    _frequencyHz = hz;
    if (!_available || _toneSource == null) return;
    try {
      SoLoud.instance.setWaveformFreq(_toneSource!, hz);
    } catch (_) {}
  }

  /// Toggles subtle 62 Hz military bunker transformer / vacuum-tube hum.
  void setAmbientHum(bool enabled) {
    _humEnabled = enabled;
    if (!_available || _humHandle == null) return;
    try {
      SoLoud.instance.fadeVolume(
        _humHandle!,
        enabled ? 0.032 : 0.0,
        const Duration(milliseconds: 220),
      );
    } catch (_) {}
  }

  Future<void> dispose() async {
    if (!_available) return;
    _available = false;
    try {
      final soloud = SoLoud.instance;
      if (_toneHandle != null) {
        await soloud.stop(_toneHandle!);
      }
      if (_humHandle != null) {
        await soloud.stop(_humHandle!);
      }
      if (_toneSource != null) {
        await soloud.disposeSource(_toneSource!);
      }
      if (_humSource != null) {
        await soloud.disposeSource(_humSource!);
      }
      if (_keyDownClickSource != null) {
        await soloud.disposeSource(_keyDownClickSource!);
      }
      if (_keyUpClickSource != null) {
        await soloud.disposeSource(_keyUpClickSource!);
      }
    } catch (_) {}
  }
}
