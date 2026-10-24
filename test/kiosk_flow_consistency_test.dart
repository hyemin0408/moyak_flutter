import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak_flutter/main.dart';
import 'package:moyak_flutter/screens/kiosk_cart_screen.dart';
import 'package:moyak_flutter/screens/kiosk_menu_screen.dart';
import 'package:moyak_flutter/screens/kiosk_linked_home_screen.dart';
import 'package:moyak_flutter/screens/kiosk_payment_screen.dart';

Future<void> openLinkedHome(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.tap(find.byType(InkWell));
  await tester.pumpAndSettle();
  await tester.longPress(find.text('시작하기'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const ValueKey('home-preview-approvedMedicines')),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Linked member context and logout survive ordinary-product checkout',
    (tester) async {
      await openLinkedHome(tester);
      await tester.tap(find.byKey(const ValueKey('linked-menu-route-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('complete-selection')));
      await tester.pumpAndSettle();
      expect(find.text('지*민 님'), findsOneWidget);
      final cart = tester
          .widget<KioskCartScreen>(find.byType(KioskCartScreen))
          .cart;
      await tester.tap(find.byKey(const ValueKey('cart-checkout')));
      await tester.pumpAndSettle();
      expect(find.text('지*민 님'), findsOneWidget);
      expect(
        tester
            .widget<KioskPaymentScreen>(find.byType(KioskPaymentScreen))
            .showMember,
        isTrue,
      );
      await tester.tap(find.byKey(const ValueKey('payment-logout')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskMenuScreen), findsOneWidget);
      expect(
        find.byType(KioskLinkedHomeScreen, skipOffstage: false),
        findsNothing,
      );
      expect(cart.quantities, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Approved banner reflects removed example cart lines without recreating them',
    (tester) async {
      await openLinkedHome(tester);
      await tester.tap(find.byKey(const ValueKey('linked-approved-banner')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cart-remove-0')));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(KioskCartScreen))).pop();
      await tester.pumpAndSettle();
      expect(find.text('그날엔 큐 터치해서 바로 받기'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('linked-approved-banner')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('cart-product-0')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('cart-remove-1')));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(KioskCartScreen))).pop();
      await tester.pumpAndSettle();
      expect(find.text('담긴 승인 약이 없어요'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
