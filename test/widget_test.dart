import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_bunker/main.dart';

void main() {
  testWidgets('MorseBunkerApp renders all 4 tabs and converts text to keying guide',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 820);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MorseBunkerApp(useMockScene: true));
    await tester.pump();

    expect(find.text('기초학습'), findsOneWidget);
    expect(find.text('변환·가이드'), findsOneWidget);
    expect(find.text('자유송신'), findsOneWidget);
    expect(find.text('실전훈련'), findsOneWidget);
    expect(find.text('마이크 해독'), findsOneWidget);

    // Switch to Text-to-Morse Guide tab
    await tester.tap(find.text('변환·가이드'));
    await tester.pumpAndSettle();

    expect(find.text('텍스트 → 모스부호 입력법 변환기'), findsOneWidget);
    expect(find.text('··· −−− ···'), findsOneWidget);

    // Enter Korean phrase using preset chip
    await tester.tap(find.text('구조 요청'));
    await tester.pumpAndSettle();
    expect(find.textContaining('글자별 실제 전건 타건 가이드'), findsOneWidget);

    // Switch to Free Keyer & Drill tabs
    await tester.tap(find.text('자유송신'));
    await tester.pumpAndSettle();
    expect(find.text('실시간 CW 신호 오실로스코프'), findsOneWidget);

    await tester.tap(find.text('실전훈련'));
    await tester.pumpAndSettle();
    expect(find.text('수신 훈련 (해독)'), findsOneWidget);

    // Switch to Mic Listen & Gemini Live tab (GeminiLiveWaveform runs a continuous ticker)
    await tester.tap(find.text('마이크 해독'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('마이크 실시간 음향 감청 (온디바이스 DSP)'), findsOneWidget);
    expect(find.text('Gemini Live AI 무전 해석관'), findsOneWidget);

    // Switch atmosphere pill
    await tester.tap(find.text('암실 적색등'));
    await tester.pump();
  });
}
