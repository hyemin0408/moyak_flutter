import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak_flutter/main.dart';
import 'package:moyak_flutter/preview_auth_complete.dart';
import 'package:moyak_flutter/screens/kiosk_auth_complete_screen.dart';
import 'package:moyak_flutter/screens/kiosk_linked_home_screen.dart';
import 'package:moyak_flutter/screens/kiosk_menu_screen.dart';
import 'package:moyak_flutter/screens/kiosk_product_list_screen.dart';
import 'package:moyak_flutter/screens/kiosk_qr_download_screen.dart';
import 'package:moyak_flutter/screens/kiosk_usage_guide_screen.dart';

void main() {
  testWidgets(
    'Linked home fits portrait and landscape and keeps all example actions safe',
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
          const MaterialApp(home: KioskLinkedHomeScreen()),
        );
        await tester.pumpAndSettle();
        expect(find.text('승인받은 약이 있습니다!'), findsOneWidget);
        expect(find.text('타이레놀 외 1건 터치해서 바로 받기'), findsOneWidget);
        expect(find.text('지*민 님'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        for (final key in [
          'linked-approved-banner',
          'linked-menu-route-0',
          'linked-menu-route-1',
          'linked-menu-route-2',
          'linked-logout',
        ]) {
          final bounds = tester.getRect(find.byKey(ValueKey(key)));
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(size.width));
          expect(bounds.bottom, lessThanOrEqualTo(size.height));
        }
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byKey(const ValueKey('linked-approved-banner')));
      await tester.pumpAndSettle();
      expect(
        find.text('예시 승인 약품 배너입니다. 실제 약사 승인·약품 수령·배출은 연결되지 않았습니다.'),
        findsOneWidget,
      );
      expect(find.byType(KioskLinkedHomeScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('linked-logout')));
      await tester.pumpAndSettle();
      expect(
        find.text('테스트용 로그아웃: 일반 홈으로 이동합니다. 실제 인증 세션 종료는 연결되지 않았습니다.'),
        findsOneWidget,
      );
      expect(find.byType(KioskMenuScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Explicit completion preview opens linked home and menus avoid repeating authentication',
    (tester) async {
      await tester.pumpWidget(const AuthCompletePreviewApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('auth-preview-continue')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskLinkedHomeScreen), findsOneWidget);
      for (final index in [0, 1]) {
        await tester.tap(find.byKey(ValueKey('linked-menu-route-$index')));
        await tester.pumpAndSettle();
        expect(find.byType(KioskProductListScreen), findsOneWidget);
        expect(find.byType(KioskQrDownloadScreen), findsNothing);
        if (index == 1) {
          expect(
            find.text(
              '연동 사용자 구매 흐름 미리보기입니다. 현재 목록은 의약외품 예시이며 제한 약품 판매는 연결되지 않았습니다.',
            ),
            findsOneWidget,
          );
        }
        await tester.tap(find.byKey(const ValueKey('previous-screen')));
        await tester.pumpAndSettle();
        expect(find.byType(KioskLinkedHomeScreen), findsOneWidget);
      }
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('linked-menu-route-2')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskUsageGuideScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('usage-back')));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(KioskLinkedHomeScreen))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(KioskAuthCompleteScreen), findsOneWidget);
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      expect(find.byType(KioskMenuScreen), findsOneWidget);
      expect(find.byType(KioskLinkedHomeScreen), findsNothing);
      expect(
        find.byKey(const ValueKey('linked-approved-banner')),
        findsNothing,
      );
    },
  );
}
