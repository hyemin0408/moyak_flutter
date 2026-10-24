import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak_flutter/demo/demo_approved_cart.dart';
import 'package:moyak_flutter/demo/demo_cart.dart';
import 'package:moyak_flutter/main.dart';
import 'package:moyak_flutter/screens/kiosk_cart_screen.dart';
import 'package:moyak_flutter/screens/kiosk_menu_screen.dart';
import 'package:moyak_flutter/screens/kiosk_payment_screen.dart';
import 'package:moyak_flutter/screens/kiosk_dispensing_screen.dart';

void main() {
  test(
    'Example approval limits reject missing approvals and excessive quantities',
    () {
      final cart = DemoCart(
        products: demoApprovedProducts,
        quantities: {0: 1},
        approvedLimits: {0: 1},
      );
      addTearDown(cart.dispose);
      expect(() => cart.add(1), throwsArgumentError);
      expect(() => cart.add(0), throwsArgumentError);
      expect(() => cart.setQuantity(0, 2), throwsArgumentError);
      expect(cart.totalWon, 3500);
      expect(
        () => DemoCart(
          products: demoApprovedProducts,
          quantities: {1: 1},
          approvedLimits: {0: 1},
        ),
        throwsArgumentError,
      );
    },
  );

  testWidgets(
    'Approved example cart updates quantities, payment, deletion and empty state',
    (tester) async {
      final cart = createDemoApprovedCart();
      addTearDown(cart.dispose);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final size in [
        const Size(1080, 1920),
        const Size(540, 960),
        const Size(1920, 1080),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(MaterialApp(home: KioskCartScreen(cart: cart)));
        await tester.pumpAndSettle();
        expect(find.text('2종류 (총 3개)'), findsOneWidget);
        expect(find.text('9,500원'), findsOneWidget);
        expect(find.text('승인 완료 · 예시'), findsNWidgets(2));
        expect(find.text('이미지 준비 중'), findsNWidgets(2));
        expect(find.byKey(const ValueKey('cart-add-products')), findsNothing);
        expect(tester.takeException(), isNull);
      }
      for (final index in [0, 1]) {
        expect(find.byKey(ValueKey('cart-increase-$index')), findsNothing);
        expect(find.byKey(ValueKey('cart-decrease-$index')), findsNothing);
      }
      expect(cart.quantities, {0: 1, 1: 2});
      expect(cart.totalWon, 9500);
      await tester.tap(find.byKey(const ValueKey('cart-checkout')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskPaymentScreen), findsOneWidget);
      expect(find.text('타이레놀정 500mg (8정)'), findsOneWidget);
      expect(find.text('그날엔 큐'), findsOneWidget);
      expect(find.text('9,500원'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('payment-complete')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskDispensingScreen), findsOneWidget);
      expect(cart.totalWon, 9500);
      Navigator.of(tester.element(find.byType(KioskDispensingScreen))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('payment-cancel')));
      await tester.pumpAndSettle();
      expect(cart.totalWon, 9500);
      await tester.tap(find.byKey(const ValueKey('cart-remove-0')));
      await tester.pumpAndSettle();
      expect(cart.totalWon, 6000);
      await tester.tap(find.byKey(const ValueKey('cart-remove-1')));
      await tester.pumpAndSettle();
      expect(find.text('장바구니가 비어 있습니다.'), findsOneWidget);
      expect(cart.totalWon, 0);
      expect(
        tester
            .widget<InkWell>(find.byKey(const ValueKey('cart-checkout')))
            .onTap,
        isNull,
      );
    },
  );

  testWidgets(
    'Approved banner opens cart and payment logout returns to general home',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('시작하기'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('home-preview-approvedMedicines')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('linked-approved-banner')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskCartScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('cart-checkout')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('payment-logout')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskMenuScreen), findsOneWidget);
      expect(
        find.byType(KioskPaymentScreen, skipOffstage: false),
        findsNothing,
      );
      expect(find.byType(KioskCartScreen, skipOffstage: false), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
