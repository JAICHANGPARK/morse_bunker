import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Holds references to animated and interactive 3D nodes/lights inside the bunker.
class BunkerSceneRig {
  BunkerSceneRig({
    required this.scene,
    required this.telegraphKeyRoot,
    required this.telegraphLeverPivot,
    required this.telegraphSpringNode,
    required this.knobTipNode,
    required this.contactSparkNode,
    required this.contactSparkMaterial,
    required this.contactSparkLight,
    required this.beaconLensMaterial,
    required this.signalPointLight,
    required this.overheadLampPivot,
    required this.overheadSpotLight,
    required this.overheadBulbMaterial,
    required this.fillPointLight,
    required this.crtScreenMaterial,
    required this.tubeMaterials,
    required this.radioMeterNeedle,
  });

  final Scene scene;
  final Node telegraphKeyRoot;
  final Node telegraphLeverPivot;
  final Node telegraphSpringNode;
  final Node knobTipNode;
  final Node contactSparkNode;
  final PhysicallyBasedMaterial contactSparkMaterial;
  final PointLight contactSparkLight;
  final PhysicallyBasedMaterial beaconLensMaterial;
  final PointLight signalPointLight;
  final Node overheadLampPivot;
  final SpotLight overheadSpotLight;
  final PhysicallyBasedMaterial overheadBulbMaterial;
  final PointLight fillPointLight;
  final PhysicallyBasedMaterial crtScreenMaterial;
  final List<PhysicallyBasedMaterial> tubeMaterials;
  final Node radioMeterNeedle;
}

Node _node({
  String name = '',
  Mesh? mesh,
  vm.Vector3? position,
  vm.Quaternion? rotation,
  vm.Vector3? scale,
}) {
  final n = Node(name: name, mesh: mesh);
  if (position != null) n.position = position;
  if (rotation != null) n.rotation = rotation;
  if (scale != null) n.scale = scale;
  return n;
}

/// Procedurally constructs the underground military radio bunker scene using
/// built-in `flutter_scene` primitives and physically based materials.
BunkerSceneRig buildBunkerScene() {
  final scene = Scene();

  final concreteMat = PhysicallyBasedMaterial()
    ..baseColorFactor = vm.Vector4(0.11, 0.12, 0.115, 1.0)
    ..metallicFactor = 0.05
    ..roughnessFactor = 0.94;

  final floorConcreteMat = PhysicallyBasedMaterial()
    ..baseColorFactor = vm.Vector4(0.08, 0.085, 0.082, 1.0)
    ..metallicFactor = 0.08
    ..roughnessFactor = 0.88;

  final darkSteelMat = PhysicallyBasedMaterial()
    ..baseColorFactor = vm.Vector4(0.14, 0.16, 0.15, 1.0)
    ..metallicFactor = 0.82
    ..roughnessFactor = 0.45;

  final oliveMetalMat = PhysicallyBasedMaterial()
    ..baseColorFactor = vm.Vector4(0.16, 0.21, 0.14, 1.0)
    ..metallicFactor = 0.55
    ..roughnessFactor = 0.56;

  final brushedBrassMat = PhysicallyBasedMaterial()
    ..baseColorFactor = vm.Vector4(0.88, 0.68, 0.28, 1.0)
    ..metallicFactor = 0.95
    ..roughnessFactor = 0.22;

  final darkBakeliteMat = PhysicallyBasedMaterial()
    ..baseColorFactor = vm.Vector4(0.04, 0.04, 0.045, 1.0)
    ..metallicFactor = 0.08
    ..roughnessFactor = 0.24;

  final mahoganyMat = PhysicallyBasedMaterial()
    ..baseColorFactor = vm.Vector4(0.24, 0.10, 0.05, 1.0)
    ..metallicFactor = 0.05
    ..roughnessFactor = 0.45;

  final deskWoodMat = PhysicallyBasedMaterial()
    ..baseColorFactor = vm.Vector4(0.18, 0.12, 0.08, 1.0)
    ..metallicFactor = 0.05
    ..roughnessFactor = 0.74;

  final deskMatMaterial = PhysicallyBasedMaterial()
    ..baseColorFactor = vm.Vector4(0.07, 0.11, 0.09, 1.0)
    ..metallicFactor = 0.04
    ..roughnessFactor = 0.88
    ..depthLayer = 1;

  final faceplateMat = PhysicallyBasedMaterial()
    ..baseColorFactor = vm.Vector4(0.06, 0.07, 0.068, 1.0)
    ..metallicFactor = 0.72
    ..roughnessFactor = 0.42
    ..depthLayer = 1;

  final dialWhiteMat = PhysicallyBasedMaterial()
    ..baseColorFactor = vm.Vector4(0.82, 0.80, 0.72, 1.0)
    ..metallicFactor = 0.1
    ..roughnessFactor = 0.6
    ..depthLayer = 2;

  final brassPlateMat = PhysicallyBasedMaterial()
    ..baseColorFactor = vm.Vector4(0.75, 0.58, 0.22, 1.0)
    ..metallicFactor = 0.9
    ..roughnessFactor = 0.3
    ..depthLayer = 1;

  // ---------------------------------------------------------------------------
  // 1. UNDERGROUND BUNKER ARCHITECTURE
  // ---------------------------------------------------------------------------
  final roomGroup = Node(name: 'bunker_room');

  roomGroup.add(_node(
    name: 'bunker_floor',
    mesh: Mesh(CuboidGeometry(vm.Vector3(7.2, 0.1, 7.2)), floorConcreteMat),
    position: vm.Vector3(0.0, -1.0, 0.0),
  ));

  roomGroup.add(_node(
    name: 'bunker_back_wall',
    mesh: Mesh(CuboidGeometry(vm.Vector3(7.2, 4.2, 0.2)), concreteMat),
    position: vm.Vector3(0.0, 1.15, 2.25),
  ));

  roomGroup.add(_node(
    name: 'bunker_left_wall',
    mesh: Mesh(CuboidGeometry(vm.Vector3(0.2, 4.2, 6.8)), concreteMat),
    position: vm.Vector3(-3.5, 1.15, -1.25),
  ));
  roomGroup.add(_node(
    name: 'bunker_right_wall',
    mesh: Mesh(CuboidGeometry(vm.Vector3(0.2, 4.2, 6.8)), concreteMat),
    position: vm.Vector3(3.5, 1.15, -1.25),
  ));

  roomGroup.add(_node(
    name: 'bunker_ceiling',
    mesh: Mesh(CuboidGeometry(vm.Vector3(7.0, 0.2, 7.0)), concreteMat),
    position: vm.Vector3(0.0, 3.25, -1.2),
  ));

  for (final zPos in [-0.9, 0.5, 1.75]) {
    roomGroup.add(_node(
      mesh: Mesh(CuboidGeometry(vm.Vector3(6.8, 0.18, 0.16)), darkSteelMat),
      position: vm.Vector3(0.0, 3.06, zPos),
    ));
  }
  for (final xPos in [-2.4, -0.8, 0.8, 2.4]) {
    roomGroup.add(_node(
      mesh: Mesh(CuboidGeometry(vm.Vector3(0.14, 4.0, 0.12)), darkSteelMat),
      position: vm.Vector3(xPos, 1.1, 2.09),
    ));
  }

  roomGroup.add(_node(
    name: 'vent_pipe',
    mesh: Mesh(
      CylinderGeometry(bottomRadius: 0.14, topRadius: 0.14, height: 6.4),
      darkSteelMat,
    ),
    position: vm.Vector3(0.0, 2.68, 1.85),
    rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), math.pi / 2),
  ));

  roomGroup.add(_node(
    mesh: Mesh(CuboidGeometry(vm.Vector3(3.2, 1.15, 0.06)), oliveMetalMat),
    position: vm.Vector3(0.0, 0.92, 1.98),
  ));

  roomGroup.add(_node(
    mesh: Mesh(CuboidGeometry(vm.Vector3(0.68, 0.82, 0.03)), darkSteelMat),
    position: vm.Vector3(0.12, 1.05, 1.93),
  ));
  roomGroup.add(_node(
    mesh: Mesh(CuboidGeometry(vm.Vector3(0.56, 0.70, 0.015)), dialWhiteMat),
    position: vm.Vector3(0.12, 1.05, 1.91),
  ));

  scene.add(roomGroup);

  // ---------------------------------------------------------------------------
  // 2. HEAVY MILITARY COMMUNICATIONS DESK (top surface at y = 0.0)
  // ---------------------------------------------------------------------------
  final deskGroup = Node(name: 'comms_desk');

  deskGroup.add(_node(
    mesh: Mesh(CuboidGeometry(vm.Vector3(3.1, 0.10, 1.48)), deskWoodMat),
    position: vm.Vector3(0.0, -0.05, 0.15),
  ));
  deskGroup.add(_node(
    mesh: Mesh(CuboidGeometry(vm.Vector3(3.16, 0.11, 0.04)), darkSteelMat),
    position: vm.Vector3(0.0, -0.055, -0.61),
  ));
  for (final xPos in [-1.35, 1.35]) {
    for (final zPos in [-0.45, 0.75]) {
      deskGroup.add(_node(
        mesh: Mesh(CuboidGeometry(vm.Vector3(0.10, 0.85, 0.10)), darkSteelMat),
        position: vm.Vector3(xPos, -0.525, zPos),
      ));
    }
  }
  deskGroup.add(_node(
    mesh: Mesh(PlaneGeometry(width: 1.55, depth: 0.92), deskMatMaterial),
    position: vm.Vector3(0.22, 0.002, -0.26),
  ));
  deskGroup.add(_node(
    mesh: Mesh(
      TorusGeometry(radius: 0.13, tubeRadius: 0.015),
      darkBakeliteMat,
    ),
    position: vm.Vector3(-0.24, 0.016, 0.18),
  ));

  scene.add(deskGroup);

  // ---------------------------------------------------------------------------
  // 3. HERO 3D MILITARY J-38 BRASS TELEGRAPH KEY (scaled & positioned front-right)
  // ---------------------------------------------------------------------------
  final telegraphKeyRoot = _node(
    name: 'telegraph_key_root',
    position: vm.Vector3(0.28, 0.0, -0.42),
    scale: vm.Vector3.all(1.55),
    rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), -0.22),
  );

  // Heavy mahogany wooden sub-plinth (y: 0.0 .. 0.016)
  telegraphKeyRoot.add(_node(
    name: 'telegraph_key_plinth',
    mesh: Mesh(CuboidGeometry(vm.Vector3(0.28, 0.016, 0.48)), mahoganyMat),
    position: vm.Vector3(0.0, 0.008, 0.0),
  ));

  // Beveled bakelite upper base (y: 0.016 .. 0.044)
  telegraphKeyRoot.add(_node(
    name: 'telegraph_key_base',
    mesh: Mesh(CuboidGeometry(vm.Vector3(0.23, 0.028, 0.42)), darkBakeliteMat),
    position: vm.Vector3(0.0, 0.030, 0.0),
  ));

  // Brass J-38 nameplate flush on front base (`depthLayer = 1`)
  telegraphKeyRoot.add(_node(
    name: 'telegraph_key_nameplate',
    mesh: Mesh(PlaneGeometry(width: 0.10, depth: 0.055), brassPlateMat),
    position: vm.Vector3(0.0, 0.045, -0.155),
  ));

  // Brass corner mounting screws
  for (final sx in [-0.09, 0.09]) {
    for (final sz in [-0.175, 0.175]) {
      telegraphKeyRoot.add(_node(
        name: 'telegraph_key_screw',
        mesh: Mesh(
          CylinderGeometry(bottomRadius: 0.011, topRadius: 0.011, height: 0.012),
          brushedBrassMat,
        ),
        position: vm.Vector3(sx, 0.049, sz),
      ));
    }
  }

  // Rear brass terminal binding posts & curved lead wire
  for (final tx in [-0.058, 0.058]) {
    telegraphKeyRoot.add(_node(
      name: 'telegraph_key_terminal',
      mesh: Mesh(
        CylinderGeometry(bottomRadius: 0.016, topRadius: 0.016, height: 0.044),
        brushedBrassMat,
      ),
      position: vm.Vector3(tx, 0.066, 0.16),
    ));
  }
  telegraphKeyRoot.add(_node(
    name: 'telegraph_key_lead',
    mesh: Mesh(
      CylinderGeometry(bottomRadius: 0.008, topRadius: 0.008, height: 0.18),
      darkBakeliteMat,
    ),
    position: vm.Vector3(-0.058, 0.052, 0.25),
    rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2),
  ));

  // Trunnion fulcrum saddle pillars (supporting pivot at y = 0.098, z = 0.04)
  for (final px in [-0.046, 0.046]) {
    telegraphKeyRoot.add(_node(
      name: 'telegraph_key_pillar',
      mesh: Mesh(CuboidGeometry(vm.Vector3(0.022, 0.072, 0.048)), brushedBrassMat),
      position: vm.Vector3(px, 0.080, 0.04),
    ));
  }
  telegraphKeyRoot.add(_node(
    name: 'telegraph_key_axle',
    mesh: Mesh(
      CylinderGeometry(bottomRadius: 0.010, topRadius: 0.010, height: 0.124),
      darkSteelMat,
    ),
    position: vm.Vector3(0.0, 0.098, 0.04),
    rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), math.pi / 2),
  ));

  // Coiled brass compression spring under the lever arm (scales along Y when pressed!)
  final telegraphSpringNode = _node(
    name: 'telegraph_spring_coil',
    position: vm.Vector3(0.0, 0.044, -0.02),
  );
  for (var i = 0; i < 4; i++) {
    telegraphSpringNode.add(_node(
      name: 'telegraph_spring_ring_$i',
      mesh: Mesh(
        TorusGeometry(radius: 0.022, tubeRadius: 0.0045),
        brushedBrassMat,
      ),
      position: vm.Vector3(0.0, 0.008 + i * 0.011, 0.0),
    ));
  }
  telegraphKeyRoot.add(telegraphSpringNode);

  // Fixed lower contact anvil at front (z = -0.09, top at y = 0.068)
  telegraphKeyRoot.add(_node(
    name: 'telegraph_key_anvil',
    mesh: Mesh(
      CylinderGeometry(bottomRadius: 0.022, topRadius: 0.018, height: 0.024),
      brushedBrassMat,
    ),
    position: vm.Vector3(0.0, 0.056, -0.09),
  ));

  // Contact spark micro-orb + micro PointLight at the contact gap
  final contactSparkMaterial = PhysicallyBasedMaterial()
    ..baseColorFactor = vm.Vector4(0.6, 0.9, 1.0, 1.0)
    ..roughnessFactor = 0.1
    ..emissiveFactor = vm.Vector4(0.45, 0.88, 1.0, 1.0)
    ..emissiveStrength = 0.0;
  final contactSparkNode = _node(
    name: 'telegraph_key_spark',
    mesh: Mesh(SphereGeometry(radius: 0.020), contactSparkMaterial),
    position: vm.Vector3(0.0, 0.072, -0.09),
    scale: vm.Vector3.all(0.001),
  );
  telegraphKeyRoot.add(contactSparkNode);

  final contactSparkLight = PointLight(
    color: vm.Vector3(0.55, 0.88, 1.0),
    intensity: 0.0,
    range: 1.8,
    radius: 0.02,
  );
  telegraphKeyRoot.add(
    _node(position: vm.Vector3(0.0, 0.076, -0.09))
      ..addComponent(PointLightComponent(contactSparkLight)),
  );

  // Pivoting brass lever arm: positive +X angle tilts front (-Z) knob UP at rest;
  // negative -X angle (-0.145) pushes the front (-Z) knob physically DOWNWARD onto the anvil.
  final telegraphLeverPivot = _node(
    name: 'telegraph_lever_pivot',
    position: vm.Vector3(0.0, 0.098, 0.04),
    rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), 0.085),
  );

  telegraphLeverPivot.add(_node(
    name: 'telegraph_lever_arm',
    mesh: Mesh(CuboidGeometry(vm.Vector3(0.032, 0.024, 0.34)), brushedBrassMat),
    position: vm.Vector3(0.0, 0.0, -0.05),
  ));
  telegraphLeverPivot.add(_node(
    name: 'telegraph_knob_stem',
    mesh: Mesh(
      CylinderGeometry(bottomRadius: 0.017, topRadius: 0.019, height: 0.028),
      brushedBrassMat,
    ),
    position: vm.Vector3(0.0, 0.024, -0.20),
  ));
  telegraphLeverPivot.add(_node(
    name: 'telegraph_knob_skirt',
    mesh: Mesh(
      CylinderGeometry(bottomRadius: 0.078, topRadius: 0.064, height: 0.012),
      darkBakeliteMat,
    ),
    position: vm.Vector3(0.0, 0.036, -0.20),
  ));
  telegraphLeverPivot.add(_node(
    name: 'telegraph_knob_cap',
    mesh: Mesh(
      CylinderGeometry(bottomRadius: 0.056, topRadius: 0.050, height: 0.026),
      darkBakeliteMat,
    ),
    position: vm.Vector3(0.0, 0.055, -0.20),
  ));
  // Gleaming brass center rivet on top of finger knob
  telegraphLeverPivot.add(_node(
    name: 'telegraph_knob_stud',
    mesh: Mesh(
      CylinderGeometry(bottomRadius: 0.012, topRadius: 0.012, height: 0.006),
      brushedBrassMat,
    ),
    position: vm.Vector3(0.0, 0.070, -0.20),
  ));

  // Tracking node right on top of the finger knob for exact 3D->2D reticle projection
  final knobTipNode = _node(
    name: 'telegraph_knob_tip',
    position: vm.Vector3(0.0, 0.074, -0.20),
  );
  telegraphLeverPivot.add(knobTipNode);

  telegraphLeverPivot.add(_node(
    name: 'telegraph_tension_screw',
    mesh: Mesh(
      CylinderGeometry(bottomRadius: 0.017, topRadius: 0.017, height: 0.042),
      brushedBrassMat,
    ),
    position: vm.Vector3(0.0, 0.024, 0.085),
  ));
  telegraphLeverPivot.add(_node(
    name: 'telegraph_upper_contact',
    mesh: Mesh(
      CylinderGeometry(bottomRadius: 0.012, topRadius: 0.012, height: 0.018),
      brushedBrassMat,
    ),
    position: vm.Vector3(0.0, -0.018, -0.13),
  ));

  telegraphKeyRoot.add(telegraphLeverPivot);
  scene.add(telegraphKeyRoot);

  // Warm key-spot accent light over the hero brass telegraph key so metal gleams
  scene.add(
    _node(position: vm.Vector3(0.45, 0.72, -0.95))
      ..addComponent(
        PointLightComponent(
          PointLight(
            color: vm.Vector3(1.0, 0.88, 0.66),
            intensity: 2.4,
            range: 3.5,
            radius: 0.08,
          ),
        ),
      ),
  );

  // ---------------------------------------------------------------------------
  // 4. VINTAGE MILITARY FIELD RADIO TRANSCEIVER (left-back of desk)
  // ---------------------------------------------------------------------------
  final radioRoot = _node(
    name: 'military_radio_root',
    position: vm.Vector3(-0.78, 0.0, 0.34),
    rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), 0.28),
  );

  radioRoot.add(_node(
    mesh: Mesh(CuboidGeometry(vm.Vector3(0.86, 0.48, 0.42)), oliveMetalMat),
    position: vm.Vector3(0.0, 0.24, 0.0),
  ));
  radioRoot.add(_node(
    mesh: Mesh(CuboidGeometry(vm.Vector3(0.78, 0.40, 0.02)), faceplateMat),
    position: vm.Vector3(0.0, 0.24, -0.215),
  ));

  final crtScreenMaterial = PhysicallyBasedMaterial()
    ..baseColorFactor = vm.Vector4(0.04, 0.16, 0.08, 1.0)
    ..roughnessFactor = 0.12
    ..metallicFactor = 0.1
    ..emissiveFactor = vm.Vector4(0.22, 1.0, 0.52, 1.0)
    ..emissiveStrength = 1.4
    ..depthLayer = 2;
  radioRoot.add(_node(
    mesh: Mesh(CuboidGeometry(vm.Vector3(0.28, 0.16, 0.015)), crtScreenMaterial),
    position: vm.Vector3(-0.18, 0.30, -0.226),
  ));

  radioRoot.add(_node(
    mesh: Mesh(
      CylinderGeometry(bottomRadius: 0.075, topRadius: 0.075, height: 0.016),
      dialWhiteMat,
    ),
    position: vm.Vector3(0.18, 0.31, -0.226),
    rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2),
  ));
  final radioMeterNeedle = _node(
    position: vm.Vector3(0.18, 0.29, -0.236),
  );
  radioMeterNeedle.add(_node(
    mesh: Mesh(
      CuboidGeometry(vm.Vector3(0.008, 0.055, 0.008)),
      PhysicallyBasedMaterial()
        ..baseColorFactor = vm.Vector4(0.85, 0.15, 0.1, 1.0)
        ..depthLayer = 3,
    ),
    position: vm.Vector3(0.0, 0.025, 0.0),
  ));
  radioRoot.add(radioMeterNeedle);

  for (final dx in [-0.24, 0.0, 0.24]) {
    radioRoot.add(_node(
      mesh: Mesh(
        CylinderGeometry(bottomRadius: 0.044, topRadius: 0.038, height: 0.04),
        darkSteelMat,
      ),
      position: vm.Vector3(dx, 0.12, -0.238),
      rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2),
    ));
  }

  for (final hx in [-0.45, 0.45]) {
    radioRoot.add(_node(
      mesh: Mesh(CuboidGeometry(vm.Vector3(0.03, 0.22, 0.06)), darkSteelMat),
      position: vm.Vector3(hx, 0.24, 0.0),
    ));
  }

  radioRoot.add(_node(
    mesh: Mesh(
      CylinderGeometry(bottomRadius: 0.012, topRadius: 0.004, height: 0.85),
      darkSteelMat,
    ),
    position: vm.Vector3(-0.34, 0.90, 0.10),
  ));

  final tubeMaterials = <PhysicallyBasedMaterial>[];
  for (var i = 0; i < 3; i++) {
    final tubeMat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.95, 0.45, 0.15, 1.0)
      ..roughnessFactor = 0.15
      ..emissiveFactor = vm.Vector4(1.0, 0.42, 0.12, 1.0)
      ..emissiveStrength = 1.6;
    tubeMaterials.add(tubeMat);
    radioRoot.add(_node(
      mesh: Mesh(
        CylinderGeometry(bottomRadius: 0.026, topRadius: 0.022, height: 0.095),
        tubeMat,
      ),
      position: vm.Vector3(-0.08 + i * 0.11, 0.525, 0.04),
    ));
  }

  scene.add(radioRoot);

  // ---------------------------------------------------------------------------
  // 5. TACTICAL SIGNAL BEACON / ALDIS LAMP (right-back of desk)
  // ---------------------------------------------------------------------------
  final beaconRoot = _node(
    name: 'signal_beacon_root',
    position: vm.Vector3(0.84, 0.0, 0.24),
    rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), -0.38),
  );

  beaconRoot.add(_node(
    mesh: Mesh(
      CylinderGeometry(bottomRadius: 0.14, topRadius: 0.11, height: 0.05),
      darkSteelMat,
    ),
    position: vm.Vector3(0.0, 0.025, 0.0),
  ));
  beaconRoot.add(_node(
    mesh: Mesh(
      CylinderGeometry(bottomRadius: 0.032, topRadius: 0.032, height: 0.22),
      darkSteelMat,
    ),
    position: vm.Vector3(0.0, 0.16, 0.0),
  ));

  beaconRoot.add(_node(
    mesh: Mesh(
      CylinderGeometry(bottomRadius: 0.13, topRadius: 0.13, height: 0.26),
      oliveMetalMat,
    ),
    position: vm.Vector3(0.0, 0.32, 0.0),
    rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2),
  ));

  beaconRoot.add(_node(
    mesh: Mesh(
      TorusGeometry(radius: 0.13, tubeRadius: 0.016),
      brushedBrassMat,
    ),
    position: vm.Vector3(0.0, 0.32, -0.13),
    rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2),
  ));

  final beaconLensMaterial = PhysicallyBasedMaterial()
    ..baseColorFactor = vm.Vector4(0.95, 0.85, 0.65, 1.0)
    ..roughnessFactor = 0.2
    ..emissiveFactor = vm.Vector4(1.0, 0.72, 0.18, 1.0)
    ..emissiveStrength = 0.12;
  beaconRoot.add(_node(
    mesh: Mesh(SphereGeometry(radius: 0.105), beaconLensMaterial),
    position: vm.Vector3(0.0, 0.32, -0.10),
  ));

  final signalPointLight = PointLight(
    color: vm.Vector3(1.0, 0.76, 0.25),
    intensity: 0.25,
    range: 7.5,
    radius: 0.12,
  );
  beaconRoot.add(
    _node(position: vm.Vector3(0.0, 0.34, -0.24))
      ..addComponent(PointLightComponent(signalPointLight)),
  );

  scene.add(beaconRoot);

  // ---------------------------------------------------------------------------
  // 6. OVERHEAD HANGING BUNKER LAMP WITH SHADOW-CASTING SPOTLIGHT
  // ---------------------------------------------------------------------------
  final overheadLampPivot = _node(
    name: 'overhead_lamp_pivot',
    position: vm.Vector3(0.05, 3.10, -0.05),
  );

  overheadLampPivot.add(_node(
    mesh: Mesh(
      CylinderGeometry(bottomRadius: 0.015, topRadius: 0.015, height: 1.15),
      darkSteelMat,
    ),
    position: vm.Vector3(0.0, -0.575, 0.0),
  ));

  overheadLampPivot.add(_node(
    mesh: Mesh(
      CylinderGeometry(bottomRadius: 0.36, topRadius: 0.10, height: 0.22),
      oliveMetalMat,
    ),
    position: vm.Vector3(0.0, -1.24, 0.0),
  ));

  final overheadBulbMaterial = PhysicallyBasedMaterial()
    ..baseColorFactor = vm.Vector4(1.0, 0.92, 0.78, 1.0)
    ..emissiveFactor = vm.Vector4(1.0, 0.84, 0.58, 1.0)
    ..emissiveStrength = 3.2;
  overheadLampPivot.add(_node(
    mesh: Mesh(SphereGeometry(radius: 0.07), overheadBulbMaterial),
    position: vm.Vector3(0.0, -1.32, 0.0),
  ));

  final overheadSpotLight = SpotLight(
    color: vm.Vector3(1.0, 0.84, 0.58),
    intensity: 16.5,
    range: 9.5,
    innerConeAngle: 0.42,
    outerConeAngle: 0.92,
    castsShadow: true,
    shadowMapResolution: 1024,
    shadowSoftness: 1.4,
    direction: vm.Vector3(0.0, -1.0, 0.02),
  );
  overheadLampPivot.add(
    _node(position: vm.Vector3(0.0, -1.36, 0.0))
      ..addComponent(SpotLightComponent(overheadSpotLight)),
  );

  scene.add(overheadLampPivot);

  // ---------------------------------------------------------------------------
  // 7. SUBTLE ATMOSPHERIC RIM FILL LIGHT
  // ---------------------------------------------------------------------------
  final fillPointLight = PointLight(
    color: vm.Vector3(0.32, 0.48, 0.42),
    intensity: 1.8,
    range: 9.0,
  );
  scene.add(
    _node(position: vm.Vector3(-1.6, 1.5, -1.8))
      ..addComponent(PointLightComponent(fillPointLight)),
  );

  return BunkerSceneRig(
    scene: scene,
    telegraphKeyRoot: telegraphKeyRoot,
    telegraphLeverPivot: telegraphLeverPivot,
    telegraphSpringNode: telegraphSpringNode,
    knobTipNode: knobTipNode,
    contactSparkNode: contactSparkNode,
    contactSparkMaterial: contactSparkMaterial,
    contactSparkLight: contactSparkLight,
    beaconLensMaterial: beaconLensMaterial,
    signalPointLight: signalPointLight,
    overheadLampPivot: overheadLampPivot,
    overheadSpotLight: overheadSpotLight,
    overheadBulbMaterial: overheadBulbMaterial,
    fillPointLight: fillPointLight,
    crtScreenMaterial: crtScreenMaterial,
    tubeMaterials: tubeMaterials,
    radioMeterNeedle: radioMeterNeedle,
  );
}
