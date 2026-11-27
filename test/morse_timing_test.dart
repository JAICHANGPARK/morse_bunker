import 'package:flutter_test/flutter_test.dart';
import 'package:morse_bunker/morse/morse_curriculum.dart';
import 'package:morse_bunker/morse/morse_table.dart';
import 'package:morse_bunker/morse/morse_timing.dart';

void main() {
  group('MorseTiming & GuidedPracticeState', () {
    test('computes ITU unit durations at 12 WPM', () {
      const cfg = MorseTimingConfig(wpm: 12);
      expect(cfg.unitMs, 100);
      expect(cfg.ditMs, 100);
      expect(cfg.dahMs, 300);
      expect(cfg.intraCharGapMs, 100);
      expect(cfg.interCharGapMs, 300);
      expect(cfg.wordGapMs, 700);
      expect(cfg.ditDahThresholdMs, 200);
    });

    test('Farnsworth widens inter-char and word gaps while keeping dit/dah crisp', () {
      const cfg = MorseTimingConfig(wpm: 15, farnsworthEnabled: true);
      expect(cfg.ditMs, 80);
      expect(cfg.dahMs, 240);
      expect(cfg.interCharGapMs, greaterThan(cfg.dahMs));
      expect(cfg.wordGapMs, greaterThan(cfg.interCharGapMs));
    });

    test('builds step-by-step Korean keying guide for text', () {
      const cfg = MorseTimingConfig(wpm: 12);
      final plan = buildMorseTransmissionPlan(
        'A N',
        mode: MorseLanguageMode.romanized,
        timing: cfg,
      );

      expect(plan.formattedMorse, '·− / −·');
      expect(plan.guides.length, 3);
      expect(plan.guides[0].stepSummary, '짧게(100ms) → 100ms 쉼 → 길게(300ms)');
      expect(plan.guides[1].unit.isWordSpace, isTrue);
      expect(plan.guides[2].stepSummary, '길게(300ms) → 100ms 쉼 → 짧게(100ms)');
      // Total: A (100+100+300) + wordGap(700) + N (300+100+100) = 1700ms
      expect(plan.totalDurationMs, 1700);
    });

    test('GuidedPracticeState evaluates dit and dah key presses accurately', () {
      final practice = GuidedPracticeState(
        targetText: 'A',
        mode: MorseLanguageMode.romanized,
        timing: const MorseTimingConfig(wpm: 12),
      );

      expect(practice.expectedSymbol, '·');
      expect(practice.registerKeyPress(95), isTrue);
      expect(practice.expectedSymbol, '−');
      expect(practice.registerKeyPress(90), isFalse); // too short for dah
      expect(practice.expectedSymbol, '−');
      expect(practice.registerKeyPress(280), isTrue);
      expect(practice.isCompleted, isTrue);
      expect(practice.correctCount, 2);
      expect(practice.mistakeCount, 1);
    });
  });
}
