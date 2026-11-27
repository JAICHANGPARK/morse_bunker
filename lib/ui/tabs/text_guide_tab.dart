import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:morse_bunker/morse/morse_keyer_controller.dart';
import 'package:morse_bunker/morse/morse_table.dart';
import 'package:morse_bunker/morse/morse_timing.dart';
import 'package:morse_bunker/ui/bunker_theme.dart';

/// Tab 2: Text-to-Morse Converter & Step-by-Step Keying Method Guide.
class TextGuideTab extends StatefulWidget {
  const TextGuideTab({
    super.key,
    required this.controller,
    required this.accentColor,
  });

  final MorseKeyerController controller;
  final Color accentColor;

  @override
  State<TextGuideTab> createState() => _TextGuideTabState();
}

class _TextGuideTabState extends State<TextGuideTab> {
  late final TextEditingController _textController;

  static const List<String> _presets = [
    'SOS',
    'HELLO',
    'ROGER',
    'ALPHA 01',
    '구조 요청',
    '작전 개시',
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: 'SOS');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final plan = buildMorseTransmissionPlan(
      _textController.text,
      mode: ctrl.languageMode,
      timing: ctrl.timing,
    );
    final activePractice = ctrl.guidedPractice;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Input Header & Korean Encoding Mode Switch
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
                  Icon(Icons.translate, size: 16, color: widget.accentColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '텍스트 → 모스부호 입력법 변환기',
                      style: TextStyle(
                        color: widget.accentColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  color: BunkerColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: '변환할 영문, 숫자 또는 한글 입력 (예: SOS, 구조 요청)',
                  hintStyle: const TextStyle(
                    color: BunkerColors.textMuted,
                    fontSize: 12.5,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0A0F0D),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: BunkerColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: BunkerColors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: widget.accentColor),
                  ),
                  suffixIcon: _textController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          color: BunkerColors.textSecondary,
                          onPressed: () {
                            _textController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _presets.map((preset) {
                  return TacticalChip(
                    label: preset,
                    selected: _textController.text.trim() == preset,
                    accentColor: widget.accentColor,
                    onTap: () {
                      _textController.text = preset;
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    '한글 처리:',
                    style: TextStyle(
                      color: BunkerColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...MorseLanguageMode.values.map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: TacticalChip(
                        label: m.label,
                        selected: ctrl.languageMode == m,
                        accentColor: widget.accentColor,
                        onTap: () => ctrl.setLanguageMode(m),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Full Morse Result + Action Buttons
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A100D),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.accentColor.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '변환된 모스부호 · 총 ${(plan.totalDurationMs / 1000).toStringAsFixed(1)}초',
                    style: const TextStyle(
                      color: BunkerColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (plan.formattedMorse.isNotEmpty)
                    InkWell(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: plan.formattedMorse),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('모스부호가 클립보드에 복사되었습니다.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 13, color: widget.accentColor),
                          const SizedBox(width: 4),
                          Text(
                            '복사',
                            style: TextStyle(
                              color: widget.accentColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              SelectableText(
                plan.formattedMorse.isEmpty
                    ? '텍스트를 입력하면 모스부호와 타건 방법이 표시됩니다.'
                    : plan.formattedMorse,
                style: TextStyle(
                  color: plan.formattedMorse.isEmpty
                      ? BunkerColors.textMuted
                      : widget.accentColor,
                  fontFamily: 'monospace',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              if (plan.events.isNotEmpty) ...[
                const SizedBox(height: 10),
                // Proportional ON/OFF Visual Timeline Bar
                SizedBox(
                  height: 18,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: plan.events.length,
                    itemBuilder: (context, idx) {
                      final ev = plan.events[idx];
                      final isActive = ctrl.isPlayingDemo &&
                          ctrl.activePlaybackCharIndex == ev.charIndex &&
                          ctrl.activePlaybackSymbolIndex == ev.symbolIndex &&
                          ev.isOn;
                      final width = (ev.durationMs / ctrl.timing.unitMs) * 10.0;
                      return Container(
                        width: width.clamp(4.0, 64.0),
                        margin: const EdgeInsets.only(right: 1.5),
                        decoration: BoxDecoration(
                          color: ev.isOn
                              ? (isActive
                                  ? Colors.white
                                  : widget.accentColor.withValues(alpha: 0.8))
                              : const Color(0xFF141C18),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: plan.events.isEmpty
                          ? null
                          : () {
                              if (ctrl.isPlayingDemo) {
                                ctrl.stopDemo();
                              } else {
                                ctrl.playTransmissionPlan(plan);
                              }
                            },
                      icon: Icon(
                        ctrl.isPlayingDemo ? Icons.stop : Icons.play_arrow,
                        size: 16,
                      ),
                      label: Text(
                        ctrl.isPlayingDemo ? '시범 중지' : '3D 시범 송신',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.accentColor,
                        side: BorderSide(color: widget.accentColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: plan.events.isEmpty
                          ? null
                          : () => ctrl.startGuidedPractice(
                                _textController.text,
                                mode: ctrl.languageMode,
                              ),
                      icon: const Icon(Icons.keyboard_alt_outlined, size: 16),
                      label: const Text(
                        '이 문장 따라 치기',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (activePractice != null) ...[
          const SizedBox(height: 10),
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
        ],

        const SizedBox(height: 12),
        if (plan.guides.isNotEmpty) ...[
          Text(
            '글자별 실제 전건 타건 가이드 (카드를 누르면 해당 글자만 시범 송신)',
            style: TextStyle(
              color: widget.accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...plan.guides.map((guide) {
            final isPlayingThis = ctrl.isPlayingDemo &&
                ctrl.activePlaybackCharIndex == guide.charIndex;

            if (guide.unit.isWordSpace) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1412),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPlayingThis
                        ? widget.accentColor
                        : BunkerColors.borderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.space_bar,
                      size: 16,
                      color: isPlayingThis
                          ? widget.accentColor
                          : BunkerColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '단어 구분 (/) · ${guide.trailingPauseLabel}',
                      style: TextStyle(
                        color: isPlayingThis
                            ? widget.accentColor
                            : BunkerColors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return InkWell(
              onTap: () => ctrl.playRawMorseDemo(
                guide.unit.morse,
                label: guide.unit.displayChar,
              ),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPlayingThis
                      ? widget.accentColor.withValues(alpha: 0.16)
                      : BunkerColors.cardBg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isPlayingThis
                        ? widget.accentColor
                        : BunkerColors.borderSubtle,
                    width: isPlayingThis ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E1412),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: BunkerColors.borderSubtle),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            guide.unit.displayChar,
                            style: TextStyle(
                              color: widget.accentColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (guide.unit.sourceHangul != null)
                            Text(
                              '(${guide.unit.sourceHangul})',
                              style: const TextStyle(
                                color: BunkerColors.textMuted,
                                fontSize: 9,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                guide.unit.morse,
                                style: const TextStyle(
                                  color: BunkerColors.textPrimary,
                                  fontFamily: 'monospace',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${guide.totalDurationMs}ms',
                                style: const TextStyle(
                                  color: BunkerColors.textMuted,
                                  fontFamily: 'monospace',
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            guide.stepSummary,
                            style: const TextStyle(
                              color: BunkerColors.textPrimary,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            guide.trailingPauseLabel,
                            style: const TextStyle(
                              color: BunkerColors.textSecondary,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
