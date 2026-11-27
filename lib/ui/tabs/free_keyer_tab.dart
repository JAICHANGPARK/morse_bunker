import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:morse_bunker/morse/morse_keyer_controller.dart';
import 'package:morse_bunker/morse/morse_table.dart';
import 'package:morse_bunker/ui/bunker_theme.dart';

/// Tab 3: Live Free Keyer, CRT Oscilloscope, Dit/Dah Hold Gauge & Decoder.
class FreeKeyerTab extends StatelessWidget {
  const FreeKeyerTab({
    super.key,
    required this.controller,
    required this.accentColor,
  });

  final MorseKeyerController controller;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final timing = controller.timing;
    final holdMs = controller.currentHoldMs;
    final thresholdMs = timing.ditDahThresholdMs;
    final maxBarMs = (timing.dahMs * 1.5).clamp(260, 1200);
    final holdFraction = (holdMs / maxBarMs).clamp(0.0, 1.0);
    final thresholdFraction = (thresholdMs / maxBarMs).clamp(0.0, 1.0);
    final isCurrentlyDah = holdMs >= thresholdMs;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // 1. Live CRT Oscilloscope + Hold Timing Gauge
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
                  Icon(Icons.graphic_eq, size: 16, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    '실시간 CW 신호 오실로스코프',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${controller.toneFrequencyHz.round()} Hz',
                    style: const TextStyle(
                      color: BunkerColors.textSecondary,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 68,
                width: double.infinity,
                child: CustomPaint(
                  painter: OscilloscopePainter(
                    samples: controller.waveformSamples,
                    accentColor: accentColor,
                    isActive: controller.isKeyDown,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      controller.isKeyDown
                          ? (isCurrentlyDah ? '판정: 장음 (−)' : '판정: 단음 (·)')
                          : '판정 기준 (${thresholdMs}ms 미만 = · / 이상 = −)',
                      style: TextStyle(
                        color: controller.isKeyDown
                            ? accentColor
                            : BunkerColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${holdMs}ms',
                    style: const TextStyle(
                      color: BunkerColors.textPrimary,
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return Stack(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0F0D),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: BunkerColors.borderSubtle),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 24),
                        height: 10,
                        width: width * holdFraction,
                        decoration: BoxDecoration(
                          color: isCurrentlyDah
                              ? accentColor
                              : const Color(0xFF4ADE80),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      Positioned(
                        left: width * thresholdFraction,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 2. Live Buffer & Decoded Teletype Tape
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A100D),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accentColor.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '실시간 해독기 (TELETYPE)',
                    style: TextStyle(
                      color: BunkerColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  ...MorseLanguageMode.values.map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: TacticalChip(
                        label: m == MorseLanguageMode.koreanSkats ? '한글' : '영문',
                        selected: controller.languageMode == m,
                        accentColor: accentColor,
                        onTap: () => controller.setLanguageMode(m),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    '입력 버퍼:',
                    style: TextStyle(
                      color: BunkerColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.currentMorseBuffer.isEmpty
                          ? '대기 중...'
                          : controller.currentMorseBuffer,
                      style: TextStyle(
                        color: accentColor,
                        fontFamily: 'monospace',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  if (controller.liveBufferCandidate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: accentColor),
                      ),
                      child: Text(
                        '예상: ${controller.liveBufferCandidate}',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const Divider(color: BunkerColors.borderSubtle, height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 54),
                child: SelectableText(
                  controller.decodedText.isEmpty
                      ? '전건을 누르면 모스부호가 자동으로 해독되어 여기에 기록됩니다.'
                      : controller.decodedText,
                  style: TextStyle(
                    color: controller.decodedText.isEmpty
                        ? BunkerColors.textMuted
                        : BunkerColors.textPrimary,
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: controller.commitBufferedCharacter,
                    icon: const Icon(Icons.check, size: 15),
                    label: const Text('글자 확정', style: TextStyle(fontSize: 11.5)),
                    style: TextButton.styleFrom(foregroundColor: accentColor),
                  ),
                  TextButton.icon(
                    onPressed: controller.backspaceDecodedText,
                    icon: const Icon(Icons.backspace_outlined, size: 15),
                    label: const Text('지우기', style: TextStyle(fontSize: 11.5)),
                    style: TextButton.styleFrom(
                      foregroundColor: BunkerColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (controller.decodedText.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: controller.decodedText),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('해독된 전문이 복사되었습니다.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      color: accentColor,
                      tooltip: '복사',
                    ),
                  IconButton(
                    onPressed: controller.clearDecodedText,
                    icon: const Icon(Icons.delete_outline, size: 17),
                    color: BunkerColors.textSecondary,
                    tooltip: '전체 초기화',
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 3. Direct 3D Physical Telegraph Key Guide
        Direct3DKeyGuideBanner(
          controller: controller,
          accentColor: accentColor,
        ),

        const SizedBox(height: 10),

        // 4. Recent Press Logs
        if (controller.recentPressLogs.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: controller.recentPressLogs.map((log) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF121816),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: BunkerColors.borderSubtle),
                ),
                child: Text(
                  log,
                  style: const TextStyle(
                    color: BunkerColors.textSecondary,
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                  ),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 10),

        // 5. Speed & Tone Calibration Controls
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BunkerColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BunkerColors.borderSubtle),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    '송신 속도 (WPM)',
                    style: TextStyle(
                      color: BunkerColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${timing.wpm} WPM (${timing.unitMs}ms)',
                    style: TextStyle(
                      color: accentColor,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Slider(
                value: timing.wpm.toDouble(),
                min: 5,
                max: 25,
                divisions: 20,
                activeColor: accentColor,
                onChanged: (v) => controller.setWpm(v.round()),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '판스워스(Farnsworth) 초보 간격',
                          style: TextStyle(
                            color: BunkerColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '부호는 선명하게, 글자 사이 대기 시간만 여유롭게 늘립니다.',
                          style: TextStyle(
                            color: BunkerColors.textSecondary,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: timing.farnsworthEnabled,
                    onChanged: controller.setFarnsworth,
                    activeThumbColor: accentColor,
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    'CW 비프음 주파수',
                    style: TextStyle(
                      color: BunkerColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${controller.toneFrequencyHz.round()} Hz',
                    style: TextStyle(
                      color: accentColor,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Slider(
                value: controller.toneFrequencyHz,
                min: 450,
                max: 950,
                divisions: 25,
                activeColor: accentColor,
                onChanged: controller.setToneFrequency,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
