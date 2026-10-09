import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak_flutter/demo/demo_cart.dart';
import 'package:moyak_flutter/screens/kiosk_cart_screen.dart';
import 'package:moyak_flutter/screens/kiosk_payment_screen.dart';

void main() {
  testWidgets(
    'Payment shows quantity-based amounts, method selection and safe action messages',
    (tester) async {
      final cart = DemoCart(quantities: {0: 1, 4: 2, 5: 1});
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
        await tester.pumpWidget(
          MaterialApp(home: KioskPaymentScreen(cart: cart)),
        );
        await tester.pumpAndSettle();
        expect(find.text('13,500원'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('payment-product-4')),
            matching: find.text('2개'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('payment-product-4')),
            matching: find.text('6,000원'),
          ),
          findsOneWidget,
        );
        for (final key in [
          'payment-cancel',
          'payment-complete',
          'payment-back',
        ]) {
          final bounds = tester.getRect(find.byKey(ValueKey(key)));
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(size.width));
          expect(bounds.bottom, lessThanOrEqualTo(size.height));
        }
        expect(tester.takeException(), isNull);
      }
      bool selected(String key) => tester
          .widget<Semantics>(
            find.descendant(
              of: find.byKey(ValueKey(key)),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics && widget.properties.selected != null,
              ),
            ),
          )
          .properties
          .selected!;
      expect(selected('payment-method-card'), isTrue);
      await tester.tap(find.byKey(const ValueKey('payment-method-mobile')));
      await tester.pumpAndSettle();
      expect(selected('payment-method-mobile'), isTrue);
      expect(selected('payment-method-card'), isFalse);
      await tester.tap(find.byKey(const ValueKey('payment-complete')));
      await tester.pumpAndSettle();
      expect(
        find.text('테스트용 결제 화면입니다. 실제 결제·영수증 발급·약품 배출은 진행되지 않습니다.'),
        findsOneWidget,
      );
      expect(cart.totalWon, 13500);
      await tester.tap(find.byKey(const ValueKey('payment-logout')));
      await tester.pumpAndSettle();
      expect(find.text('실제 인증이 연결되지 않아 회원 로그아웃은 수행하지 않습니다.'), findsOneWidget);
      expect(cart.totalWon, 13500);
    },
  );

  testWidgets(
    'Checkout preserves cart, cancel/back return, and inactivity is paused during payment',
    (tester) async {
      final cart = DemoCart();
      addTearDown(cart.dispose);
      await tester.pumpWidget(MaterialApp(home: KioskCartScreen(cart: cart)));
      await tester.tap(find.byKey(const ValueKey('cart-checkout')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskPaymentScreen), findsOneWidget);
      await tester.pump(const Duration(minutes: 11));
      expect(cart.totalWon, 7000);
      await tester.tap(find.byKey(const ValueKey('payment-cancel')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskCartScreen), findsOneWidget);
      expect(find.text('7,000원'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('cart-checkout')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('payment-back')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskCartScreen), findsOneWidget);
      await tester.pump(const Duration(minutes: 10));
      await tester.pump();
      expect(cart.totalQuantity, 0);
      expect(find.text('장바구니가 비어 있습니다.'), findsOneWidget);
    },
  );

  testWidgets('Empty cart cannot open payment', (tester) async {
    final cart = DemoCart(quantities: {});
    addTearDown(cart.dispose);
    await tester.pumpWidget(MaterialApp(home: KioskCartScreen(cart: cart)));
    await tester.tap(find.byKey(const ValueKey('cart-checkout')));
    await tester.pumpAndSettle();
    expect(find.byType(KioskPaymentScreen), findsNothing);
    expect(cart.totalWon, 0);
  });
}
