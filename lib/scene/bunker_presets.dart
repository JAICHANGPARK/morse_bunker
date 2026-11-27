import 'package:material_ui/material_ui.dart';
import 'package:flutter_scene/scene.dart';
import 'package:morse_bunker/morse/morse_keyer_controller.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Visual theme colors & 3D EnvironmentSettings for each bunker atmosphere.
class BunkerAtmosphereConfig {
  const BunkerAtmosphereConfig({
    required this.environmentSettings,
    required this.overheadColor,
    required this.overheadIntensity,
    required this.fillColor,
    required this.fillIntensity,
    required this.signalLightColor,
    required this.signalEmissiveColor,
    required this.crtEmissiveColor,
    required this.accentColor,
    required this.accentSecondary,
    required this.backdropGradient,
  });

  final EnvironmentSettings environmentSettings;
  final vm.Vector3 overheadColor;
  final double overheadIntensity;
  final vm.Vector3 fillColor;
  final double fillIntensity;
  final vm.Vector3 signalLightColor;
  final vm.Vector4 signalEmissiveColor;
  final vm.Vector4 crtEmissiveColor;
  final Color accentColor;
  final Color accentSecondary;
  final List<Color> backdropGradient;
}

BunkerAtmosphereConfig getAtmosphereConfig(BunkerAtmosphere atmosphere) {
  switch (atmosphere) {
    case BunkerAtmosphere.undergroundBunker:
      return BunkerAtmosphereConfig(
        environmentSettings: EnvironmentSettings(
          toneMapping: ToneMappingMode.aces,
          exposure: 0.95,
          environmentIntensity: 0.16,
          colorGradingEnabled: true,
          contrast: 1.16,
          saturation: 0.92,
          temperature: 0.04,
          bloomEnabled: true,
          bloomThreshold: 0.85,
          bloomIntensity: 0.34,
          bloomScatter: 0.72,
          ambientOcclusionEnabled: true,
          ambientOcclusionMethod: AmbientOcclusionMethod.groundTruth,
          ambientOcclusionHalfResolution: true,
          ambientOcclusionIntensity: 1.25,
          fogEnabled: true,
          fogMode: FogMode.exponential,
          fogColor: vm.Vector3(0.035, 0.042, 0.038),
          fogDensity: 0.09,
          vignetteEnabled: true,
          vignetteIntensity: 0.58,
          vignetteRadius: 0.62,
          filmGrainEnabled: true,
          filmGrainIntensity: 0.16,
        ),
        overheadColor: vm.Vector3(1.0, 0.84, 0.58),
        overheadIntensity: 16.5,
        fillColor: vm.Vector3(0.32, 0.48, 0.42),
        fillIntensity: 1.8,
        signalLightColor: vm.Vector3(1.0, 0.76, 0.25),
        signalEmissiveColor: vm.Vector4(1.0, 0.72, 0.18, 1.0),
        crtEmissiveColor: vm.Vector4(0.22, 1.0, 0.52, 1.0),
        accentColor: const Color(0xFFF5A623),
        accentSecondary: const Color(0xFF4ADE80),
        backdropGradient: const [Color(0xFF0A0E0C), Color(0xFF141B17)],
      );

    case BunkerAtmosphere.darkroomRed:
      return BunkerAtmosphereConfig(
        environmentSettings: EnvironmentSettings(
          toneMapping: ToneMappingMode.aces,
          exposure: 0.86,
          environmentIntensity: 0.10,
          colorGradingEnabled: true,
          contrast: 1.22,
          saturation: 1.05,
          temperature: 0.22,
          bloomEnabled: true,
          bloomThreshold: 0.8,
          bloomIntensity: 0.42,
          bloomScatter: 0.78,
          ambientOcclusionEnabled: true,
          ambientOcclusionMethod: AmbientOcclusionMethod.groundTruth,
          ambientOcclusionHalfResolution: true,
          ambientOcclusionIntensity: 1.35,
          fogEnabled: true,
          fogMode: FogMode.exponential,
          fogColor: vm.Vector3(0.08, 0.015, 0.018),
          fogDensity: 0.11,
          vignetteEnabled: true,
          vignetteIntensity: 0.68,
          vignetteRadius: 0.56,
          filmGrainEnabled: true,
          filmGrainIntensity: 0.20,
        ),
        overheadColor: vm.Vector3(1.0, 0.22, 0.18),
        overheadIntensity: 14.0,
        fillColor: vm.Vector3(0.55, 0.08, 0.08),
        fillIntensity: 1.6,
        signalLightColor: vm.Vector3(1.0, 0.35, 0.22),
        signalEmissiveColor: vm.Vector4(1.0, 0.26, 0.16, 1.0),
        crtEmissiveColor: vm.Vector4(1.0, 0.28, 0.24, 1.0),
        accentColor: const Color(0xFFFF5252),
        accentSecondary: const Color(0xFFFFB74D),
        backdropGradient: const [Color(0xFF100607), Color(0xFF1E0B0D)],
      );

    case BunkerAtmosphere.nightOpsGreen:
      return BunkerAtmosphereConfig(
        environmentSettings: EnvironmentSettings(
          toneMapping: ToneMappingMode.aces,
          exposure: 0.92,
          environmentIntensity: 0.12,
          colorGradingEnabled: true,
          contrast: 1.18,
          saturation: 0.95,
          temperature: -0.14,
          tint: 0.24,
          bloomEnabled: true,
          bloomThreshold: 0.82,
          bloomIntensity: 0.38,
          bloomScatter: 0.75,
          ambientOcclusionEnabled: true,
          ambientOcclusionMethod: AmbientOcclusionMethod.groundTruth,
          ambientOcclusionHalfResolution: true,
          ambientOcclusionIntensity: 1.28,
          fogEnabled: true,
          fogMode: FogMode.exponential,
          fogColor: vm.Vector3(0.018, 0.055, 0.032),
          fogDensity: 0.10,
          vignetteEnabled: true,
          vignetteIntensity: 0.62,
          vignetteRadius: 0.58,
          filmGrainEnabled: true,
          filmGrainIntensity: 0.19,
        ),
        overheadColor: vm.Vector3(0.42, 1.0, 0.58),
        overheadIntensity: 14.5,
        fillColor: vm.Vector3(0.12, 0.45, 0.24),
        fillIntensity: 1.8,
        signalLightColor: vm.Vector3(0.32, 1.0, 0.55),
        signalEmissiveColor: vm.Vector4(0.24, 1.0, 0.52, 1.0),
        crtEmissiveColor: vm.Vector4(0.25, 1.0, 0.62, 1.0),
        accentColor: const Color(0xFF39FF88),
        accentSecondary: const Color(0xFF7DD3FC),
        backdropGradient: const [Color(0xFF050E09), Color(0xFF0B1F14)],
      );
  }
}

/// Target camera position & look-at target for each camera preset.
({vm.Vector3 position, vm.Vector3 target}) getCameraPresetTarget(
  BunkerCameraPreset preset, {
  bool isWideLayout = true,
}) {
  switch (preset) {
    case BunkerCameraPreset.deskOverview:
      if (isWideLayout) {
        return (
          position: vm.Vector3(-0.28, 0.84, -1.58),
          target: vm.Vector3(-0.08, 0.16, -0.26),
        );
      }
      return (
        position: vm.Vector3(0.24, 0.78, -1.42),
        target: vm.Vector3(0.24, 0.14, -0.38),
      );
    case BunkerCameraPreset.telegraphCloseUp:
      return (
        position: vm.Vector3(0.76, 0.42, -1.04),
        target: vm.Vector3(0.26, 0.12, -0.44),
      );
    case BunkerCameraPreset.bunkerWide:
      return (
        position: vm.Vector3(-0.55, 1.55, -2.95),
        target: vm.Vector3(0.0, 0.48, 0.45),
      );
  }
}
