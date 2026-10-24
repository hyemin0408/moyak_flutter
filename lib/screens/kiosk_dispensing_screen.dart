import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/kiosk_dispensing_preview_layout.dart';
import 'kiosk_dispensing_complete_screen.dart';

/// Developer UI sequence only; never starts a device or creates success signals.
class KioskDispensingScreen extends StatefulWidget {
  const KioskDispensingScreen.preview({
    super.key,
    required this.onFirstScreen,
    this.showMember = false,
    this.onLogout,
  });

  final VoidCallback onFirstScreen;
  final bool showMember;
  final VoidCallback? onLogout;

  @override
  State<KioskDispensingScreen> createState() => _KioskDispensingScreenState();
}

class _KioskDispensingScreenState extends State<KioskDispensingScreen> {
  bool _openingCompletion = false;

  void _previewCompletion() {
    if (!kDebugMode || _openingCompletion) return;
    _openingCompletion = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => KioskDispensingCompleteScreen.preview(
          onFirstScreen: widget.onFirstScreen,
          showMember: widget.showMember,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => KioskDispensingPreviewLayout(
    showMember: widget.showMember,
    onLogout: widget.onLogout,
    children: [
      Positioned(
        left: 64,
        top: 386,
        width: 952,
        height: 100,
        child: Container(
          decoration: KioskDispensingPreviewLayout.panel(),
          child: Center(
            child: KioskDispensingPreviewLayout.text(
              '결제가 완료되었어요',
              38,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ),
      Positioned(
        left: 64,
        top: 534,
        width: 952,
        height: 520,
        child: Container(
          decoration: KioskDispensingPreviewLayout.panel(color: Colors.white),
          child: Image.asset('assets/moyak_character.png', fit: BoxFit.contain),
        ),
      ),
      KioskDispensingPreviewLayout.slot(
        120,
        1098,
        840,
        56,
        KioskDispensingPreviewLayout.text(
          '약 배출구에서 약을 수령해 주세요.',
          38,
          weight: FontWeight.w800,
        ),
      ),
      Positioned(
        left: 250,
        top: 1180,
        width: 580,
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                value: 0.65,
                color: KioskDispensingPreviewLayout.yellow,
                strokeWidth: 4,
              ),
            ),
            const SizedBox(width: 20),
            KioskDispensingPreviewLayout.text('약 배출 테스트 진행 중', 28),
          ],
        ),
      ),
      Positioned(
        left: 64,
        top: 1290,
        width: 952,
        height: 205,
        child: Container(
          decoration: KioskDispensingPreviewLayout.panel(),
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              KioskDispensingPreviewLayout.text(
                '키오스크 하단의 약 배출구를 확인해 주세요.',
                28,
                weight: FontWeight.w800,
              ),
              const SizedBox(height: 14),
              KioskDispensingPreviewLayout.text(
                '약이 모두 배출될 때까지 수령구 안으로 손을 넣지 마세요.',
                24,
                color: const Color(0xFFFF4444),
              ),
              const SizedBox(height: 12),
              KioskDispensingPreviewLayout.text(
                '현재는 장치 미연결 상태로 실제 배출되지 않습니다.',
                24,
                color: KioskDispensingPreviewLayout.muted,
              ),
            ],
          ),
        ),
      ),
      if (kDebugMode)
        Positioned(
          left: 310,
          top: 1530,
          width: 460,
          height: 90,
          child: KioskDispensingPreviewLayout.button(
            'dispensing-preview-complete',
            '개발용 · 배출 완료 예시 보기',
            _previewCompletion,
          ),
        ),
    ],
  );
}
