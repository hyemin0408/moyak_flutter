import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak_flutter/main.dart';
import 'package:moyak_flutter/preview_auth_complete.dart';
import 'package:moyak_flutter/screens/kiosk_auth_complete_screen.dart';
import 'package:moyak_flutter/screens/kiosk_device_pairing_screen.dart';

void main() {
  testWidgets(
    'Completion preview matches example text without extra controls and fits screens',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.runAsync(() async {
        for (final font in ['Inter', 'NotoSansKR']) {
          final loader = FontLoader(
            font == 'Inter' ? 'MenuInter' : 'MenuKorean',
          );
          loader.addFont(rootBundle.load('assets/fonts/$font.ttf'));
          await loader.load();
        }
      });
      final previewKey = GlobalKey();
      for (final size in [
        const Size(1080, 1920),
        const Size(540, 960),
        const Size(1920, 1080),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          MaterialApp(
            home: RepaintBoundary(
              key: previewKey,
              child: const KioskAuthCompleteScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('본인인증 완료'), findsOneWidget);
        expect(find.text('지*민님 환영합니다'), findsOneWidget);
        expect(find.text('본인 연동 및 안전 거래 한도가 활성화되었습니다.'), findsOneWidget);
        expect(find.text('안내 및 보안 주의 사항'), findsOneWidget);
        expect(
          find.text('- 약품 결제가 완료되면 회원 정보가 안전을 위해 자동 로그아웃됩니다.'),
          findsOneWidget,
        );
        expect(find.byType(InkWell), findsNothing);
        expect(find.byType(TextField), findsNothing);
        final icon = tester.getRect(find.byType(CustomPaint).last);
        expect(icon.center.dx, closeTo(size.width / 2, 1));
        expect(tester.takeException(), isNull);
        if (size.width == 1080) {
          await tester.runAsync(() async {
            final boundary =
                previewKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory('build').create(recursive: true);
            await File('build/moyak_auth_complete_preview.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
    },
  );

  testWidgets(
    'Preview entry is separate from normal app and no pairing success is simulated',
    (tester) async {
      await tester.pumpWidget(const AuthCompletePreviewApp());
      expect(find.byType(KioskAuthCompleteScreen), findsOneWidget);
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.byType(KioskStartScreen), findsOneWidget);
      expect(find.byType(KioskAuthCompleteScreen), findsNothing);
      await tester.pumpWidget(
        const MaterialApp(home: KioskDevicePairingScreen()),
      );
      await tester.pump(const Duration(minutes: 1));
      expect(find.text('스마트폰 연동 대기 중...'), findsOneWidget);
      expect(find.byType(KioskAuthCompleteScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
