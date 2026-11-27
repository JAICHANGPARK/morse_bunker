/// International ITU Morse code & Korean SKATS (한글 표준 전신부호) codec.
library;

/// How Korean text is converted into Morse code.
enum MorseLanguageMode {
  /// Official Korean Hangul Morse (SKATS / 한국 표준 전신부호).
  koreanSkats('한글 표준 (SKATS)'),

  /// Converts Hangul syllables into Revised Romanization letters first.
  romanized('로마자 변환');

  const MorseLanguageMode(this.label);
  final String label;
}

/// Category of a Morse code entry in reference tables.
enum MorseCategory {
  alphabet('알파벳 A-Z'),
  digit('숫자 0-9'),
  hangul('한글 SKATS'),
  prosign('군사·비상 약어'),
  punctuation('문장부호');

  const MorseCategory(this.label);
  final String label;
}

/// Reference metadata for a single Morse code symbol or prosign.
class MorseEntry {
  const MorseEntry({
    required this.symbol,
    required this.morse,
    required this.category,
    required this.mnemonic,
    this.meaning,
  });

  final String symbol;
  final String morse;
  final MorseCategory category;
  final String mnemonic;
  final String? meaning;
}

/// Encoded representation of a single transmittable unit (character, jamo, or space).
class MorseEncodedUnit {
  const MorseEncodedUnit({
    required this.displayChar,
    required this.transmittedChar,
    required this.morse,
    required this.isWordSpace,
    this.sourceHangul,
  });

  /// Original display character (or decomposed Jamo for Hangul).
  final String displayChar;

  /// Character actually looked up in the Morse table.
  final String transmittedChar;

  /// Sequence of `·` and `−` (empty when [isWordSpace] is true).
  final String morse;

  /// Whether this unit represents a word boundary (`/`).
  final bool isWordSpace;

  /// Original Hangul syllable if decomposed from one.
  final String? sourceHangul;
}

/// Standard dot and dash characters used throughout the app.
const String kDit = '·';
const String kDah = '−';

/// Normalizes ASCII `.` / `-` / `_` into display `·` / `−`.
String normalizeMorseSymbols(String raw) {
  return raw
      .replaceAll('.', kDit)
      .replaceAll('-', kDah)
      .replaceAll('_', kDah);
}

/// All A-Z entries with Korean rhythmic mnemonics.
const List<MorseEntry> kAlphabetEntries = [
  MorseEntry(symbol: 'A', morse: '·−', category: MorseCategory.alphabet, mnemonic: '아-빠 (짧고 길게)'),
  MorseEntry(symbol: 'B', morse: '−···', category: MorseCategory.alphabet, mnemonic: '바-나-나-칩'),
  MorseEntry(symbol: 'C', morse: '−·−·', category: MorseCategory.alphabet, mnemonic: '코-카-콜-라'),
  MorseEntry(symbol: 'D', morse: '−··', category: MorseCategory.alphabet, mnemonic: '도-미-노'),
  MorseEntry(symbol: 'E', morse: '·', category: MorseCategory.alphabet, mnemonic: '엣 (가장 짧은 1회)'),
  MorseEntry(symbol: 'F', morse: '··−·', category: MorseCategory.alphabet, mnemonic: '따-따-타-따'),
  MorseEntry(symbol: 'G', morse: '−−·', category: MorseCategory.alphabet, mnemonic: '공-장-장 (길-길-짧)'),
  MorseEntry(symbol: 'H', morse: '····', category: MorseCategory.alphabet, mnemonic: '하-하-하-하 (4연타)'),
  MorseEntry(symbol: 'I', morse: '··', category: MorseCategory.alphabet, mnemonic: '이-잇 (짧게 2회)'),
  MorseEntry(symbol: 'J', morse: '·−−−', category: MorseCategory.alphabet, mnemonic: '제-트-기-출-동'),
  MorseEntry(symbol: 'K', morse: '−·−', category: MorseCategory.alphabet, mnemonic: '킹-콩-킹 (교신 개시)'),
  MorseEntry(symbol: 'L', morse: '·−··', category: MorseCategory.alphabet, mnemonic: '라-일-락-꽃'),
  MorseEntry(symbol: 'M', morse: '−−', category: MorseCategory.alphabet, mnemonic: '맘-마 (길게 2회)'),
  MorseEntry(symbol: 'N', morse: '−·', category: MorseCategory.alphabet, mnemonic: '나-비 (길고 짧게)'),
  MorseEntry(symbol: 'O', morse: '−−−', category: MorseCategory.alphabet, mnemonic: '오-오-오 (길게 3회)'),
  MorseEntry(symbol: 'P', morse: '·−−·', category: MorseCategory.alphabet, mnemonic: '파-인-애-플'),
  MorseEntry(symbol: 'Q', morse: '−−·−', category: MorseCategory.alphabet, mnemonic: '퀸-카-가-다'),
  MorseEntry(symbol: 'R', morse: '·−·', category: MorseCategory.alphabet, mnemonic: '로-저-댓 (수신 확인)'),
  MorseEntry(symbol: 'S', morse: '···', category: MorseCategory.alphabet, mnemonic: '쓰-리-샷 (짧게 3회)'),
  MorseEntry(symbol: 'T', morse: '−', category: MorseCategory.alphabet, mnemonic: '타- (가장 짧은 길게 1회)'),
  MorseEntry(symbol: 'U', morse: '··−', category: MorseCategory.alphabet, mnemonic: '유-턴-업'),
  MorseEntry(symbol: 'V', morse: '···−', category: MorseCategory.alphabet, mnemonic: '빠-바-바-밤 (베토벤 5번)'),
  MorseEntry(symbol: 'W', morse: '·−−', category: MorseCategory.alphabet, mnemonic: '워-터-파크'),
  MorseEntry(symbol: 'X', morse: '−··−', category: MorseCategory.alphabet, mnemonic: '엑-스-레-이'),
  MorseEntry(symbol: 'Y', morse: '−·−−', category: MorseCategory.alphabet, mnemonic: '요-트-타-자'),
  MorseEntry(symbol: 'Z', morse: '−−··', category: MorseCategory.alphabet, mnemonic: '지-브-라-줄'),
];

/// 0-9 entries showing the 5-element rolling symmetry.
const List<MorseEntry> kDigitEntries = [
  MorseEntry(symbol: '1', morse: '·−−−−', category: MorseCategory.digit, mnemonic: '짧1 + 길4'),
  MorseEntry(symbol: '2', morse: '··−−−', category: MorseCategory.digit, mnemonic: '짧2 + 길3'),
  MorseEntry(symbol: '3', morse: '···−−', category: MorseCategory.digit, mnemonic: '짧3 + 길2'),
  MorseEntry(symbol: '4', morse: '····−', category: MorseCategory.digit, mnemonic: '짧4 + 길1'),
  MorseEntry(symbol: '5', morse: '·····', category: MorseCategory.digit, mnemonic: '짧5 (연속 5타)'),
  MorseEntry(symbol: '6', morse: '−····', category: MorseCategory.digit, mnemonic: '길1 + 짧4'),
  MorseEntry(symbol: '7', morse: '−−···', category: MorseCategory.digit, mnemonic: '길2 + 짧3'),
  MorseEntry(symbol: '8', morse: '−−−··', category: MorseCategory.digit, mnemonic: '길3 + 짧2'),
  MorseEntry(symbol: '9', morse: '−−−−·', category: MorseCategory.digit, mnemonic: '길4 + 짧1'),
  MorseEntry(symbol: '0', morse: '−−−−−', category: MorseCategory.digit, mnemonic: '길5 (장음 5회)'),
];

/// Official Korean Hangul Morse (SKATS) basic Jamo entries.
const List<MorseEntry> kHangulEntries = [
  MorseEntry(symbol: 'ㄱ', morse: '·−··', category: MorseCategory.hangul, mnemonic: '기역 (라일락)'),
  MorseEntry(symbol: 'ㄴ', morse: '··−·', category: MorseCategory.hangul, mnemonic: '니은'),
  MorseEntry(symbol: 'ㄷ', morse: '−···', category: MorseCategory.hangul, mnemonic: '디귿'),
  MorseEntry(symbol: 'ㄹ', morse: '···−', category: MorseCategory.hangul, mnemonic: '리을'),
  MorseEntry(symbol: 'ㅁ', morse: '−−', category: MorseCategory.hangul, mnemonic: '미음 (장음 2)'),
  MorseEntry(symbol: 'ㅂ', morse: '·−−', category: MorseCategory.hangul, mnemonic: '비읍'),
  MorseEntry(symbol: 'ㅅ', morse: '−−·', category: MorseCategory.hangul, mnemonic: '시옷'),
  MorseEntry(symbol: 'ㅇ', morse: '−·−', category: MorseCategory.hangul, mnemonic: '이응'),
  MorseEntry(symbol: 'ㅈ', morse: '·−−·', category: MorseCategory.hangul, mnemonic: '지읒'),
  MorseEntry(symbol: 'ㅊ', morse: '−·−·', category: MorseCategory.hangul, mnemonic: '치읓'),
  MorseEntry(symbol: 'ㅋ', morse: '−··−', category: MorseCategory.hangul, mnemonic: '키읔'),
  MorseEntry(symbol: 'ㅌ', morse: '−−··', category: MorseCategory.hangul, mnemonic: '티읕'),
  MorseEntry(symbol: 'ㅍ', morse: '−−−', category: MorseCategory.hangul, mnemonic: '피읖 (장음 3)'),
  MorseEntry(symbol: 'ㅎ', morse: '·−−−', category: MorseCategory.hangul, mnemonic: '히읗'),
  MorseEntry(symbol: 'ㅏ', morse: '·', category: MorseCategory.hangul, mnemonic: '아 (단음 1)'),
  MorseEntry(symbol: 'ㅑ', morse: '··', category: MorseCategory.hangul, mnemonic: '야 (단음 2)'),
  MorseEntry(symbol: 'ㅓ', morse: '−', category: MorseCategory.hangul, mnemonic: '어 (장음 1)'),
  MorseEntry(symbol: 'ㅕ', morse: '···', category: MorseCategory.hangul, mnemonic: '여 (단음 3)'),
  MorseEntry(symbol: 'ㅗ', morse: '·−', category: MorseCategory.hangul, mnemonic: '오'),
  MorseEntry(symbol: 'ㅛ', morse: '−·', category: MorseCategory.hangul, mnemonic: '요'),
  MorseEntry(symbol: 'ㅜ', morse: '····', category: MorseCategory.hangul, mnemonic: '우 (단음 4)'),
  MorseEntry(symbol: 'ㅠ', morse: '·−·', category: MorseCategory.hangul, mnemonic: '유'),
  MorseEntry(symbol: 'ㅡ', morse: '−··', category: MorseCategory.hangul, mnemonic: '으'),
  MorseEntry(symbol: 'ㅣ', morse: '··−', category: MorseCategory.hangul, mnemonic: '이'),
  MorseEntry(symbol: 'ㅐ', morse: '−−·−', category: MorseCategory.hangul, mnemonic: '애'),
  MorseEntry(symbol: 'ㅔ', morse: '−·−−', category: MorseCategory.hangul, mnemonic: '에'),
];

/// Military, maritime, and tactical prosigns & abbreviations.
const List<MorseEntry> kProsignEntries = [
  MorseEntry(
    symbol: 'SOS',
    morse: '···−−−···',
    category: MorseCategory.prosign,
    mnemonic: '연속 무간격 송신 (··· −−− ···)',
    meaning: '국제 조난·비상 구조 신호',
  ),
  MorseEntry(
    symbol: 'CQ',
    morse: '−·−· −−·−',
    category: MorseCategory.prosign,
    mnemonic: 'CQ 호출 (전 국 앞)',
    meaning: '모든 수신국 호출 (Seek You)',
  ),
  MorseEntry(
    symbol: 'K',
    morse: '−·−',
    category: MorseCategory.prosign,
    mnemonic: '응답 바람 (Over)',
    meaning: '송신 종료, 상대방 응답 대기',
  ),
  MorseEntry(
    symbol: 'R',
    morse: '·−·',
    category: MorseCategory.prosign,
    mnemonic: 'Roger (수신 양호)',
    meaning: '전문 완전 수신 확인',
  ),
  MorseEntry(
    symbol: 'AR',
    morse: '·−·−·',
    category: MorseCategory.prosign,
    mnemonic: '전문 끝 (연결 송신)',
    meaning: '메시지 끝 (End of Message)',
  ),
  MorseEntry(
    symbol: 'SK',
    morse: '···−·−',
    category: MorseCategory.prosign,
    mnemonic: '교신 완전 종료 (Out)',
    meaning: '통신 종료 (Silent Key / End of Contact)',
  ),
  MorseEntry(
    symbol: 'BT',
    morse: '−···−',
    category: MorseCategory.prosign,
    mnemonic: '단락 구분 (=)',
    meaning: '새 문단·구분선',
  ),
  MorseEntry(
    symbol: 'QTH',
    morse: '−−·− − ····',
    category: MorseCategory.prosign,
    mnemonic: '현재 위치 보고',
    meaning: '현재 위치/좌표는 어디인가?',
  ),
  MorseEntry(
    symbol: 'ROGER',
    morse: '·−· −−− −−· · ·−·',
    category: MorseCategory.prosign,
    mnemonic: '수신 완료 / 알겠음',
    meaning: '명령 또는 전문 수신 확인',
  ),
];

/// Common punctuation entries.
const List<MorseEntry> kPunctuationEntries = [
  MorseEntry(symbol: '.', morse: '·−·−·−', category: MorseCategory.punctuation, mnemonic: '마침표'),
  MorseEntry(symbol: ',', morse: '−−··−−', category: MorseCategory.punctuation, mnemonic: '쉼표'),
  MorseEntry(symbol: '?', morse: '··−−··', category: MorseCategory.punctuation, mnemonic: '물음표'),
  MorseEntry(symbol: '/', morse: '−··−·', category: MorseCategory.punctuation, mnemonic: '슬래시'),
  MorseEntry(symbol: '-', morse: '−····−', category: MorseCategory.punctuation, mnemonic: '하이픈'),
  MorseEntry(symbol: '!', morse: '−·−·−−', category: MorseCategory.punctuation, mnemonic: '느낌표'),
  MorseEntry(symbol: '@', morse: '·−−·−·', category: MorseCategory.punctuation, mnemonic: '골뱅이 (@)'),
];

/// Combined character -> Morse map for Latin, digits, and punctuation.
final Map<String, String> kLatinMorseMap = {
  for (final e in [...kAlphabetEntries, ...kDigitEntries, ...kPunctuationEntries])
    e.symbol: e.morse,
  '(': '−·−−·',
  ')': '−·−−·−',
  ':': '−−−···',
  '=': '−···−',
  '+': '·−·−·',
};

/// Combined Morse -> Latin character reverse lookup map.
final Map<String, String> kMorseToLatinMap = {
  for (final entry in kLatinMorseMap.entries) entry.value: entry.key,
};

/// Korean Jamo -> SKATS Morse lookup map.
final Map<String, String> kKoreanJamoMorseMap = {
  for (final e in kHangulEntries) e.symbol: e.morse,
};

/// Reverse SKATS Morse -> Korean Jamo map.
final Map<String, String> kMorseToKoreanJamoMap = {
  for (final e in kHangulEntries) e.morse: e.symbol,
};

/// Looks up [MorseEntry] metadata for any character or prosign if available.
final Map<String, MorseEntry> kMorseEntryBySymbol = {
  for (final e in [
    ...kAlphabetEntries,
    ...kDigitEntries,
    ...kHangulEntries,
    ...kProsignEntries,
    ...kPunctuationEntries,
  ])
    e.symbol: e,
};

// Hangul Jamo tables for Unicode decomposition (0xAC00..0xD7A3).
const List<String> _kChoseong = [
  'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ',
  'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
];

const List<String> _kJungseong = [
  'ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ',
  'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ',
  'ㅣ',
];

const List<String> _kJongseong = [
  '', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ',
  'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ',
  'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
];

const Map<String, List<String>> _kCompoundJamoSplit = {
  'ㄲ': ['ㄱ', 'ㄱ'],
  'ㄸ': ['ㄷ', 'ㄷ'],
  'ㅃ': ['ㅂ', 'ㅂ'],
  'ㅆ': ['ㅅ', 'ㅅ'],
  'ㅉ': ['ㅈ', 'ㅈ'],
  'ㅒ': ['ㅑ', 'ㅣ'],
  'ㅖ': ['ㅕ', 'ㅣ'],
  'ㅘ': ['ㅗ', 'ㅏ'],
  'ㅙ': ['ㅗ', 'ㅐ'],
  'ㅚ': ['ㅗ', 'ㅣ'],
  'ㅝ': ['ㅜ', 'ㅓ'],
  'ㅞ': ['ㅜ', 'ㅔ'],
  'ㅟ': ['ㅜ', 'ㅣ'],
  'ㅢ': ['ㅡ', 'ㅣ'],
  'ㄳ': ['ㄱ', 'ㅅ'],
  'ㄵ': ['ㄴ', 'ㅈ'],
  'ㄶ': ['ㄴ', 'ㅎ'],
  'ㄺ': ['ㄹ', 'ㄱ'],
  'ㄻ': ['ㄹ', 'ㅁ'],
  'ㄼ': ['ㄹ', 'ㅂ'],
  'ㄽ': ['ㄹ', 'ㅅ'],
  'ㄾ': ['ㄹ', 'ㅌ'],
  'ㄿ': ['ㄹ', 'ㅍ'],
  'ㅀ': ['ㄹ', 'ㅎ'],
  'ㅄ': ['ㅂ', 'ㅅ'],
};

const List<String> _kChoseongRoman = [
  'G', 'KK', 'N', 'D', 'TT', 'R', 'M', 'B', 'PP', 'S',
  'SS', '', 'J', 'JJ', 'CH', 'K', 'T', 'P', 'H',
];

const List<String> _kJungseongRoman = [
  'A', 'AE', 'YA', 'YAE', 'EO', 'E', 'YEO', 'YE', 'O', 'WA',
  'WAE', 'OE', 'YO', 'U', 'WO', 'WE', 'WI', 'YU', 'EU', 'UI',
  'I',
];

const List<String> _kJongseongRoman = [
  '', 'K', 'K', 'K', 'N', 'N', 'N', 'T', 'L', 'K',
  'M', 'L', 'L', 'L', 'P', 'L', 'M', 'P', 'P', 'T',
  'T', 'NG', 'T', 'T', 'K', 'T', 'P', 'T',
];

bool isHangulSyllable(int codeUnit) => codeUnit >= 0xAC00 && codeUnit <= 0xD7A3;

/// Decomposes a single Hangul syllable or compatibility Jamo into basic SKATS Jamos.
List<String> decomposeHangulToSkatsJamos(String ch) {
  if (ch.isEmpty) return const [];
  final code = ch.codeUnitAt(0);
  if (isHangulSyllable(code)) {
    final index = code - 0xAC00;
    final cho = index ~/ (21 * 28);
    final jung = (index % (21 * 28)) ~/ 28;
    final jong = index % 28;
    final raw = <String>[
      _kChoseong[cho],
      _kJungseong[jung],
      if (jong > 0) _kJongseong[jong],
    ];
    final result = <String>[];
    for (final jamo in raw) {
      final split = _kCompoundJamoSplit[jamo];
      if (split != null) {
        result.addAll(split);
      } else {
        result.add(jamo);
      }
    }
    return result;
  }
  final split = _kCompoundJamoSplit[ch];
  if (split != null) return split;
  if (kKoreanJamoMorseMap.containsKey(ch)) return [ch];
  return const [];
}

/// Converts a Hangul syllable into Revised Romanization uppercase letters.
String romanizeHangulChar(String ch) {
  if (ch.isEmpty) return '';
  final code = ch.codeUnitAt(0);
  if (!isHangulSyllable(code)) return ch.toUpperCase();
  final index = code - 0xAC00;
  final cho = index ~/ (21 * 28);
  final jung = (index % (21 * 28)) ~/ 28;
  final jong = index % 28;
  return '${_kChoseongRoman[cho]}${_kJungseongRoman[jung]}${_kJongseongRoman[jong]}';
}

/// Encodes arbitrary user text (English, digits, punctuation, Korean) into units.
List<MorseEncodedUnit> encodeTextToUnits(
  String input, {
  MorseLanguageMode mode = MorseLanguageMode.koreanSkats,
}) {
  final units = <MorseEncodedUnit>[];
  final trimmed = input.trim();
  if (trimmed.isEmpty) return units;

  var previousWasSpace = false;
  for (final rune in trimmed.runes) {
    final ch = String.fromCharCode(rune);
    if (ch.trim().isEmpty) {
      if (!previousWasSpace && units.isNotEmpty) {
        units.add(
          const MorseEncodedUnit(
            displayChar: ' ',
            transmittedChar: ' ',
            morse: '',
            isWordSpace: true,
          ),
        );
        previousWasSpace = true;
      }
      continue;
    }

    previousWasSpace = false;

    final skatsJamos = decomposeHangulToSkatsJamos(ch);
    if (skatsJamos.isNotEmpty) {
      if (mode == MorseLanguageMode.koreanSkats) {
        for (final jamo in skatsJamos) {
          final morse = kKoreanJamoMorseMap[jamo];
          if (morse != null) {
            units.add(
              MorseEncodedUnit(
                displayChar: jamo,
                transmittedChar: jamo,
                morse: morse,
                isWordSpace: false,
                sourceHangul: ch,
              ),
            );
          }
        }
      } else {
        final romanized = romanizeHangulChar(ch);
        for (final rRune in romanized.runes) {
          final rCh = String.fromCharCode(rRune);
          final morse = kLatinMorseMap[rCh];
          if (morse != null) {
            units.add(
              MorseEncodedUnit(
                displayChar: rCh,
                transmittedChar: rCh,
                morse: morse,
                isWordSpace: false,
                sourceHangul: ch,
              ),
            );
          }
        }
      }
      continue;
    }

    final upper = ch.toUpperCase();
    final morse = kLatinMorseMap[upper];
    if (morse != null) {
      units.add(
        MorseEncodedUnit(
          displayChar: upper,
          transmittedChar: upper,
          morse: morse,
          isWordSpace: false,
        ),
      );
    }
  }

  while (units.isNotEmpty && units.last.isWordSpace) {
    units.removeLast();
  }
  return units;
}

/// Formats encoded units into human-readable Morse (`/` separates words).
String formatMorseUnits(List<MorseEncodedUnit> units) {
  final parts = <String>[];
  for (final unit in units) {
    parts.add(unit.isWordSpace ? '/' : unit.morse);
  }
  return parts.join(' ');
}

/// Convenience helper returning the formatted Morse string for [input].
String encodeTextToMorse(
  String input, {
  MorseLanguageMode mode = MorseLanguageMode.koreanSkats,
}) {
  return formatMorseUnits(encodeTextToUnits(input, mode: mode));
}

/// Decodes a single Morse code string (e.g. `·−` or `.-`) into a character.
String? decodeMorseSymbol(
  String rawMorse, {
  MorseLanguageMode mode = MorseLanguageMode.koreanSkats,
}) {
  final normalized = normalizeMorseSymbols(rawMorse.trim());
  if (normalized.isEmpty) return null;
  if (mode == MorseLanguageMode.koreanSkats) {
    // Allow Latin or Jamo depending on match; prioritize Jamo only if user chose SKATS?
    // Actually in free keying, Latin A-Z/0-9 overlaps with SKATS Jamo patterns (e.g. `·` is E and ㅏ).
    // So when mode is Korean SKATS and user explicitly selected SKATS decode, check SKATS first.
    return kMorseToKoreanJamoMap[normalized] ?? kMorseToLatinMap[normalized];
  }
  return kMorseToLatinMap[normalized];
}

/// Decodes a full Morse sequence separated by spaces and `/` for word spaces.
String decodeMorseSequence(
  String rawMorse, {
  MorseLanguageMode mode = MorseLanguageMode.koreanSkats,
  bool preferLatin = false,
}) {
  final tokens = rawMorse.trim().split(RegExp(r'\s+'));
  final buffer = StringBuffer();
  for (final token in tokens) {
    if (token.isEmpty) continue;
    if (token == '/') {
      buffer.write(' ');
      continue;
    }
    final normalized = normalizeMorseSymbols(token);
    final decoded = preferLatin
        ? (kMorseToLatinMap[normalized] ?? kMorseToKoreanJamoMap[normalized])
        : decodeMorseSymbol(normalized, mode: mode);
    buffer.write(decoded ?? '?');
  }
  return buffer.toString();
}
