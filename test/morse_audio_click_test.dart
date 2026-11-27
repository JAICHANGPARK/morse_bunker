import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:morse_bunker/audio/morse_audio_service.dart';

void main() {
  group('Mechanical Telegraph Click WAV Synthesis', () {
    test('produces valid RIFF/WAVE 16-bit PCM buffers for down and up clicks', () {
      final downWav = synthesizeMechanicalClickWav(isDown: true);
      final upWav = synthesizeMechanicalClickWav(isDown: false);

      expect(String.fromCharCodes(downWav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(downWav.sublist(8, 12)), 'WAVE');
      expect(String.fromCharCodes(upWav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(upWav.sublist(8, 12)), 'WAVE');

      expect(downWav.length, greaterThan(44));
      expect(upWav.length, greaterThan(44));

      // Verify non-silent audio payload
      final view = ByteData.sublistView(downWav);
      var peak = 0;
      for (var i = 44; i + 1 < downWav.length; i += 2) {
        final s = view.getInt16(i, Endian.little).abs();
        if (s > peak) peak = s;
      }
      expect(peak, greaterThan(5000));
    });
  });
}
