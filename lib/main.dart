import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:morse_bunker/morse/morse_keyer_controller.dart';
import 'package:morse_bunker/morse/morse_mic_live_controller.dart';
import 'package:morse_bunker/ui/morse_bunker_home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MorseBunkerApp());
}

/// Root widget for Morse Bunker 3D Morse Code Learning App.
class MorseBunkerApp extends StatefulWidget {
  const MorseBunkerApp({
    super.key,
    this.useMockScene = false,
  });

  final bool useMockScene;

  @override
  State<MorseBunkerApp> createState() => _MorseBunkerAppState();
}

class _MorseBunkerAppState extends State<MorseBunkerApp> {
  late final MorseKeyerController _controller;
  late final MorseMicLiveController _micController;

  @override
  void initState() {
    super.initState();
    _controller = MorseKeyerController(enableAudio: !widget.useMockScene);
    _micController = MorseMicLiveController(
      keyerController: _controller,
      enableMic: !widget.useMockScene,
    );
    // On Web, browsers block AudioContext until a user gesture; MorseKeyerController
    // lazily unlocks SoLoud on the first click/tap/Spacebar press.
    if (!widget.useMockScene && !kIsWeb) {
      _controller.initAudio();
    }
  }

  @override
  void dispose() {
    _micController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Morse Bunker 3D',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF070B09),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF5A623),
          secondary: Color(0xFF4ADE80),
          surface: Color(0xFF101614),
        ),
      ),
      home: MorseBunkerHome(
        controller: _controller,
        micController: _micController,
        useMockScene: widget.useMockScene,
      ),
    );
  }
}
