import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak_flutter/demo/demo_cart.dart';
import 'package:moyak_flutter/main.dart';
import 'package:moyak_flutter/screens/kiosk_cart_screen.dart';
import 'package:moyak_flutter/screens/kiosk_product_list_screen.dart';

void main() {
  testWidgets(
    'Cart totals respect quantities and deleting items produces an empty cart',
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
        await tester.pumpWidget(MaterialApp(home: KioskCartScreen(cart: cart)));
        await tester.pumpAndSettle();
        expect(find.text('3종류 (총 4개)'), findsOneWidget);
        expect(find.text('13,500원'), findsOneWidget);
        expect(cart.totalWon, 13500);
        final bounds = tester.getRect(find.byKey(const ValueKey('cart-home')));
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.bottom, lessThanOrEqualTo(size.height));
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byKey(const ValueKey('cart-remove-4')));
      await tester.pumpAndSettle();
      expect(find.text('2종류 (총 2개)'), findsOneWidget);
      expect(find.text('7,500원'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('cart-remove-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cart-remove-5')));
      await tester.pumpAndSettle();
      expect(find.text('장바구니가 비어 있습니다.'), findsOneWidget);
      expect(find.text('0원'), findsOneWidget);
    },
  );

  testWidgets(
    'Shared cart survives product additions, deletion, and returns to start',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('menu-route-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('complete-selection')));
      await tester.pumpAndSettle();
      expect(find.text('7,000원'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('cart-remove-4')));
      await tester.pumpAndSettle();
      expect(find.text('4,000원'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('cart-add-products')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskProductListScreen), findsOneWidget);
      expect(find.text('4,000원'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('add-product-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('complete-selection')));
      await tester.pumpAndSettle();
      expect(find.text('7,500원'), findsOneWidget);
      expect(find.byKey(const ValueKey('cart-product-4')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('cart-home')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskStartScreen), findsOneWidget);
      expect(find.byType(KioskCartScreen), findsNothing);
    },
  );

  testWidgets('Inactive example cart is cleared after ten minutes', (
    tester,
  ) async {
    final cart = DemoCart();
    addTearDown(cart.dispose);
    await tester.pumpWidget(MaterialApp(home: KioskCartScreen(cart: cart)));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 9));
    expect(cart.totalQuantity, 2);
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();
    expect(cart.totalQuantity, 0);
    expect(find.text('장바구니가 비어 있습니다.'), findsOneWidget);
  });
}
