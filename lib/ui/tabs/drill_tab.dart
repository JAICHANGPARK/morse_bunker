import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:morse_bunker/morse/morse_keyer_controller.dart';
import 'package:morse_bunker/morse/morse_table.dart';
import 'package:morse_bunker/ui/bunker_theme.dart';

enum _DrillMode { receive, transmit }

enum _DrillPool {
  basic('초급 문자 (E T I A N M S O)'),
  alphabet('전체 알파벳 A-Z'),
  digits('숫자 0-9'),
  tactical('군사 약어·단어 (SOS, CQ, ROGER)');

  const _DrillPool(this.label);
  final String label;
}

enum _SignalChannel {
  both('소리 + 3D 램프'),
  audioOnly('소리만 (청각 집중)'),
  lampOnly('3D 램프만 (암실 시각)');

  const _SignalChannel(this.label);
  final String label;
}

/// Tab 4: Applied Military Receive & Transmit Drills with Rank Progression.
class DrillTab extends StatefulWidget {
  const DrillTab({
    super.key,
    required this.controller,
    required this.accentColor,
  });

  final MorseKeyerController controller;
  final Color accentColor;

  @override
  State<DrillTab> createState() => _DrillTabState();
}

class _DrillTabState extends State<DrillTab> {
  final math.Random _rng = math.Random();
  _DrillMode _mode = _DrillMode.receive;
  _DrillPool _pool = _DrillPool.basic;
  _SignalChannel _channel = _SignalChannel.both;

  late String _targetItem;
  List<String> _choices = [];
  String? _selectedAnswer;
  bool _showHint = false;
  String _transmitFeedback = '';

  static const List<String> _basicItems = ['E', 'T', 'I', 'A', 'N', 'M', 'S', 'O'];
  static const List<String> _tacticalWords = [
    'SOS',
    'CQ',
    'K',
    'ROGER',
    'ALPHA',
    'BRAVO',
    'BASE',
    'QTH',
  ];

  @override
  void initState() {
    super.initState();
    _generateNextChallenge(autoPlay: false);
  }

  List<String> get _currentPoolItems {
    switch (_pool) {
      case _DrillPool.basic:
        return _basicItems;
      case _DrillPool.alphabet:
        return kAlphabetEntries.map((e) => e.symbol).toList();
      case _DrillPool.digits:
        return kDigitEntries.map((e) => e.symbol).toList();
      case _DrillPool.tactical:
        return _tacticalWords;
    }
  }

  void _generateNextChallenge({bool autoPlay = true}) {
    final items = _currentPoolItems;
    final target = items[_rng.nextInt(items.length)];
    final choiceSet = <String>{target};
    while (choiceSet.length < 4 && choiceSet.length < items.length) {
      choiceSet.add(items[_rng.nextInt(items.length)]);
    }
    final shuffled = choiceSet.toList()..shuffle(_rng);

    setState(() {
      _targetItem = target;
      _choices = shuffled;
      _selectedAnswer = null;
      _showHint = false;
      _transmitFeedback = '';
    });

    if (autoPlay && _mode == _DrillMode.receive) {
      _playCurrentChallenge();
    }
  }

  void _playCurrentChallenge() {
    final showLamp = _channel != _SignalChannel.audioOnly;
    final playAudio = _channel != _SignalChannel.lampOnly;
    widget.controller.playTextDemo(
      _targetItem,
      mode: MorseLanguageMode.romanized,
      showLamp: showLamp,
      playAudio: playAudio,
    );
  }

  void _handleChoiceTap(String choice) {
    if (_selectedAnswer != null) return;
    final correct = choice == _targetItem;
    setState(() => _selectedAnswer = choice);
    widget.controller.recordDrillResult(correct, points: _pool == _DrillPool.tactical ? 25 : 15);
  }

  void _evaluateTransmittedBuffer() {
    widget.controller.commitBufferedCharacter();
    final raw = widget.controller.decodedText.trim().toUpperCase();
    if (raw.isEmpty) {
      setState(() => _transmitFeedback = '먼저 전건으로 부호를 입력해 주세요.');
      return;
    }
    final correct = raw == _targetItem.toUpperCase();
    widget.controller.recordDrillResult(correct, points: 25);
    setState(() {
      _transmitFeedback = correct
          ? '완벽한 송신입니다! ($_targetItem)'
          : '해독 결과: "$raw" (목표: "$_targetItem"). 다시 도전해보세요!';
    });
    if (correct) {
      widget.controller.clearDecodedText();
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted && _mode == _DrillMode.transmit) {
          _generateNextChallenge(autoPlay: false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final targetMorse = encodeTextToMorse(
      _targetItem,
      mode: MorseLanguageMode.romanized,
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // 1. Military Rank & Score Summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BunkerColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.accentColor.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Icon(Icons.military_tech, color: widget.accentColor, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ctrl.militaryRank,
                      style: TextStyle(
                        color: widget.accentColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '점수 ${ctrl.drillScore} · 연속 ${ctrl.drillStreak}회 · 정확도 ${(ctrl.drillAccuracy * 100).round()}%',
                      style: const TextStyle(
                        color: BunkerColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 2. Mode & Pool Selectors
        Row(
          children: [
            Expanded(
              child: TacticalChip(
                label: '수신 훈련 (해독)',
                icon: Icons.hearing,
                selected: _mode == _DrillMode.receive,
                accentColor: widget.accentColor,
                onTap: () {
                  setState(() => _mode = _DrillMode.receive);
                  _generateNextChallenge(autoPlay: false);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TacticalChip(
                label: '송신 훈련 (직접 타건)',
                icon: Icons.touch_app,
                selected: _mode == _DrillMode.transmit,
                accentColor: widget.accentColor,
                onTap: () {
                  ctrl.clearDecodedText();
                  setState(() => _mode = _DrillMode.transmit);
                  _generateNextChallenge(autoPlay: false);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _DrillPool.values.map((pool) {
            return TacticalChip(
              label: pool.label,
              selected: _pool == pool,
              accentColor: widget.accentColor,
              onTap: () {
                setState(() => _pool = pool);
                _generateNextChallenge(autoPlay: false);
              },
            );
          }).toList(),
        ),

        if (_mode == _DrillMode.receive) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _SignalChannel.values.map((ch) {
              return TacticalChip(
                label: ch.label,
                selected: _channel == ch,
                accentColor: widget.accentColor,
                onTap: () => setState(() => _channel = ch),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 12),

        // 3. Challenge Card
        if (_mode == _DrillMode.receive)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0A100D),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BunkerColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '암실/무전 수신 신호를 해독하세요',
                  style: TextStyle(
                    color: widget.accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _playCurrentChallenge,
                        icon: Icon(
                          ctrl.isPlayingDemo ? Icons.graphic_eq : Icons.play_arrow,
                          size: 18,
                        ),
                        label: Text(
                          ctrl.isPlayingDemo ? '신호 송출 중...' : '무전 신호 받기',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.accentColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => setState(() => _showHint = !_showHint),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.accentColor,
                        side: BorderSide(color: widget.accentColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                      ),
                      child: Text(_showHint ? '힌트 숨김' : '부호 힌트'),
                    ),
                  ],
                ),
                if (_showHint) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      targetMorse,
                      style: TextStyle(
                        color: widget.accentColor,
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.6,
                  children: _choices.map((choice) {
                    final isSelected = _selectedAnswer == choice;
                    final isTarget = choice == _targetItem;
                    Color borderColor = BunkerColors.borderSubtle;
                    Color bgColor = const Color(0xFF131A17);
                    if (_selectedAnswer != null) {
                      if (isTarget) {
                        borderColor = const Color(0xFF4ADE80);
                        bgColor = const Color(0xFF153122);
                      } else if (isSelected) {
                        borderColor = const Color(0xFFFF5252);
                        bgColor = const Color(0xFF311416);
                      }
                    }
                    return InkWell(
                      onTap: () => _handleChoiceTap(choice),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor, width: 1.3),
                        ),
                        child: Text(
                          choice,
                          style: const TextStyle(
                            color: BunkerColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_selectedAnswer != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        _selectedAnswer == _targetItem
                            ? Icons.check_circle
                            : Icons.error_outline,
                        color: _selectedAnswer == _targetItem
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFFFF6B6B),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _selectedAnswer == _targetItem
                              ? '정답입니다! ($_targetItem = $targetMorse)'
                              : '오답입니다. 정답은 $_targetItem ($targetMorse)',
                          style: const TextStyle(
                            color: BunkerColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _generateNextChallenge(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.accentColor,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('다음 문제'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0A100D),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BunkerColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '목표 전문을 전건으로 직접 송신하세요',
                  style: TextStyle(
                    color: widget.accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121A17),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.accentColor.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _targetItem,
                        style: TextStyle(
                          color: widget.accentColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _showHint ? targetMorse : '부호 가림 (필요 시 힌트 보기)',
                        style: const TextStyle(
                          color: BunkerColors.textSecondary,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '현재 입력: ${ctrl.decodedText}${ctrl.currentMorseBuffer.isNotEmpty ? ' [${ctrl.currentMorseBuffer}]' : ''}',
                  style: const TextStyle(
                    color: BunkerColors.textPrimary,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Direct3DKeyGuideBanner(
                  controller: ctrl,
                  accentColor: widget.accentColor,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => setState(() => _showHint = !_showHint),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.accentColor,
                        side: BorderSide(color: widget.accentColor),
                      ),
                      child: Text(_showHint ? '힌트 숨김' : '힌트'),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: ctrl.clearDecodedText,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BunkerColors.textSecondary,
                        side: const BorderSide(color: BunkerColors.borderSubtle),
                      ),
                      child: const Text('지우기'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _evaluateTransmittedBuffer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.accentColor,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('송신 채점하기'),
                      ),
                    ),
                  ],
                ),
                if (_transmitFeedback.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _transmitFeedback,
                    style: TextStyle(
                      color: widget.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
