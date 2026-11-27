import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_scene/scene.dart';
import 'package:morse_bunker/morse/morse_keyer_controller.dart';
import 'package:morse_bunker/scene/bunker_presets.dart';
import 'package:morse_bunker/scene/bunker_scene_builder.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Full-screen 3D viewport rendering the dark military radio bunker with
/// `flutter_scene` and `flutter_gpu`, supporting direct physical pressing of the
/// 3D brass telegraph key via raycasting + projected knob proximity.
class BunkerSceneViewport extends StatefulWidget {
  const BunkerSceneViewport({
    super.key,
    required this.controller,
    this.isWideLayout = true,
    this.useMockScene = false,
  });

  final MorseKeyerController controller;
  final bool isWideLayout;

  /// Used in widget tests where a GPU context is unavailable.
  final bool useMockScene;

  @override
  State<BunkerSceneViewport> createState() => _BunkerSceneViewportState();
}

class _BunkerSceneViewportState extends State<BunkerSceneViewport> {
  BunkerSceneRig? _rig;
  bool _ready = false;
  String? _initError;

  // Spring-damper physical lever dynamics
  double _leverDepression = 0.0; // 0.0 (rest up) -> 1.0 (pressed onto anvil)
  double _leverVelocity = 0.0;
  bool _wasBottomedOut = false;
  double _cameraRecoilY = 0.0;
  double _lampGlow = 0.0;

  // Smooth camera state
  late vm.Vector3 _camPos;
  late vm.Vector3 _camTarget;
  double _orbitYaw = 0.0;
  double _orbitPitch = 0.0;

  // Cached camera & viewport for exact pointer picking & 3D->2D reticle projection
  PerspectiveCamera? _lastCamera;
  Size _lastViewportSize = Size.zero;
  final ValueNotifier<Offset?> _knobScreenPos = ValueNotifier<Offset?>(null);

  // Atmosphere transition state
  BunkerAtmosphere _currentAtmosphere = BunkerAtmosphere.undergroundBunker;
  EnvironmentSettings? _fromEnv;
  EnvironmentSettings? _toEnv;
  double _envTransitionT = 1.0;

  // Pointer & hover state for direct 3D telegraph key interaction
  bool _pointerHeld3DKey = false;
  bool _isHovering3DKey = false;
  bool _hasPressed3DOnce = false;

  @override
  void initState() {
    super.initState();
    final initialCam = getCameraPresetTarget(
      widget.controller.cameraPreset,
      isWideLayout: widget.isWideLayout,
    );
    _camPos = initialCam.position.clone();
    _camTarget = initialCam.target.clone();
    _currentAtmosphere = widget.controller.atmosphere;

    if (!widget.useMockScene) {
      _initScene();
    }
  }

  @override
  void dispose() {
    _knobScreenPos.dispose();
    super.dispose();
  }

  Future<void> _initScene() async {
    try {
      await Scene.initializeStaticResources();
      final rig = buildBunkerScene();
      if (kIsWeb) {
        rig.scene.renderQuality.adaptive = true;
      }
      final cfg = getAtmosphereConfig(widget.controller.atmosphere);
      rig.scene.environmentSettings = cfg.environmentSettings;
      _applyLightColors(rig, cfg, lampGlow: 0.0, timeSec: 0.0);

      if (!mounted) return;
      setState(() {
        _rig = rig;
        _ready = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initError = e.toString();
      });
    }
  }

  void _applyLightColors(
    BunkerSceneRig rig,
    BunkerAtmosphereConfig cfg, {
    required double lampGlow,
    required double timeSec,
  }) {
    rig.overheadSpotLight.color = cfg.overheadColor;
    rig.overheadSpotLight.intensity = cfg.overheadIntensity;
    rig.overheadBulbMaterial.emissiveFactor = vm.Vector4(
      cfg.overheadColor.x,
      cfg.overheadColor.y,
      cfg.overheadColor.z,
      1.0,
    );

    rig.fillPointLight.color = cfg.fillColor;
    rig.fillPointLight.intensity = cfg.fillIntensity;

    rig.signalPointLight.color = cfg.signalLightColor;
    rig.signalPointLight.intensity = 0.25 + lampGlow * 14.5;

    rig.beaconLensMaterial.emissiveFactor = cfg.signalEmissiveColor;
    rig.beaconLensMaterial.emissiveStrength = 0.14 + lampGlow * 6.5;

    final crtPulse =
        1.1 + lampGlow * 1.4 + 0.12 * math.sin(timeSec * 3.5);
    rig.crtScreenMaterial.emissiveFactor = cfg.crtEmissiveColor;
    rig.crtScreenMaterial.emissiveStrength = crtPulse;
  }

  PerspectiveCamera _buildCamera(Size viewportSize, double timeSec) {
    final breathX = math.sin(timeSec * 0.45) * 0.009;
    final breathY = math.cos(timeSec * 0.35) * 0.006;

    final offset = _camPos - _camTarget;
    final cosY = math.cos(_orbitYaw);
    final sinY = math.sin(_orbitYaw);
    final rotatedX = offset.x * cosY - offset.z * sinY;
    final rotatedZ = offset.x * sinY + offset.z * cosY;
    final finalPos = vm.Vector3(
      _camTarget.x + rotatedX + breathX,
      (_camTarget.y + offset.y + _orbitPitch + breathY + _cameraRecoilY)
          .clamp(0.24, 2.5),
      _camTarget.z + rotatedZ,
    );

    final cam = PerspectiveCamera(
      position: finalPos,
      target: vm.Vector3(
        _camTarget.x,
        _camTarget.y + _cameraRecoilY * 0.5,
        _camTarget.z,
      ),
      fovRadiansY: 42 * vm.degrees2Radians,
    );
    _lastCamera = cam;
    _lastViewportSize = viewportSize;
    return cam;
  }

  void _onTick(Duration elapsed, double dt) {
    final rig = _rig;
    if (rig == null) return;

    final timeSec = elapsed.inMicroseconds / 1e6;
    final safeDt = dt.clamp(0.001, 0.033);

    // Update rolling oscilloscope samples in controller
    widget.controller.sampleOscilloscopeTick(timeSec);

    // Smooth camera interpolation toward selected preset
    final desiredCam = getCameraPresetTarget(
      widget.controller.cameraPreset,
      isWideLayout: widget.isWideLayout,
    );
    final camAlpha = (safeDt * 4.8).clamp(0.0, 1.0);
    _camPos = _camPos + (desiredCam.position - _camPos) * camAlpha;
    _camTarget = _camTarget + (desiredCam.target - _camTarget) * camAlpha;
    _cameraRecoilY *= math.exp(-safeDt * 24.0);

    // Smooth atmosphere transition
    if (_currentAtmosphere != widget.controller.atmosphere) {
      _fromEnv = rig.scene.environmentSettings;
      _toEnv =
          getAtmosphereConfig(widget.controller.atmosphere).environmentSettings;
      _currentAtmosphere = widget.controller.atmosphere;
      _envTransitionT = 0.0;
    }
    if (_envTransitionT < 1.0 && _fromEnv != null && _toEnv != null) {
      _envTransitionT = (_envTransitionT + safeDt * 2.4).clamp(0.0, 1.0);
      rig.scene.environmentSettings =
          EnvironmentSettings.lerp(_fromEnv!, _toEnv!, _envTransitionT);
    }

    // Spring-damper physical lever motion
    final isDown = widget.controller.isKeyDown;
    if (isDown) {
      final accel = (1.0 - _leverDepression) * 560.0 - _leverVelocity * 24.0;
      _leverVelocity += accel * safeDt;
      _leverDepression += _leverVelocity * safeDt;
      if (_leverDepression >= 1.0) {
        _leverDepression = 1.0;
        _leverVelocity = 0.0;
        if (!_wasBottomedOut) {
          _wasBottomedOut = true;
          _cameraRecoilY = -0.0055;
        }
      }
    } else {
      _wasBottomedOut = false;
      final accel = (0.0 - _leverDepression) * 340.0 - _leverVelocity * 17.0;
      _leverVelocity += accel * safeDt;
      _leverDepression += _leverVelocity * safeDt;
      if (_leverDepression < -0.06) {
        _leverDepression = -0.06;
        _leverVelocity = 0.0;
      }
    }

    // Positive +X angle tilts front (-Z) knob UP at rest;
    // rotating negative by -0.23 pushes the front (-Z) knob physically DOWNWARD onto the anvil!
    final leverAngle = 0.085 - _leverDepression * 0.23;
    rig.telegraphLeverPivot.rotation = vm.Quaternion.axisAngle(
      vm.Vector3(1, 0, 0),
      leverAngle,
    );

    // Compress coiled brass spring beneath the lever
    final springScaleY = (1.0 - _leverDepression * 0.44).clamp(0.45, 1.15);
    rig.telegraphSpringNode.scale = vm.Vector3(1.0, springScaleY, 1.0);

    // Contact spark + micro PointLight when brass contact meets anvil
    final sparkActive = _leverDepression > 0.80 && isDown;
    rig.contactSparkNode.scale = vm.Vector3.all(sparkActive ? 1.0 : 0.001);
    rig.contactSparkMaterial.emissiveStrength = sparkActive ? 8.5 : 0.0;
    rig.contactSparkLight.intensity = sparkActive ? 4.2 : 0.0;

    // Animate beacon signal lamp
    final lampTarget = widget.controller.isLampActive ? 1.0 : 0.0;
    final lampSpeed = widget.controller.isLampActive ? 34.0 : 14.0;
    _lampGlow +=
        (lampTarget - _lampGlow) * (safeDt * lampSpeed).clamp(0.0, 1.0);

    final cfg = getAtmosphereConfig(widget.controller.atmosphere);
    _applyLightColors(rig, cfg, lampGlow: _lampGlow, timeSec: timeSec);

    // Subtle overhead hanging lamp sway
    rig.overheadLampPivot.rotation = vm.Quaternion.axisAngle(
      vm.Vector3(0, 0, 1),
      math.sin(timeSec * 0.75) * 0.016,
    );

    // Vacuum tubes gentle filament pulse & meter needle kick when transmitting
    for (var i = 0; i < rig.tubeMaterials.length; i++) {
      rig.tubeMaterials[i].emissiveStrength =
          1.35 + 0.35 * math.sin(timeSec * 2.1 + i * 1.3) + _lampGlow * 1.4;
    }
    rig.radioMeterNeedle.rotation = vm.Quaternion.axisAngle(
      vm.Vector3(0, 0, 1),
      0.55 - _lampGlow * 1.05,
    );

    // Project 3D knob position onto 2D viewport for the diegetic reticle overlay
    final cam = _lastCamera;
    if (cam != null && !_lastViewportSize.isEmpty) {
      final knobWorld = rig.knobTipNode.globalTransform.getTranslation();
      _knobScreenPos.value = cam.worldToScreen(knobWorld, _lastViewportSize);
    }
  }

  bool _hitsTelegraphKey(Offset localPos, Size viewSize) {
    final rig = _rig;
    if (rig == null || viewSize.isEmpty) return false;
    final cam = _lastCamera ?? _buildCamera(viewSize, 0.0);

    // 1. Generous projected 2D proximity around the 3D bakelite finger knob
    final knobWorld = rig.knobTipNode.globalTransform.getTranslation();
    final knobScreen = cam.worldToScreen(knobWorld, viewSize);
    if (knobScreen != null && (localPos - knobScreen).distance <= 92.0) {
      return true;
    }

    // 2. Exact 3D mesh raycast on any part of the telegraph assembly
    final ray = cam.screenPointToRay(localPos, viewSize);
    final hit = raycastNode(rig.scene.root, ray);
    if (hit == null) return false;
    return hit.node.name.startsWith('telegraph_');
  }

  @override
  Widget build(BuildContext context) {
    final cfg = getAtmosphereConfig(widget.controller.atmosphere);

    if (widget.useMockScene || _initError != null || !_ready || _rig == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.2, -0.2),
            radius: 1.15,
            colors: [
              cfg.accentColor.withValues(alpha: 0.14),
              ...cfg.backdropGradient,
            ],
          ),
        ),
        child: _initError == null && !widget.useMockScene && !_ready
            ? Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cfg.accentColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '3D 벙커 GPU 셰이더 초기화 중...',
                        style: TextStyle(
                          color: cfg.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.expand(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return MouseRegion(
          cursor: _pointerHeld3DKey
              ? SystemMouseCursors.grabbing
              : (_isHovering3DKey
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.grab),
          onHover: (event) {
            final hovering = _hitsTelegraphKey(event.localPosition, size);
            if (hovering != _isHovering3DKey) {
              setState(() => _isHovering3DKey = hovering);
            }
          },
          onExit: (_) {
            if (_isHovering3DKey) {
              setState(() => _isHovering3DKey = false);
            }
          },
          child: Listener(
            onPointerDown: (event) {
              if (_hitsTelegraphKey(event.localPosition, size)) {
                _pointerHeld3DKey = true;
                _hasPressed3DOnce = true;
                HapticFeedback.heavyImpact();
                widget.controller.pressKey();
              }
            },
            onPointerUp: (_) {
              if (_pointerHeld3DKey) {
                _pointerHeld3DKey = false;
                HapticFeedback.selectionClick();
                widget.controller.releaseKey();
              }
            },
            onPointerCancel: (_) {
              if (_pointerHeld3DKey) {
                _pointerHeld3DKey = false;
                widget.controller.releaseKey();
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanUpdate: (details) {
                if (_pointerHeld3DKey) return;
                setState(() {
                  _orbitYaw =
                      (_orbitYaw - details.delta.dx * 0.005).clamp(-0.65, 0.65);
                  _orbitPitch =
                      (_orbitPitch + details.delta.dy * 0.004).clamp(-0.35, 0.55);
                });
              },
              onDoubleTap: () {
                setState(() {
                  _orbitYaw = 0.0;
                  _orbitPitch = 0.0;
                });
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SceneView(
                    _rig!.scene,
                    onTick: _onTick,
                    cameraBuilder: (elapsed) =>
                        _buildCamera(size, elapsed.inMicroseconds / 1e6),
                    errorBuilder: (context, error, retry) => Container(
                      color: const Color(0xFF0A0E0C),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: cfg.accentColor, size: 32),
                          const SizedBox(height: 10),
                          const Text(
                            '3D WebGL2/GPU 셰이더를 불러오지 못했습니다.',
                            style: TextStyle(
                              color: Color(0xFFE9EFEA),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: retry,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: cfg.accentColor,
                              side: BorderSide(color: cfg.accentColor),
                            ),
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Diegetic 3D-anchored reticle & live timing badge projected onto the 3D knob
                  IgnorePointer(
                    child: ValueListenableBuilder<Offset?>(
                      valueListenable: _knobScreenPos,
                      builder: (context, pos, _) {
                        if (pos == null) return const SizedBox.shrink();
                        return ListenableBuilder(
                          listenable: widget.controller,
                          builder: (context, _) {
                            final isDown = widget.controller.isKeyDown;
                            final holdMs = widget.controller.currentHoldMs;
                            final isDah = holdMs >=
                                widget.controller.timing.ditDahThresholdMs;
                            final ringSize = isDown ? 54.0 : (_isHovering3DKey ? 74.0 : 66.0);
                            final showIdlePrompt =
                                !isDown && (!_hasPressed3DOnce || _isHovering3DKey);

                            return Stack(
                              children: [
                                Positioned(
                                  left: pos.dx - ringSize / 2,
                                  top: pos.dy - ringSize / 2,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 70),
                                    width: ringSize,
                                    height: ringSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDown
                                            ? (isDah
                                                ? cfg.accentColor
                                                : const Color(0xFF4ADE80))
                                            : cfg.accentColor.withValues(
                                                alpha: _isHovering3DKey
                                                    ? 0.85
                                                    : 0.36,
                                              ),
                                        width: isDown ? 2.4 : 1.4,
                                      ),
                                      boxShadow: isDown
                                          ? [
                                              BoxShadow(
                                                color: (isDah
                                                        ? cfg.accentColor
                                                        : const Color(
                                                            0xFF4ADE80))
                                                    .withValues(alpha: 0.45),
                                                blurRadius: 16,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                                if (isDown)
                                  Positioned(
                                    left: pos.dx - 58,
                                    top: pos.dy - 64,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xE60B110E),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isDah
                                              ? cfg.accentColor
                                              : const Color(0xFF4ADE80),
                                        ),
                                      ),
                                      child: Text(
                                        isDah
                                            ? '− 장음 ${holdMs}ms'
                                            : '· 단음 ${holdMs}ms',
                                        style: TextStyle(
                                          color: isDah
                                              ? cfg.accentColor
                                              : const Color(0xFF4ADE80),
                                          fontFamily: 'monospace',
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  )
                                else if (showIdlePrompt)
                                  Positioned(
                                    left: pos.dx - 70,
                                    top: pos.dy + 40,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xCC0C110F),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: cfg.accentColor
                                              .withValues(alpha: 0.55),
                                        ),
                                      ),
                                      child: Text(
                                        '3D 전건 직접 누르기',
                                        style: TextStyle(
                                          color: cfg.accentColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
