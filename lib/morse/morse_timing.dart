import 'package:morse_bunker/morse/morse_table.dart';

/// Timing parameters derived from WPM and optional Farnsworth spacing.
class MorseTimingConfig {
  const MorseTimingConfig({
    this.wpm = 12,
    this.farnsworthEnabled = false,
    this.farnsworthGapScale = 1.65,
  });

  /// Words per minute (standard PARIS benchmark: 50 units per word).
  final int wpm;

  /// When true, keeps individual dit/dah crisp at [wpm] while widening gaps
  /// between characters and words so beginners have thinking time.
  final bool farnsworthEnabled;

  /// Multiplier applied to inter-character and word gaps in Farnsworth mode.
  final double farnsworthGapScale;

  /// Base unit duration in milliseconds: `1200 / wpm` (e.g. 12 WPM = 100 ms).
  int get unitMs => (1200 / wpm.clamp(5, 30)).round();

  /// Short signal (`·`) = 1 unit.
  int get ditMs => unitMs;

  /// Long signal (`−`) = 3 units.
  int get dahMs => unitMs * 3;

  /// Gap between symbols inside the same character = 1 unit.
  int get intraCharGapMs => unitMs;

  /// Gap between characters = 3 units (widened in Farnsworth mode).
  int get interCharGapMs => farnsworthEnabled
      ? (unitMs * 3 * farnsworthGapScale).round()
      : unitMs * 3;

  /// Gap between words = 7 units (widened in Farnsworth mode).
  int get wordGapMs => farnsworthEnabled
      ? (unitMs * 7 * farnsworthGapScale).round()
      : unitMs * 7;

  /// Manual keying classification threshold between dit (`·`) and dah (`−`).
  int get ditDahThresholdMs => (unitMs * 2.0).round();

  /// Idle silence after key-up before committing the buffered Morse character.
  int get charCommitGapMs => (interCharGapMs * 0.92).round();

  /// Idle silence after key-up before inserting a word space.
  int get wordSpaceGapMs => (wordGapMs * 0.9).round();

  MorseTimingConfig copyWith({
    int? wpm,
    bool? farnsworthEnabled,
    double? farnsworthGapScale,
  }) {
    return MorseTimingConfig(
      wpm: wpm ?? this.wpm,
      farnsworthEnabled: farnsworthEnabled ?? this.farnsworthEnabled,
      farnsworthGapScale: farnsworthGapScale ?? this.farnsworthGapScale,
    );
  }
}

/// A single ON/OFF segment in a Morse playback timeline.
class MorseSignalEvent {
  const MorseSignalEvent({
    required this.isOn,
    required this.durationMs,
    required this.charIndex,
    required this.symbolIndex,
    required this.symbol,
    required this.label,
  });

  final bool isOn;
  final int durationMs;
  final int charIndex;
  final int symbolIndex;
  final String symbol;
  final String label;
}

/// Step-by-step Korean keying instruction for a single character/jamo.
class MorseCharacterGuide {
  const MorseCharacterGuide({
    required this.charIndex,
    required this.unit,
    required this.steps,
    required this.trailingPauseLabel,
    required this.trailingPauseMs,
    required this.totalDurationMs,
  });

  final int charIndex;
  final MorseEncodedUnit unit;
  final List<String> steps;
  final String trailingPauseLabel;
  final int trailingPauseMs;
  final int totalDurationMs;

  String get stepSummary => steps.join(' → ');
}

/// Complete encoding + timeline + Korean keying guide for a user's text input.
class MorseTransmissionPlan {
  const MorseTransmissionPlan({
    required this.sourceText,
    required this.mode,
    required this.timing,
    required this.units,
    required this.guides,
    required this.events,
    required this.formattedMorse,
    required this.totalDurationMs,
  });

  final String sourceText;
  final MorseLanguageMode mode;
  final MorseTimingConfig timing;
  final List<MorseEncodedUnit> units;
  final List<MorseCharacterGuide> guides;
  final List<MorseSignalEvent> events;
  final String formattedMorse;
  final int totalDurationMs;
}

/// Builds a complete timeline and human-readable Korean keying breakdown.
MorseTransmissionPlan buildMorseTransmissionPlan(
  String text, {
  required MorseLanguageMode mode,
  required MorseTimingConfig timing,
}) {
  final units = encodeTextToUnits(text, mode: mode);
  final guides = <MorseCharacterGuide>[];
  final events = <MorseSignalEvent>[];
  var totalMs = 0;

  for (var i = 0; i < units.length; i++) {
    final unit = units[i];
    final nextUnit = i + 1 < units.length ? units[i + 1] : null;

    if (unit.isWordSpace) {
      guides.add(
        MorseCharacterGuide(
          charIndex: i,
          unit: unit,
          steps: const ['단어 사이 공백'],
          trailingPauseLabel: '${timing.wordGapMs}ms 대기 (7단위)',
          trailingPauseMs: timing.wordGapMs,
          totalDurationMs: timing.wordGapMs,
        ),
      );
      events.add(
        MorseSignalEvent(
          isOn: false,
          durationMs: timing.wordGapMs,
          charIndex: i,
          symbolIndex: -1,
          symbol: '/',
          label: '단어 간격 (${timing.wordGapMs}ms)',
        ),
      );
      totalMs += timing.wordGapMs;
      continue;
    }

    final steps = <String>[];
    var charMs = 0;
    final symbols = unit.morse.split('');
    for (var s = 0; s < symbols.length; s++) {
      final sym = symbols[s];
      final isDah = sym == kDah;
      final onMs = isDah ? timing.dahMs : timing.ditMs;
      steps.add(isDah ? '길게(${onMs}ms)' : '짧게(${onMs}ms)');
      events.add(
        MorseSignalEvent(
          isOn: true,
          durationMs: onMs,
          charIndex: i,
          symbolIndex: s,
          symbol: sym,
          label: isDah ? '장음 − (${onMs}ms)' : '단음 · (${onMs}ms)',
        ),
      );
      charMs += onMs;
      totalMs += onMs;

      if (s < symbols.length - 1) {
        steps.add('${timing.intraCharGapMs}ms 쉼');
        events.add(
          MorseSignalEvent(
            isOn: false,
            durationMs: timing.intraCharGapMs,
            charIndex: i,
            symbolIndex: s,
            symbol: ' ',
            label: '부호 간격 (${timing.intraCharGapMs}ms)',
          ),
        );
        charMs += timing.intraCharGapMs;
        totalMs += timing.intraCharGapMs;
      }
    }

    var trailingMs = 0;
    var trailingLabel = '송신 완료';
    if (nextUnit != null && !nextUnit.isWordSpace) {
      trailingMs = timing.interCharGapMs;
      trailingLabel = '다음 글자 전 ${trailingMs}ms 대기 (3단위)';
      events.add(
        MorseSignalEvent(
          isOn: false,
          durationMs: trailingMs,
          charIndex: i,
          symbolIndex: symbols.length,
          symbol: '  ',
          label: '문자 간격 (${trailingMs}ms)',
        ),
      );
      totalMs += trailingMs;
    }

    guides.add(
      MorseCharacterGuide(
        charIndex: i,
        unit: unit,
        steps: steps,
        trailingPauseLabel: trailingLabel,
        trailingPauseMs: trailingMs,
        totalDurationMs: charMs,
      ),
    );
  }

  return MorseTransmissionPlan(
    sourceText: text,
    mode: mode,
    timing: timing,
    units: units,
    guides: guides,
    events: events,
    formattedMorse: formatMorseUnits(units),
    totalDurationMs: totalMs,
  );
}
