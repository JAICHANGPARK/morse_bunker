import 'package:flutter_test/flutter_test.dart';
import 'package:morse_bunker/morse/morse_table.dart';

void main() {
  group('MorseTable Codec', () {
    test('encodes Latin SOS and digits accurately', () {
      expect(
        encodeTextToMorse('SOS', mode: MorseLanguageMode.romanized),
        '··· −−− ···',
      );
      expect(
        encodeTextToMorse('HELLO 09', mode: MorseLanguageMode.romanized),
        '···· · ·−·· ·−·· −−− / −−−−− −−−−·',
      );
    });

    test('decodes Morse sequence back to Latin text', () {
      expect(
        decodeMorseSequence('... --- ... / .-. --- --. . .-.', preferLatin: true),
        'SOS ROGER',
      );
    });

    test('decomposes Hangul syllables into SKATS Jamos and encodes', () {
      final jamos = decomposeHangulToSkatsJamos('한');
      expect(jamos, ['ㅎ', 'ㅏ', 'ㄴ']);
      expect(
        encodeTextToMorse('한', mode: MorseLanguageMode.koreanSkats),
        '·−−− · ··−·',
      );

      // Compound vowel & tense consonant decomposition
      expect(decomposeHangulToSkatsJamos('꽈'), ['ㄱ', 'ㄱ', 'ㅗ', 'ㅏ']);
      expect(decomposeHangulToSkatsJamos('값'), ['ㄱ', 'ㅏ', 'ㅂ', 'ㅅ']);
    });

    test('supports Romanized mode for Korean text', () {
      expect(romanizeHangulChar('가'), 'GA');
      expect(
        encodeTextToMorse('가', mode: MorseLanguageMode.romanized),
        '−−· ·−',
      );
    });
  });
}
