import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:morse_bunker/morse/morse_acoustic_decoder.dart';
import 'package:morse_bunker/morse/morse_table.dart';
import 'package:morse_bunker/morse/morse_timing.dart';

Uint8List _appendToneAndSilence({
  required List<({bool on, int ms})> segments,
  int sampleRate = 16000,
  double freqHz = 700.0,
  double amplitude = 0.5,
}) {
  final builder = BytesBuilder(copy: false);
  var sampleIndex = 0;
  for (final seg in segments) {
    final count = (sampleRate * seg.ms) ~/ 1000;
    final chunk = Uint8List(count * 2);
    final view = ByteData.view(chunk.buffer);
    for (var i = 0; i < count; i++) {
      final t = (sampleIndex + i) / sampleRate;
      final val = seg.on
          ? (math.sin(2.0 * math.pi * freqHz * t) * amplitude * 32767)
              .round()
              .clamp(-32768, 32767)
          : 0;
      view.setInt16(i * 2, val, Endian.little);
    }
    sampleIndex += count;
    builder.add(chunk);
  }
  return builder.toBytes();
}

void main() {
  group('MorseAcousticDecoder & PCM Resampler', () {
    test('detects 700 Hz CW tone and decodes SOS accurately', () {
      const timing = MorseTimingConfig(wpm: 12); // dit=100, dah=300, charGap=300
      final decoder = MorseAcousticDecoder(
        sampleRate: 16000,
        mode: AcousticListenMode.cwTone,
        timing: timing,
        languageMode: MorseLanguageMode.romanized,
        sensitivity: 0.65,
      );

      final pcm = _appendToneAndSilence(
        freqHz: 700.0,
        segments: [
          (on: false, ms: 80),
          // S: · · ·
          (on: true, ms: 100), (on: false, ms: 100),
          (on: true, ms: 100), (on: false, ms: 100),
          (on: true, ms: 100), (on: false, ms: 340),
          // O: − − −
          (on: true, ms: 300), (on: false, ms: 100),
          (on: true, ms: 300), (on: false, ms: 100),
          (on: true, ms: 300), (on: false, ms: 340),
          // S: · · ·
          (on: true, ms: 100), (on: false, ms: 100),
          (on: true, ms: 100), (on: false, ms: 100),
          (on: true, ms: 100), (on: false, ms: 380),
        ],
      );

      // Feed in realistic 512-byte chunks
      const chunkBytes = 512;
      for (var offset = 0; offset < pcm.length; offset += chunkBytes) {
        final end = math.min(offset + chunkBytes, pcm.length);
        decoder.processPcm16(Uint8List.sublistView(pcm, offset, end));
      }
      decoder.flushSilence(400);

      expect(decoder.detectedFrequencyHz, closeTo(700.0, 60.0));
      expect(decoder.decodedText.trim(), 'SOS');
    });

    test('resamples 48 kHz PCM16 mono down to 16 kHz', () {
      final pcm48k = _appendToneAndSilence(
        sampleRate: 48000,
        segments: [(on: true, ms: 100)],
      );
      final pcm16k = resamplePcm16Mono(pcm48k, 48000, 16000);
      expect(pcm16k.lengthInBytes, pcm48k.lengthInBytes ~/ 3);
    });
  });
}
