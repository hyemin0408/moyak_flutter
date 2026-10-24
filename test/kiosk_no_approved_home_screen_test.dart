import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak_flutter/main.dart';
import 'package:moyak_flutter/preview_no_approved_home.dart';
import 'package:moyak_flutter/screens/kiosk_menu_screen.dart';
import 'package:moyak_flutter/screens/kiosk_no_approved_home_screen.dart';
import 'package:moyak_flutter/screens/kiosk_usage_guide_screen.dart';

void main() {
  testWidgets(
    'No approvals home scales and provides a safe consultation hook',
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
          const MaterialApp(home: KioskNoApprovedHomeScreen()),
        );
        await tester.pumpAndSettle();
        expect(find.text('아직 승인된 약이 없어요'), findsOneWidget);
        expect(find.text('현재 수령할 수 있는 승인된 약이 없습니다.'), findsOneWidget);
        expect(find.text('약사 상담 안내'), findsOneWidget);
        expect(find.text('앱 이용 방법 확인하기'), findsOneWidget);
        expect(
          find.text('앱 연결 기능이 준비되면 실제 상담 화면으로 연결할 수 있어요.'),
          findsOneWidget,
        );
        expect(find.text('약사 상담은 휴대폰 MOYAK 앱에서 진행할 수 있어요.'), findsOneWidget);
        expect(find.text('지*민 님'), findsOneWidget);
        expect(find.text('2'), findsNothing);
        final bounds = tester.getRect(
          find.byKey(const ValueKey('no-approved-consultation')),
        );
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(size.width));
        expect(bounds.bottom, lessThanOrEqualTo(size.height));
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byKey(const ValueKey('no-approved-consultation')));
      await tester.pumpAndSettle();
      expect(find.text('MOYAK 앱 이용 안내'), findsOneWidget);
      expect(find.textContaining('앱 실행·딥링크·QR 연결 기능은 준비 중'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('no-approved-existing-guide')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(KioskUsageGuideScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('usage-back')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskNoApprovedHomeScreen), findsOneWidget);
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: KioskNoApprovedHomeScreen(onUsageGuide: () => calls++),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('no-approved-consultation')));
      expect(calls, 1);
    },
  );

  testWidgets(
    'Separate preview logs out to general home and preserves normal entry',
    (tester) async {
      await tester.pumpWidget(const NoApprovedHomePreviewApp());
      await tester.pumpAndSettle();
      expect(find.byType(KioskNoApprovedHomeScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('no-approved-logout')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskMenuScreen), findsOneWidget);
      expect(
        find.byType(KioskNoApprovedHomeScreen, skipOffstage: false),
        findsNothing,
      );
      Navigator.of(tester.element(find.byType(KioskMenuScreen))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(KioskStartScreen), findsOneWidget);
    },
  );
}
