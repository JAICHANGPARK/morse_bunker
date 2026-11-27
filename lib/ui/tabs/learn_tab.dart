import 'package:material_ui/material_ui.dart';
import 'package:morse_bunker/morse/morse_curriculum.dart';
import 'package:morse_bunker/morse/morse_keyer_controller.dart';
import 'package:morse_bunker/morse/morse_table.dart';
import 'package:morse_bunker/ui/bunker_theme.dart';

/// Tab 1: Basics to Advanced Curriculum + Interactive Reference Morse Chart.
class LearnTab extends StatefulWidget {
  const LearnTab({
    super.key,
    required this.controller,
    required this.accentColor,
  });

  final MorseKeyerController controller;
  final Color accentColor;

  @override
  State<LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<LearnTab> {
  int _selectedStageIdx = 0;
  MorseCategory _chartCategory = MorseCategory.alphabet;
  final Set<String> _completedStages = {};

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    final practice = widget.controller.guidedPractice;
    if (practice != null && practice.isCompleted) {
      final stage = kMorseCurriculumStages[_selectedStageIdx];
      if (practice.targetText == stage.practicePhrase) {
        _completedStages.add(stage.id);
      }
    }
  }

  List<MorseEntry> get _entriesForCategory {
    switch (_chartCategory) {
      case MorseCategory.alphabet:
        return kAlphabetEntries;
      case MorseCategory.digit:
        return kDigitEntries;
      case MorseCategory.hangul:
        return kHangulEntries;
      case MorseCategory.prosign:
        return kProsignEntries;
      case MorseCategory.punctuation:
        return kPunctuationEntries;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final timing = ctrl.timing;
    final stage = kMorseCurriculumStages[_selectedStageIdx];
    final activePractice = ctrl.guidedPractice;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // 1. ITU Timing Rules Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BunkerColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BunkerColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: widget.accentColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '모스부호 기초 규칙 · 현재 ${timing.wpm} WPM (1단위 = ${timing.unitMs}ms)',
                      style: TextStyle(
                        color: widget.accentColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ctrl.playRawMorseDemo('·−', label: '1:3 리듬'),
                    style: TextButton.styleFrom(
                      foregroundColor: widget.accentColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('리듬 듣기', style: TextStyle(fontSize: 11.5)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _TimingUnitBlock(
                    label: '단음 (·)',
                    units: '1u',
                    ms: '${timing.ditMs}ms',
                    flex: 1,
                    color: widget.accentColor,
                  ),
                  const SizedBox(width: 4),
                  _TimingUnitBlock(
                    label: '부호쉼',
                    units: '1u',
                    ms: '${timing.intraCharGapMs}ms',
                    flex: 1,
                    color: BunkerColors.textMuted,
                    isGap: true,
                  ),
                  const SizedBox(width: 4),
                  _TimingUnitBlock(
                    label: '장음 (−)',
                    units: '3u',
                    ms: '${timing.dahMs}ms',
                    flex: 3,
                    color: widget.accentColor,
                  ),
                  const SizedBox(width: 4),
                  _TimingUnitBlock(
                    label: '글자쉼',
                    units: '3u',
                    ms: '${timing.interCharGapMs}ms',
                    flex: 2,
                    color: BunkerColors.textMuted,
                    isGap: true,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '단어 사이 공백은 7단위(${timing.wordGapMs}ms)를 쉬어 단어 경계를 구분합니다.',
                style: const TextStyle(
                  color: BunkerColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Guided Practice card if active
        if (activePractice != null) ...[
          GuidedPracticeCard(
            practice: activePractice,
            accentColor: widget.accentColor,
            onReset: () => setState(() => activePractice.reset()),
            onClose: () => ctrl.exitGuidedPractice(),
            onHearTarget: () => ctrl.playTextDemo(
              activePractice.targetText,
              mode: activePractice.mode,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 3. 6-Stage Curriculum Selector
        Text(
          '단계별 커리큘럼 (기초 → 응용)',
          style: TextStyle(
            color: widget.accentColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(kMorseCurriculumStages.length, (i) {
              final s = kMorseCurriculumStages[i];
              final selected = i == _selectedStageIdx;
              final done = _completedStages.contains(s.id);
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: TacticalChip(
                  label: '${s.stageNumber}단계${done ? ' ✓' : ''}',
                  selected: selected,
                  accentColor: done ? const Color(0xFF4ADE80) : widget.accentColor,
                  onTap: () => setState(() => _selectedStageIdx = i),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),

        // Selected Stage Detail Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BunkerColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.accentColor.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stage.title,
                style: TextStyle(
                  color: widget.accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                stage.subtitle,
                style: const TextStyle(
                  color: BunkerColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stage.description,
                style: const TextStyle(
                  color: BunkerColors.textSecondary,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: stage.items.map((item) {
                  final entry = kMorseEntryBySymbol[item];
                  final morse = entry?.morse ??
                      encodeTextToMorse(item, mode: stage.mode);
                  return InkWell(
                    onTap: () => ctrl.playTextDemo(item, mode: stage.mode),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101714),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: BunkerColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item,
                            style: TextStyle(
                              color: widget.accentColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            morse,
                            style: const TextStyle(
                              color: BunkerColors.textPrimary,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 14, color: widget.accentColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        stage.keyTip,
                        style: const TextStyle(
                          color: BunkerColors.textPrimary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (ctrl.isPlayingDemo) {
                          ctrl.stopDemo();
                        } else {
                          ctrl.playTextDemo(
                            stage.practicePhrase,
                            mode: stage.mode,
                          );
                        }
                      },
                      icon: Icon(
                        ctrl.isPlayingDemo ? Icons.stop : Icons.play_arrow,
                        size: 16,
                      ),
                      label: Text(
                        ctrl.isPlayingDemo
                            ? '시범 정지'
                            : '3D 시범 (${stage.practicePhrase})',
                        style: const TextStyle(fontSize: 11.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.accentColor,
                        side: BorderSide(color: widget.accentColor),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => ctrl.startGuidedPractice(
                        stage.practicePhrase,
                        mode: stage.mode,
                      ),
                      icon: const Icon(Icons.touch_app, size: 16),
                      label: const Text(
                        '따라 치기 실습',
                        style: TextStyle(fontSize: 11.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 4. Interactive Reference Morse Chart
        Text(
          '인터랙티브 모스 부호표 (클릭 시 3D 전건·램프·음향 시연)',
          style: TextStyle(
            color: widget.accentColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            MorseCategory.alphabet,
            MorseCategory.digit,
            MorseCategory.hangul,
            MorseCategory.prosign,
          ].map((cat) {
            return TacticalChip(
              label: cat.label,
              selected: _chartCategory == cat,
              accentColor: widget.accentColor,
              onTap: () => setState(() => _chartCategory = cat),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _entriesForCategory.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _chartCategory == MorseCategory.prosign ? 2 : 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio:
                _chartCategory == MorseCategory.prosign ? 1.85 : 1.35,
          ),
          itemBuilder: (context, index) {
            final entry = _entriesForCategory[index];
            return InkWell(
              onTap: () {
                if (entry.category == MorseCategory.prosign) {
                  ctrl.playRawMorseDemo(entry.morse, label: entry.symbol);
                } else {
                  ctrl.playRawMorseDemo(entry.morse, label: entry.symbol);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF101614),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: BunkerColors.borderSubtle),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.symbol,
                      style: TextStyle(
                        color: widget.accentColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.morse,
                      style: const TextStyle(
                        color: BunkerColors.textPrimary,
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.meaning ?? entry.mnemonic,
                      style: const TextStyle(
                        color: BunkerColors.textSecondary,
                        fontSize: 9.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TimingUnitBlock extends StatelessWidget {
  const _TimingUnitBlock({
    required this.label,
    required this.units,
    required this.ms,
    required this.flex,
    required this.color,
    this.isGap = false,
  });

  final String label;
  final String units;
  final String ms;
  final int flex;
  final Color color;
  final bool isGap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: isGap ? const Color(0xFF0E1412) : color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isGap ? BunkerColors.borderSubtle : color,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isGap ? BunkerColors.textSecondary : color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$units ($ms)',
              style: const TextStyle(
                color: BunkerColors.textPrimary,
                fontSize: 9.5,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
