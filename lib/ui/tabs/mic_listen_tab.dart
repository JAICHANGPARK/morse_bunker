import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:material_ui/material_ui.dart';
import 'package:morse_bunker/morse/morse_acoustic_decoder.dart';
import 'package:morse_bunker/morse/morse_keyer_controller.dart';
import 'package:morse_bunker/morse/morse_mic_live_controller.dart';
import 'package:morse_bunker/morse/morse_table.dart';
import 'package:morse_bunker/ui/bunker_theme.dart';

/// Tab 5: Live Microphone Morse Decoder (On-Device DSP + Gemini Live AI Interpreter).
class MicListenTab extends StatefulWidget {
  const MicListenTab({
    super.key,
    required this.keyerController,
    required this.micController,
    required this.accentColor,
  });

  final MorseKeyerController keyerController;
  final MorseMicLiveController micController;
  final Color accentColor;

  @override
  State<MicListenTab> createState() => _MicListenTabState();
}

class _MicListenTabState extends State<MicListenTab> {
  static const String _envApiKey = String.fromEnvironment('GEMINI_API_KEY');
  late final TextEditingController _apiKeyController;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: _envApiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.micController,
      builder: (context, _) {
        final mic = widget.micController;
        final decoder = mic.decoder;
        final live = mic.liveController;
        final accent = widget.accentColor;
        final transcripts = live?.transcripts ?? const <LiveTranscriptItem>[];

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // 1. On-Device Real-Time Acoustic DSP Decoder (Offline / No API Key Needed)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BunkerColors.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: decoder.isToneActive
                      ? accent
                      : BunkerColors.borderSubtle,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.hearing, size: 16, color: accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '마이크 실시간 음향 감청 (온디바이스 DSP)',
                          style: TextStyle(
                            color: accent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: decoder.isToneActive
                              ? accent
                              : const Color(0xFF2B3530),
                          boxShadow: decoder.isToneActive
                              ? [
                                  BoxShadow(
                                    color: accent,
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      GeminiLiveMicButton(
                        isRecording: mic.isListening,
                        size: 50,
                        iconSize: 24,
                        activeColor: accent,
                        inactiveColor: const Color(0xFF1A221E),
                        tooltip: mic.isListening ? '감청 중지' : '마이크 감청 시작',
                        onPressed: () {
                          if (mic.isListening) {
                            mic.stopListening();
                          } else {
                            mic.startListening();
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mic.isListening
                                  ? (decoder.mode == AcousticListenMode.cwTone
                                      ? '감청 중 · ${decoder.detectedFrequencyHz.round()} Hz (SNR ${decoder.signalSnrDb.toStringAsFixed(1)}dB)'
                                      : '감청 중 · 광대역 두드림 감지')
                                  : '마이크 버튼을 눌러 소리를 들려주세요',
                              style: TextStyle(
                                color: mic.isListening
                                    ? accent
                                    : BunkerColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              mic.statusMessage,
                              style: const TextStyle(
                                color: BunkerColors.textSecondary,
                                fontSize: 10.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: GeminiLiveWaveform(
                      audioStream: mic.micPcmStream,
                      barCount: 22,
                      width: 260,
                      height: 38,
                      barWidth: 4,
                      spacing: 4,
                      color: accent,
                      enableIdleBreathing: mic.isListening,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: AcousticListenMode.values.map((m) {
                      return TacticalChip(
                        label: m.label,
                        selected: decoder.mode == m,
                        accentColor: accent,
                        onTap: () => mic.setListenMode(m),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        '감지 민감도',
                        style: TextStyle(
                          color: BunkerColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: decoder.sensitivity,
                          min: 0.2,
                          max: 1.0,
                          divisions: 16,
                          activeColor: accent,
                          onChanged: mic.setSensitivity,
                        ),
                      ),
                      Text(
                        '${(decoder.sensitivity * 100).round()}%',
                        style: const TextStyle(
                          color: BunkerColors.textPrimary,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '음성 잡음 제거 (노크/일반 음성용 · CW 비프음은 OFF 권장)',
                          style: TextStyle(
                            color: BunkerColors.textSecondary,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: mic.noiseSuppressionEnabled,
                        onChanged: mic.setNoiseSuppression,
                        activeThumbColor: accent,
                      ),
                    ],
                  ),
                  const Divider(color: BunkerColors.borderSubtle, height: 16),
                  Row(
                    children: [
                      const Text(
                        '수신 버퍼:',
                        style: TextStyle(
                          color: BunkerColors.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          decoder.currentMorseBuffer.isEmpty
                              ? '신호 대기...'
                              : decoder.currentMorseBuffer,
                          style: TextStyle(
                            color: accent,
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...MorseLanguageMode.values.map((m) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: TacticalChip(
                            label: m == MorseLanguageMode.koreanSkats
                                ? '한글'
                                : '영문',
                            selected: widget.keyerController.languageMode == m,
                            accentColor: accent,
                            onTap: () {
                              widget.keyerController.setLanguageMode(m);
                              mic.syncDecoderSettings();
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0F0D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: BunkerColors.borderSubtle),
                    ),
                    child: SelectableText(
                      decoder.decodedText.isEmpty
                          ? '모스부호 비프음을 들려주면 여기에 실시간으로 해독됩니다.'
                          : decoder.decodedText,
                      style: TextStyle(
                        color: decoder.decodedText.isEmpty
                            ? BunkerColors.textMuted
                            : BunkerColors.textPrimary,
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: mic.commitBuffer,
                        icon: const Icon(Icons.check, size: 15),
                        label: const Text('글자 확정',
                            style: TextStyle(fontSize: 11.5)),
                        style: TextButton.styleFrom(foregroundColor: accent),
                      ),
                      const Spacer(),
                      if (decoder.decodedText.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: decoder.decodedText),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('마이크 해독 결과가 복사되었습니다.'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          color: accent,
                          tooltip: '복사',
                        ),
                      IconButton(
                        onPressed: mic.clearDecoded,
                        icon: const Icon(Icons.delete_outline, size: 17),
                        color: BunkerColors.textSecondary,
                        tooltip: '초기화',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2. Gemini Live AI Real-Time Interpreter (gemini_live package)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B110E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.55)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Gemini Live AI 무전 해석관',
                          style: TextStyle(
                            color: accent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GeminiLiveStatusBadge.fromFlags(
                        isConnected: mic.isGeminiConnected,
                        isConnecting: mic.isConnectingGemini,
                        customLabel: mic.isGeminiConnected
                            ? 'Live 연결됨'
                            : (mic.isConnectingGemini ? '연결 중...' : '미연결'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'gemini_live (gemini-3.8-live) 스트리밍으로 마이크 모스음·리듬·전술 약어를 AI가 실시간으로 청취해 해석합니다.',
                    style: TextStyle(
                      color: BunkerColors.textSecondary,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _apiKeyController,
                          obscureText: _obscureKey,
                          style: const TextStyle(
                            color: BunkerColors.textPrimary,
                            fontSize: 12.5,
                            fontFamily: 'monospace',
                          ),
                          decoration: InputDecoration(
                            hintText: 'Gemini API Key 입력 (AI Studio 키)',
                            hintStyle: const TextStyle(
                              color: BunkerColors.textMuted,
                              fontSize: 11.5,
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: const Color(0xFF070B09),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: BunkerColors.borderSubtle,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: BunkerColors.borderSubtle,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureKey
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                size: 16,
                              ),
                              color: BunkerColors.textSecondary,
                              onPressed: () =>
                                  setState(() => _obscureKey = !_obscureKey),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: mic.isConnectingGemini
                            ? null
                            : () {
                                if (mic.isGeminiConnected) {
                                  mic.disconnectGeminiLive();
                                } else {
                                  mic.connectGeminiLive(_apiKeyController.text);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mic.isGeminiConnected
                              ? const Color(0xFF31181A)
                              : accent,
                          foregroundColor: mic.isGeminiConnected
                              ? const Color(0xFFFF8A80)
                              : Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          mic.isGeminiConnected ? '연결 해제' : 'AI 연결',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TacticalChip(
                        label: mic.voiceOutputEnabled ? 'AI 음성+자막' : '텍스트만',
                        icon: mic.voiceOutputEnabled
                            ? Icons.record_voice_over
                            : Icons.text_snippet_outlined,
                        selected: mic.voiceOutputEnabled,
                        accentColor: accent,
                        onTap: () => mic.setVoiceOutputEnabled(
                          !mic.voiceOutputEnabled,
                        ),
                      ),
                      const Spacer(),
                      if (live != null)
                        GeminiLiveUsageBadge(
                          tracker: live.tokenTracker,
                          compact: true,
                          backgroundColor: const Color(0xFF131B17),
                          foregroundColor: accent,
                        ),
                    ],
                  ),
                  if (mic.geminiError.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D1416),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFF6B6B)),
                      ),
                      child: Text(
                        mic.geminiError,
                        style: const TextStyle(
                          color: Color(0xFFFFB4B4),
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: mic.isGeminiConnected
                          ? mic.askAiToInterpretCurrentBuffer
                          : null,
                      icon: const Icon(Icons.psychology_alt, size: 17),
                      label: const Text(
                        '현재 수신 모스부호 AI 정밀 해석 요청',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(
                          color: mic.isGeminiConnected
                              ? accent
                              : BunkerColors.borderSubtle,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  if (live?.latestTranscript != null &&
                      live!.latestTranscript!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    GeminiLiveCaptionBubble(
                      text: live.latestTranscript!,
                      role: live.latestTranscriptRole ?? 'model',
                      speaker: live.latestTranscriptRole == 'user'
                          ? '수신/요청'
                          : 'AI 통신교관',
                      isStreaming: live.isModelSpeaking,
                      enableBlur: !kIsWeb,
                      autoDismissDuration: null,
                      backgroundColor: const Color(0xFF141D19),
                      textColor: BunkerColors.textPrimary,
                    ),
                  ],
                  if (transcripts.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      '해석 기록',
                      style: TextStyle(
                        color: BunkerColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...transcripts.reversed.take(4).map((item) {
                      final isModel = item.role == 'model';
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: isModel
                              ? const Color(0xFF121A16)
                              : const Color(0xFF0E1311),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: BunkerColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isModel ? 'AI 통신교관' : '사용자 / DSP',
                              style: TextStyle(
                                color: isModel
                                    ? accent
                                    : BunkerColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.text,
                              style: const TextStyle(
                                color: BunkerColors.textPrimary,
                                fontSize: 11.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
