# Morse Bunker 3D

**Flutter Scene (`flutter_gpu` / WebGL2)**, **Flutter SoLoud**, **온디바이스 음향 DSP**, **Gemini Live (`gemini_live`)**를 결합한 3D 지하 벙커·암실 모스부호 학습 애플리케이션입니다.

- **Live Web Demo**: https://morse-bunker-3d.web.app

---

## 주요 기능

1. **실시간 3D 지하 벙커 / 암실 / 야간 작전실 (`flutter_scene` + `flutter_gpu`)**
   - 절차적으로 구축한 콘크리트 벙커, 철골 빔, 천장 스포트라이트 그림자, 진공관 군용 무전기(CRT 오실로스코프), 신호 램프, J-38 황동 전건
   - 3가지 분위기 전환 (`지하 벙커`, `암실 적색등`, `야간 작전실`) 및 3가지 카메라 시점 (`전건실 기본`, `전건 클로즈업`, `벙커 전체`)
2. **물리적 3D 전건 직접 타건 UX**
   - 화면 속 3D 황동 전건 손잡이를 직접 클릭·터치로 꾹 눌러 타건 (스프링 압축, 접점 스파크, 금속 클릭/복원음, 미세 카메라 반동, 3D 손잡이 위 실시간 `· 단음 / − 장음` ms 뱃지)
   - `Space` 바 입력 및 3D 시점 드래그 회전 지원
3. **기초부터 응용까지 5개 학습 콘솔**
   - **기초학습**: ITU `1:3` 및 `1-3-7` 규칙 시각화, 6단계 커리큘럼, 클릭 시 3D 시연하는 인터랙티브 부호표 (`A-Z`, `0-9`, `한글 SKATS`, `군사·비상 약어`)
   - **변환·가이드**: 사용자가 입력한 영문/한글(SKATS·로마자) 텍스트를 글자별 타건법(`짧게(100ms) → 100ms 쉼 → 길게(300ms)`)으로 분해 안내 + 3D 시범 송신 + 따라 치기 실습
   - **자유송신**: 실시간 CW 오실로스코프, 단음/장음 임계선 게이지, 텔레타이프 자동 해독기, WPM(5–25)·판스워스·주파수 설정
   - **실전훈련**: 소리+3D 램프 / 소리만 / 암실 3D 램프만 수신 해독 훈련 및 직접 타건 송신 훈련, 군사 계급 진급 시스템
   - **마이크 해독**: 온디바이스 Goertzel(`400–1100 Hz`) 비프음/노크 DSP 해독기 + `gemini_live`(`gemini-3.8-live`) 실시간 AI 무전 해석관

---

## 기술 스택

- **3D / GPU**: `flutter_scene`, `flutter_gpu`, `vector_math`
- **Audio**: `flutter_soloud` (연속 CW 사인파 + 합성 금속 클릭음 + 24 kHz Gemini Live 음성 출력)
- **Mic & AI**: `record`, `gemini_live` (`gemini-3.8-live`)

---

## 실행 및 빌드

```bash
flutter pub get

# macOS 네이티브 (Flutter GPU)
flutter run -d macos --enable-flutter-gpu

# Web (Chrome, WebGL2 + Web Audio WASM)
flutter run -d chrome

# 테스트
flutter analyze
flutter test

# Web 릴리즈 빌드 & Firebase Hosting 배포
flutter build web --release
npx -y firebase-tools@latest deploy --only hosting:morse-bunker-3d
```
