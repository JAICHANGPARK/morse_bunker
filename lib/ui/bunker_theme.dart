import 'package:material_ui/material_ui.dart';
import 'package:morse_bunker/morse/morse_curriculum.dart';
import 'package:morse_bunker/morse/morse_keyer_controller.dart';
import 'package:morse_bunker/morse/morse_table.dart';

/// Shared military bunker UI components and styling helpers.
class BunkerColors {
  static const Color panelBg = Color(0xD90C110F);
  static const Color panelSurface = Color(0xE6131A17);
  static const Color cardBg = Color(0xCC18201C);
  static const Color borderSubtle = Color(0x44586A60);
  static const Color textPrimary = Color(0xFFE9EFEA);
  static const Color textSecondary = Color(0xFF9BA9A0);
  static const Color textMuted = Color(0xFF6B7870);
}

/// Dark translucent tactical console container.
class BunkerPanel extends StatelessWidget {
  const BunkerPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderColor,
    this.borderRadius = 12,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: BunkerColors.panelBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? BunkerColors.borderSubtle,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Compact pill selector button for HUD controls.
class TacticalChip extends StatelessWidget {
  const TacticalChip({
    super.key,
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.22)
              : const Color(0x99121816),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? accentColor : BunkerColors.borderSubtle,
            width: selected ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: selected ? accentColor : BunkerColors.textSecondary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? accentColor : BunkerColors.textSecondary,
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tactical guide card reminding the operator to press the physical 3D brass
/// telegraph key directly (or Spacebar), with a 1-tap macro camera zoom button.
class Direct3DKeyGuideBanner extends StatelessWidget {
  const Direct3DKeyGuideBanner({
    super.key,
    required this.controller,
    required this.accentColor,
  });

  final MorseKeyerController controller;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isDown = controller.isKeyDown;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDown
            ? accentColor.withValues(alpha: 0.16)
            : const Color(0xFF101714),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDown ? accentColor : accentColor.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDown ? Icons.bolt : Icons.touch_app,
            size: 18,
            color: isDown ? accentColor : BunkerColors.textPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDown
                      ? '3D 전건 타건 중 · ${controller.currentHoldMs}ms'
                      : '3D 황동 전건을 직접 꾹 눌러 송신하세요',
                  style: TextStyle(
                    color: isDown ? accentColor : BunkerColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  '화면 속 전건 손잡이를 마우스/터치로 누르거나 Space바를 사용하세요',
                  style: TextStyle(
                    color: BunkerColors.textSecondary,
                    fontSize: 10.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TacticalChip(
            label: controller.cameraPreset == BunkerCameraPreset.telegraphCloseUp
                ? '기본 시점'
                : '전건 클로즈업',
            icon: Icons.center_focus_strong,
            selected:
                controller.cameraPreset == BunkerCameraPreset.telegraphCloseUp,
            accentColor: accentColor,
            onTap: () => controller.setCameraPreset(
              controller.cameraPreset == BunkerCameraPreset.telegraphCloseUp
                  ? BunkerCameraPreset.deskOverview
                  : BunkerCameraPreset.telegraphCloseUp,
            ),
          ),
        ],
      ),
    );
  }
}

/// Real-time CRT oscilloscope painter for CW signal activity.
class OscilloscopePainter extends CustomPainter {
  OscilloscopePainter({
    required this.samples,
    required this.accentColor,
    required this.isActive,
  });

  final List<double> samples;
  final Color accentColor;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF060C09);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      bgPaint,
    );

    // Subtle CRT grid lines
    final gridPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.14)
      ..strokeWidth = 0.75;
    for (var i = 1; i < 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (var i = 1; i < 8; i++) {
      final x = size.width * (i / 8);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    if (samples.isEmpty) return;

    final path = Path();
    final midY = size.height * 0.5;
    final amp = size.height * 0.36;
    for (var i = 0; i < samples.length; i++) {
      final x = (i / (samples.length - 1)) * size.width;
      final normalized = (samples[i] - 0.5) * 2.0; // -1..1 when active, -1 idle
      final y = samples[i] == 0.0 ? midY : midY - normalized * amp;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (isActive) {
      final glowPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(path, glowPaint);
    }

    final linePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant OscilloscopePainter oldDelegate) => true;
}

/// Inline guided tap-along card shared by LearnTab and TextGuideTab.
class GuidedPracticeCard extends StatelessWidget {
  const GuidedPracticeCard({
    super.key,
    required this.practice,
    required this.accentColor,
    required this.onReset,
    required this.onClose,
    required this.onHearTarget,
  });

  final GuidedPracticeState practice;
  final Color accentColor;
  final VoidCallback onReset;
  final VoidCallback onClose;
  final VoidCallback onHearTarget;

  @override
  Widget build(BuildContext context) {
    final unit = practice.currentUnit;
    final expected = practice.expectedSymbol;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101915),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.7), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes, color: accentColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '따라 치기 실습 · ${practice.targetText}',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onHearTarget,
                icon: const Icon(Icons.volume_up, size: 14),
                label: const Text('시범', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              IconButton(
                onPressed: onReset,
                icon: const Icon(Icons.refresh, size: 16),
                tooltip: '처음부터',
                color: BunkerColors.textSecondary,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 16),
                tooltip: '종료',
                color: BunkerColors.textSecondary,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: practice.progress,
              backgroundColor: const Color(0xFF1F2B25),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          if (practice.isCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF153022),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4ADE80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Color(0xFF4ADE80), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      practice.lastFeedback,
                      style: const TextStyle(
                        color: Color(0xFFE2FBE9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (unit != null) ...[
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor),
                  ),
                  child: Text(
                    unit.displayChar,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        children: List.generate(unit.morse.length, (i) {
                          final sym = unit.morse[i];
                          final done = i < practice.symbolIndex;
                          final current = i == practice.symbolIndex;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: done
                                  ? const Color(0xFF1B3A29)
                                  : current
                                      ? accentColor.withValues(alpha: 0.25)
                                      : const Color(0xFF1A221E),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: done
                                    ? const Color(0xFF4ADE80)
                                    : current
                                        ? accentColor
                                        : BunkerColors.borderSubtle,
                              ),
                            ),
                            child: Text(
                              sym,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: done
                                    ? const Color(0xFF4ADE80)
                                    : current
                                        ? accentColor
                                        : BunkerColors.textSecondary,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      if (expected != null)
                        Text(
                          expected == kDah
                              ? '다음 입력: 길게 누르기 − (약 ${practice.timing.dahMs}ms)'
                              : '다음 입력: 짧게 탭 · (약 ${practice.timing.ditMs}ms)',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              practice.lastFeedback,
              style: TextStyle(
                color: practice.lastWasSuccess
                    ? const Color(0xFF9BE7B8)
                    : const Color(0xFFFF8A80),
                fontSize: 11.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
