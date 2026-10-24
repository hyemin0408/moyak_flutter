import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak_flutter/main.dart';
import 'package:moyak_flutter/screens/kiosk_dispensing_screen.dart';
import 'package:moyak_flutter/screens/kiosk_dispensing_complete_screen.dart';
import 'package:moyak_flutter/screens/kiosk_payment_screen.dart';

void main() {
  testWidgets('Dispensing previews fit kiosk, small and landscape screens', (
    tester,
  ) async {
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
        MaterialApp(
          home: KioskDispensingScreen.preview(
            onFirstScreen: () {},
            showMember: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('약 배출 테스트 진행 중'), findsOneWidget);
      expect(find.text('개발용 미리보기 · 실제 결제 및 약 배출 없음'), findsOneWidget);
      final bounds = tester.getRect(
        find.byKey(const ValueKey('dispensing-preview-complete')),
      );
      expect(bounds.right, lessThanOrEqualTo(size.width));
      expect(bounds.bottom, lessThanOrEqualTo(size.height));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          home: KioskDispensingCompleteScreen.preview(
            onFirstScreen: () {},
            showMember: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('약 배출이 완료되었어요'), findsOneWidget);
      expect(find.textContaining('실제 약 배출이나 수령 완료는 확인되지'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  for (final approved in [false, true]) {
    testWidgets(
      'Explicit preview for ${approved ? 'approved' : 'ordinary'} checkout does not create payment or device success',
      (tester) async {
        await tester.pumpWidget(const MyApp());
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();
        if (approved) {
          await tester.longPress(find.text('시작하기'));
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('home-preview-approvedMedicines')),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('linked-approved-banner')),
          );
        } else {
          await tester.tap(find.byKey(const ValueKey('menu-route-0')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('complete-selection')));
        }
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('cart-checkout')));
        await tester.pumpAndSettle();
        final cart = tester
            .widget<KioskPaymentScreen>(find.byType(KioskPaymentScreen))
            .cart;
        final originalTotal = cart.totalWon;
        await tester.tap(find.byKey(const ValueKey('payment-complete')));
        await tester.pumpAndSettle();
        expect(find.byType(KioskDispensingScreen), findsOneWidget);
        await tester.pump(const Duration(minutes: 5));
        expect(find.byType(KioskDispensingCompleteScreen), findsNothing);
        expect(cart.totalWon, originalTotal);
        final completePreview = tester
            .widget<InkWell>(
              find.byKey(const ValueKey('dispensing-preview-complete')),
            )
            .onTap!;
        // Repeated callbacks cannot stack completion routes during transition.
        completePreview();
        completePreview();
        await tester.pumpAndSettle();
        expect(find.byType(KioskDispensingCompleteScreen), findsOneWidget);
        expect(
          find.byType(KioskDispensingScreen, skipOffstage: false),
          findsNothing,
        );
        expect(cart.totalWon, originalTotal);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(KioskDispensingCompleteScreen), findsOneWidget);
        expect(find.byType(KioskPaymentScreen), findsNothing);
        await tester.tap(find.byKey(const ValueKey('dispensing-first-screen')));
        await tester.pumpAndSettle();
        expect(find.byType(KioskStartScreen), findsOneWidget);
        expect(
          find.byType(KioskPaymentScreen, skipOffstage: false),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
