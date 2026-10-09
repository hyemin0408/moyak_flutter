import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak_flutter/screens/kiosk_device_pairing_screen.dart';

void main() {
  testWidgets(
    'Pairing prototype fits different sizes and never reports connection success',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final size in [
        const Size(1080, 1920),
        const Size(540, 960),
        const Size(1920, 1080),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          const MaterialApp(home: KioskDevicePairingScreen()),
        );
        await tester.pumpAndSettle();
        expect(find.text('기기 고유 연동'), findsOneWidget);
        expect(find.text('앱에서 기기 QR을 스캔해주세요'), findsOneWidget);
        expect(find.text('자판기 고유인증 키: MD-2409-ROME'), findsOneWidget);
        expect(find.text('임시 QR · 실제 연동 불가'), findsOneWidget);
        expect(find.text('스마트폰 연동 대기 중...'), findsOneWidget);
        expect(
          tester
              .widget<CircularProgressIndicator>(
                find.byType(CircularProgressIndicator),
              )
              .value,
          0.75,
        );
        await tester.pump(const Duration(seconds: 30));
        expect(find.text('스마트폰 연동 대기 중...'), findsOneWidget);
        expect(find.text('연동 완료'), findsNothing);
        for (final key in ['pairing-back', 'pairing-language']) {
          final bounds = tester.getRect(find.byKey(ValueKey(key)));
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(size.width));
          expect(bounds.top, greaterThanOrEqualTo(0));
          expect(bounds.bottom, lessThanOrEqualTo(size.height));
        }
        expect(tester.takeException(), isNull);
      }
    },
  );
}
