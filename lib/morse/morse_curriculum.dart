import 'package:morse_bunker/morse/morse_table.dart';
import 'package:morse_bunker/morse/morse_timing.dart';

/// A single structured learning stage from basic rhythm to applied military dispatches.
class MorseCurriculumStage {
  const MorseCurriculumStage({
    required this.id,
    required this.stageNumber,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.items,
    required this.practicePhrase,
    required this.keyTip,
    this.mode = MorseLanguageMode.romanized,
  });

  final String id;
  final int stageNumber;
  final String title;
  final String subtitle;
  final String description;
  final List<String> items;
  final String practicePhrase;
  final String keyTip;
  final MorseLanguageMode mode;
}

const List<MorseCurriculumStage> kMorseCurriculumStages = [
  MorseCurriculumStage(
    id: 'stage_1_rhythm',
    stageNumber: 1,
    title: '1단계 · 기초 리듬과 1:3 법칙',
    subtitle: '단음(·)과 장음(−), 그리고 1-3-7 공백 규칙',
    description:
        '모스부호는 길고 짧음의 비율이 생명입니다. 단음(Dit)이 1단위일 때 장음(Dah)은 정확히 3배 길이로 누릅니다. 같은 글자 안의 쉼은 1단위, 글자 사이는 3단위, 단어 사이는 7단위를 쉽니다.',
    items: ['E', 'T', 'I', 'M'],
    practicePhrase: 'ET IM',
    keyTip: '짧은 탭은 "딧", 3배 길게 누르는 건 "다-" 리듬으로 기억하세요.',
  ),
  MorseCurriculumStage(
    id: 'stage_2_basic_letters',
    stageNumber: 2,
    title: '2단계 · 초급 알파벳 마스터',
    subtitle: '1~2타 기초 알파벳 (E, T, I, A, N, M)',
    description:
        '가장 빈도가 높은 6개 알파벳입니다. 한 번 또는 두 번의 타건만으로 구성되어 있어 첫 수신·송신 감각을 익히기에 좋습니다.',
    items: ['E', 'T', 'I', 'A', 'N', 'M'],
    practicePhrase: 'TEAM MAN',
    keyTip: 'A(·−)와 N(−·)은 서로 반대 대칭입니다.',
  ),
  MorseCurriculumStage(
    id: 'stage_3_pattern_letters',
    stageNumber: 3,
    title: '3단계 · 패턴별 알파벳 응용',
    subtitle: '3~4타 대칭 및 리듬군 (S, O, R, K, D, U, W, G, H, V)',
    description:
        '단음/장음 개수로 묶어 익히면 26자를 빠르게 암기할 수 있습니다. S(···)와 O(−−−), K(−·−)와 R(·−·)처럼 거울 대칭 구조를 함께 연습하세요.',
    items: ['S', 'O', 'R', 'K', 'D', 'U', 'W', 'G', 'H', 'V'],
    practicePhrase: 'ROGER OK',
    keyTip: 'V(···−)는 베토벤 운명 교향곡 "빠바바밤" 리듬과 같습니다.',
  ),
  MorseCurriculumStage(
    id: 'stage_4_digits',
    stageNumber: 4,
    title: '4단계 · 전술 숫자 코드 (0–9)',
    subtitle: '좌표·주파수 보고용 5요소 회전 패턴',
    description:
        '모든 숫자는 정확히 5개의 부호로 이루어집니다. 1~5는 앞쪽이 단음(·)으로 늘어나고, 6~0은 앞쪽이 장음(−)으로 채워지는 규칙적인 구조입니다.',
    items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    practicePhrase: 'GRID 4829',
    keyTip: '5는 ·····, 0은 −−−−−! 1~4와 6~9는 서로 정반대입니다.',
  ),
  MorseCurriculumStage(
    id: 'stage_5_prosigns',
    stageNumber: 5,
    title: '5단계 · 비상·군사 통신 프로사인',
    subtitle: 'SOS, CQ, QTH, ROGER, K, AR 실무 부호',
    description:
        '군사·해상 무선에서 교신 시작(CQ), 응답 요청(K), 수신 확인(R/ROGER), 조난(SOS), 전문 종료(AR)를 빠르게 전달하는 표준 약어입니다.',
    items: ['SOS', 'CQ', 'K', 'R', 'QTH', 'ROGER'],
    practicePhrase: 'CQ CQ K',
    keyTip: 'SOS(···−−−···)는 글자 간 공백 없이 하나의 연속 리듬으로 송신합니다.',
  ),
  MorseCurriculumStage(
    id: 'stage_6_applied',
    stageNumber: 6,
    title: '6단계 · 실전 지하 벙커 작전 전문',
    subtitle: '영문 전술 문장 & 한글 표준 전신부호(SKATS)',
    description:
        '실제 야전 통신병처럼 전체 문장과 한글 자모 분해 부호(SKATS)를 송신해봅니다. "변환·가이드" 탭에서는 원하는 어떤 문장이든 타건법으로 분해해 연습할 수 있습니다.',
    items: ['SOS', 'ALPHA', 'BASE', '구조', '작전'],
    practicePhrase: '구조 요청',
    keyTip: '한글은 초성·중성·종성을 자모 단위로 분리해 차례로 송신합니다.',
    mode: MorseLanguageMode.koreanSkats,
  ),
];

/// Interactive guided tap-along state that verifies each user dit/dah press.
class GuidedPracticeState {
  GuidedPracticeState({
    required this.targetText,
    required this.mode,
    required this.timing,
  }) : plan = buildMorseTransmissionPlan(
          targetText,
          mode: mode,
          timing: timing,
        ) {
    _advancePastWordSpaces();
  }

  final String targetText;
  final MorseLanguageMode mode;
  final MorseTimingConfig timing;
  final MorseTransmissionPlan plan;

  int unitIndex = 0;
  int symbolIndex = 0;
  int correctCount = 0;
  int mistakeCount = 0;
  String lastFeedback = '전건(Space 또는 3D 전건)을 눌러 시작하세요.';
  bool lastWasSuccess = true;

  bool get isCompleted => unitIndex >= plan.units.length;

  MorseEncodedUnit? get currentUnit =>
      isCompleted ? null : plan.units[unitIndex];

  String? get expectedSymbol {
    final unit = currentUnit;
    if (unit == null || unit.isWordSpace) return null;
    if (symbolIndex >= unit.morse.length) return null;
    return unit.morse[symbolIndex];
  }

  int get totalSymbols {
    var total = 0;
    for (final u in plan.units) {
      if (!u.isWordSpace) total += u.morse.length;
    }
    return total;
  }

  double get progress =>
      totalSymbols == 0 ? 1.0 : (correctCount / totalSymbols).clamp(0.0, 1.0);

  double get accuracy {
    final attempts = correctCount + mistakeCount;
    if (attempts == 0) return 1.0;
    return correctCount / attempts;
  }

  /// Evaluates a single completed key press duration against [expectedSymbol].
  bool registerKeyPress(int durationMs) {
    final expected = expectedSymbol;
    if (expected == null) return false;

    final actual = durationMs >= timing.ditDahThresholdMs ? kDah : kDit;
    final matched = actual == expected;

    if (matched) {
      correctCount++;
      lastWasSuccess = true;
      final kind = actual == kDah ? '장음(−)' : '단음(·)';
      lastFeedback = '정확합니다! $kind (${durationMs}ms)';
      symbolIndex++;
      final unit = currentUnit!;
      if (symbolIndex >= unit.morse.length) {
        symbolIndex = 0;
        unitIndex++;
        _advancePastWordSpaces();
        if (isCompleted) {
          lastFeedback = '전문 송신 완료! 정확도 ${(accuracy * 100).round()}%';
        } else {
          lastFeedback =
              '${unit.displayChar} 완료! 다음: ${currentUnit!.displayChar}';
        }
      }
    } else {
      mistakeCount++;
      lastWasSuccess = false;
      final expectedLabel = expected == kDah
          ? '길게(−, ${timing.dahMs}ms 이상)'
          : '짧게(·, ${timing.ditMs}ms 내외)';
      lastFeedback =
          '타이밍 오차 (${durationMs}ms). $expectedLabel 눌러야 합니다.';
    }
    return matched;
  }

  void reset() {
    unitIndex = 0;
    symbolIndex = 0;
    correctCount = 0;
    mistakeCount = 0;
    lastWasSuccess = true;
    lastFeedback = '다시 시작합니다. 첫 부호를 입력하세요.';
    _advancePastWordSpaces();
  }

  void _advancePastWordSpaces() {
    while (unitIndex < plan.units.length && plan.units[unitIndex].isWordSpace) {
      unitIndex++;
    }
  }
}
