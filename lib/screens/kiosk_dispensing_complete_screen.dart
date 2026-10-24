import 'package:flutter/material.dart';

import '../widgets/kiosk_dispensing_preview_layout.dart';

/// Visual example only. Not a payment, dispensing, or collection receipt.
class KioskDispensingCompleteScreen extends StatelessWidget {
  const KioskDispensingCompleteScreen.preview({
    super.key,
    required this.onFirstScreen,
    this.showMember = false,
    this.onLogout,
  });

  final VoidCallback onFirstScreen;
  final bool showMember;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: KioskDispensingPreviewLayout(
      showMember: showMember,
      onLogout: onLogout,
      children: [
        Positioned(
          left: 450,
          top: 595,
          width: 180,
          height: 180,
          child: Container(
            decoration: KioskDispensingPreviewLayout.panel(),
            child: const Icon(
              Icons.check_circle_outline,
              size: 100,
              color: KioskDispensingPreviewLayout.brown,
            ),
          ),
        ),
        KioskDispensingPreviewLayout.slot(
          120,
          845,
          840,
          68,
          KioskDispensingPreviewLayout.text(
            '약 배출이 완료되었어요',
            48,
            weight: FontWeight.w800,
          ),
        ),
        KioskDispensingPreviewLayout.slot(
          180,
          940,
          720,
          48,
          KioskDispensingPreviewLayout.text(
            '배출구에서 약을 챙겨 주세요.',
            30,
            color: KioskDispensingPreviewLayout.muted,
          ),
        ),
        Positioned(
          left: 140,
          top: 1080,
          width: 800,
          height: 160,
          child: Container(
            decoration: KioskDispensingPreviewLayout.panel(),
            padding: const EdgeInsets.all(30),
            child: Center(
              child: KioskDispensingPreviewLayout.text(
                '테스트용 배출 완료 화면입니다.\n실제 약 배출이나 수령 완료는 확인되지 않았습니다.',
                26,
                color: KioskDispensingPreviewLayout.muted,
              ),
            ),
          ),
        ),
        Positioned(
          left: 310,
          top: 1490,
          width: 460,
          height: 90,
          child: KioskDispensingPreviewLayout.button(
            'dispensing-first-screen',
            '첫 화면으로',
            onFirstScreen,
          ),
        ),
      ],
    ),
  );
}
