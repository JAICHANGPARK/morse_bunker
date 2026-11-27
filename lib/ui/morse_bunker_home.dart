import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:morse_bunker/morse/morse_keyer_controller.dart';
import 'package:morse_bunker/morse/morse_mic_live_controller.dart';
import 'package:morse_bunker/scene/bunker_presets.dart';
import 'package:morse_bunker/scene/bunker_scene_viewport.dart';
import 'package:morse_bunker/ui/bunker_theme.dart';
import 'package:morse_bunker/ui/tabs/drill_tab.dart';
import 'package:morse_bunker/ui/tabs/free_keyer_tab.dart';
import 'package:morse_bunker/ui/tabs/learn_tab.dart';
import 'package:morse_bunker/ui/tabs/mic_listen_tab.dart';
import 'package:morse_bunker/ui/tabs/text_guide_tab.dart';

/// Main tactical military bunker Morse code training screen.
class MorseBunkerHome extends StatefulWidget {
  const MorseBunkerHome({
    super.key,
    required this.controller,
    required this.micController,
    this.useMockScene = false,
  });

  final MorseKeyerController controller;
  final MorseMicLiveController micController;
  final bool useMockScene;

  @override
  State<MorseBunkerHome> createState() => _MorseBunkerHomeState();
}

class _MorseBunkerHomeState extends State<MorseBunkerHome>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FocusNode _keyboardFocusNode = FocusNode();
  bool _consoleCollapsed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  bool _isTypingInTextField() {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) return false;
    if (focusContext.widget is EditableText) return true;
    return focusContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (_isTypingInTextField()) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent) {
        widget.controller.pressKey();
        return KeyEventResult.handled;
      } else if (event is KeyUpEvent) {
        widget.controller.releaseKey();
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;
        final cfg = getAtmosphereConfig(ctrl.atmosphere);
        final accent = cfg.accentColor;

        return Focus(
          focusNode: _keyboardFocusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Scaffold(
            backgroundColor: const Color(0xFF070B09),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Layer 0: Full-bleed 3D Military Bunker Scene (flutter_scene + flutter_gpu)
                    BunkerSceneViewport(
                      controller: ctrl,
                      isWideLayout: isWide,
                      useMockScene: widget.useMockScene,
                    ),

                    // Layer 1: Top Tactical HUD Bar
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _TopTacticalHud(
                              controller: ctrl,
                              accentColor: accent,
                              consoleCollapsed: _consoleCollapsed,
                              onToggleConsole: () => setState(
                                () => _consoleCollapsed = !_consoleCollapsed,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: isWide
                                  ? _buildWideWorkspace(ctrl, accent)
                                  : _buildNarrowWorkspace(ctrl, accent),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideWorkspace(MorseKeyerController ctrl, Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_consoleCollapsed)
          SizedBox(
            width: 455,
            child: _ConsoleTabsPanel(
              controller: ctrl,
              micController: widget.micController,
              tabController: _tabController,
              accentColor: accent,
            ),
          ),
        const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: SizedBox(
            width: 340,
            child: _Floating3DSceneHud(
              controller: ctrl,
              accentColor: accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowWorkspace(MorseKeyerController ctrl, Color accent) {
    return Column(
      children: [
        // Leave top portion open so user sees 3D bunker desk, radio, and lamp
        Expanded(
          flex: _consoleCollapsed ? 9 : 4,
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: 280,
                child: _Floating3DSceneHud(
                  controller: ctrl,
                  accentColor: accent,
                  compact: true,
                ),
              ),
            ),
          ),
        ),
        if (!_consoleCollapsed)
          Expanded(
            flex: 6,
            child: _ConsoleTabsPanel(
              controller: ctrl,
              micController: widget.micController,
              tabController: _tabController,
              accentColor: accent,
            ),
          ),
      ],
    );
  }
}

class _TopTacticalHud extends StatelessWidget {
  const _TopTacticalHud({
    required this.controller,
    required this.accentColor,
    required this.consoleCollapsed,
    required this.onToggleConsole,
  });

  final MorseKeyerController controller;
  final Color accentColor;
  final bool consoleCollapsed;
  final VoidCallback onToggleConsole;

  @override
  Widget build(BuildContext context) {
    return BunkerPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 10,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Icon(Icons.podcasts, color: accentColor, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MORSE BUNKER · 3D 전술 통신 교관',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  '${controller.militaryRank} · ${controller.timing.wpm} WPM · GPU 3D',
                  style: const TextStyle(
                    color: BunkerColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            ...BunkerAtmosphere.values.map((atmo) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: TacticalChip(
                  label: atmo.label,
                  selected: controller.atmosphere == atmo,
                  accentColor: accentColor,
                  onTap: () => controller.setAtmosphere(atmo),
                ),
              );
            }),
            const SizedBox(width: 6),
            ...BunkerCameraPreset.values.map((cam) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: TacticalChip(
                  label: cam.label,
                  icon: Icons.videocam_outlined,
                  selected: controller.cameraPreset == cam,
                  accentColor: accentColor,
                  onTap: () => controller.setCameraPreset(cam),
                ),
              );
            }),
            const SizedBox(width: 6),
            TacticalChip(
              label: controller.soundEnabled ? '음향 ON' : '음소거',
              icon: controller.soundEnabled
                  ? Icons.volume_up
                  : Icons.volume_off,
              selected: controller.soundEnabled,
              accentColor: accentColor,
              onTap: () => controller.setSoundEnabled(!controller.soundEnabled),
            ),
            const SizedBox(width: 6),
            TacticalChip(
              label: '진공관 험',
              icon: Icons.waves,
              selected: controller.ambientHumEnabled,
              accentColor: accentColor,
              onTap: () =>
                  controller.setAmbientHum(!controller.ambientHumEnabled),
            ),
            const SizedBox(width: 6),
            TacticalChip(
              label: consoleCollapsed ? '패널 열기' : '3D 전체보기',
              icon: consoleCollapsed ? Icons.menu_open : Icons.fullscreen,
              selected: consoleCollapsed,
              accentColor: accentColor,
              onTap: onToggleConsole,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsoleTabsPanel extends StatelessWidget {
  const _ConsoleTabsPanel({
    required this.controller,
    required this.micController,
    required this.tabController,
    required this.accentColor,
  });

  final MorseKeyerController controller;
  final MorseMicLiveController micController;
  final TabController tabController;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return BunkerPanel(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          TabBar(
            controller: tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: accentColor,
            labelColor: accentColor,
            unselectedLabelColor: BunkerColors.textSecondary,
            dividerColor: BunkerColors.borderSubtle,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            tabs: const [
              Tab(text: '기초학습'),
              Tab(text: '변환·가이드'),
              Tab(text: '자유송신'),
              Tab(text: '실전훈련'),
              Tab(text: '마이크 해독'),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                LearnTab(controller: controller, accentColor: accentColor),
                TextGuideTab(controller: controller, accentColor: accentColor),
                FreeKeyerTab(controller: controller, accentColor: accentColor),
                DrillTab(controller: controller, accentColor: accentColor),
                MicListenTab(
                  keyerController: controller,
                  micController: micController,
                  accentColor: accentColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Floating3DSceneHud extends StatelessWidget {
  const _Floating3DSceneHud({
    required this.controller,
    required this.accentColor,
    this.compact = false,
  });

  final MorseKeyerController controller;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: BunkerPanel(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 7 : 9,
        ),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: controller.isLampActive
                    ? accentColor
                    : const Color(0xFF2B3530),
                boxShadow: controller.isLampActive
                    ? [
                        BoxShadow(
                          color: accentColor,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                controller.isPlayingDemo
                    ? '시범 송신: ${controller.activePlaybackLabel}'
                    : (controller.currentMorseBuffer.isNotEmpty
                        ? '입력 중: ${controller.currentMorseBuffer}'
                        : '3D 전건 직접 클릭 · Space바 · 드래그 시점 회전'),
                style: TextStyle(
                  color: controller.isLampActive
                      ? accentColor
                      : BunkerColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
