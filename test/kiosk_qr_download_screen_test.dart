import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak_flutter/main.dart';
import 'package:moyak_flutter/screens/kiosk_menu_screen.dart';
import 'package:moyak_flutter/screens/kiosk_qr_download_screen.dart';
import 'package:moyak_flutter/screens/kiosk_device_pairing_screen.dart';
import 'package:moyak_flutter/screens/kiosk_usage_guide_screen.dart';

void main() {
  testWidgets(
    'QR placeholder and deferred pairing remain visible at different sizes',
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
          const MaterialApp(home: KioskQrDownloadScreen()),
        );
        await tester.pumpAndSettle();
        expect(find.text('QR 코드 준비 중'), findsOneWidget);
        expect(find.text('현재 스캔 불가'), findsOneWidget);
        expect(find.text('QR 스캔 & 설치'), findsOneWidget);
        expect(find.text('본인인증 완료'), findsOneWidget);
        expect(find.text('자판기 연동'), findsOneWidget);
        expect(find.text("카메라로 스캔하여 마켓에서 '모약' 앱을 설치하세요."), findsOneWidget);
        for (final key in ['qr-pair-next', 'qr-back']) {
          final bounds = tester.getRect(find.byKey(ValueKey(key)));
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.top, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(size.width));
          expect(bounds.bottom, lessThanOrEqualTo(size.height));
        }
        await tester.tap(find.byKey(const ValueKey('qr-pair-next')));
        await tester.pumpAndSettle();
        expect(find.byType(KioskDevicePairingScreen), findsOneWidget);
        expect(find.text('임시 QR · 실제 연동 불가'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('pairing-back')));
        await tester.pumpAndSettle();
        expect(find.byType(KioskQrDownloadScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('Second home menu opens QR guide and back restores home', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-route-1')));
    await tester.pumpAndSettle();
    expect(find.byType(KioskQrDownloadScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('qr-pair-next')));
    await tester.pumpAndSettle();
    expect(find.byType(KioskDevicePairingScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pairing-back')));
    await tester.pumpAndSettle();
    expect(find.byType(KioskQrDownloadScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('qr-back')));
    await tester.pumpAndSettle();
    expect(find.byType(KioskMenuScreen), findsOneWidget);
    expect(find.byType(KioskQrDownloadScreen), findsNothing);
    await tester.tap(find.byKey(const ValueKey('menu-route-2')));
    await tester.pumpAndSettle();
    expect(find.byType(KioskUsageGuideScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('usage-back')));
    await tester.pumpAndSettle();
    expect(find.byType(KioskMenuScreen), findsOneWidget);
  });
}
