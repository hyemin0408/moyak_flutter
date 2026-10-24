import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:moyak_flutter/models/moyak_api_models.dart';
import 'package:moyak_flutter/screens/kiosk_cart_screen.dart';
import 'package:moyak_flutter/screens/kiosk_payment_screen.dart';
import 'package:moyak_flutter/screens/kiosk_dispensing_screen.dart';
import 'package:moyak_flutter/screens/kiosk_home_router.dart';
import 'package:moyak_flutter/services/kiosk_backend.dart';
import 'package:moyak_flutter/services/order_recovery_store.dart';
import 'package:moyak_flutter/services/service_result.dart';

import 'kiosk_backend_integration_test.dart' as fixtures;
import 'kiosk_recovery_test.dart' as recovery;

Map<String, Object?> approval(
  String id, {
  String user = 'mock-user',
  String status = 'pending',
  int? price = 3500,
  int quantity = 1,
  bool expired = false,
}) => {
  'id': id,
  'user_id': user,
  'drug_item_seq': 'seq-$id',
  'drug_item_name': '서버 승인 약 $id',
  'status': status,
  'price': price,
  'quantity': quantity,
  'expires_at': DateTime.now()
      .toUtc()
      .add(Duration(days: expired ? -1 : 1))
      .toIso8601String(),
};

void main() {
  test('Approved quantity preserves server line total without division or multiplication', () async {
    var quantity = 3;
    final b = recovery.configured(
      MockClient(
        (r) async => fixtures.json(
          r.url.path.endsWith('/session')
              ? recovery.session()
              : [approval('a', quantity: quantity, price: 10001)],
        ),
      ),
      MemoryOrderRecoveryStore(),
    );
    addTearDown(b.api.close);
    final cart =
        (await b.loadApprovedCart() as ServiceSuccess<LiveApprovedKioskCart>)
            .value;
    addTearDown(cart.dispose);
    expect(cart.totalQuantity, 3);
    expect(cart.totalWon, 10001);
    expect(() => cart.setQuantity(0, 2), throwsArgumentError);
    expect(await cart.validateSelection(), isNull);
    quantity = 2;
    expect(await cart.validateSelection(), contains('변경'));
    cart.remove(0);
    expect(cart.totalWon, 0);
  });

  test(
    'Legacy approvals default to one while malformed quantities are rejected',
    () {
      final legacy = approval('a')..remove('quantity');
      expect(KioskApprovedPurchase.fromJson(legacy).quantity, 1);
      for (final quantity in [0, -1, null, 1.5, '3']) {
        expect(
          () => KioskApprovedPurchase.fromJson({
            ...approval('a'),
            'quantity': quantity,
          }),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'Removing selection during approval refresh blocks payment review',
    () async {
      var reads = 0;
      final pending = Completer<http.Response>();
      final b = recovery.configured(
        MockClient((r) async {
          if (r.url.path.endsWith('/session')) {
            return fixtures.json(recovery.session());
          }
          reads++;
          return reads == 1 ? fixtures.json([approval('a')]) : pending.future;
        }),
        MemoryOrderRecoveryStore(),
      );
      addTearDown(b.api.close);
      final cart =
          (await b.loadApprovedCart() as ServiceSuccess<LiveApprovedKioskCart>)
              .value;
      addTearDown(cart.dispose);
      final checking = cart.validateSelection();
      await Future<void>.delayed(Duration.zero);
      cart.remove(0);
      pending.complete(fixtures.json([approval('a')]));
      expect(await checking, contains('변경'));
      expect(await cart.validateSelection(), contains('비어'));
      expect(reads, 2);
    },
  );
  test('Approval request uses paired user; filters terminal/expired states, retains approval IDs', () async {
    final b = recovery.configured(
      MockClient((r) async {
        if (r.url.path.endsWith('/session')) {
          return fixtures.json(recovery.session());
        }
        expect(r.method, 'GET');
        expect(r.url.path, '/vending/purchases');
        expect(r.url.queryParameters, {'user_id': 'mock-user'});
        return fixtures.json([
          approval('a'),
          approval('b', price: 4000),
          approval('c', status: 'dispensed'),
          approval('d', expired: true),
        ]);
      }),
      MemoryOrderRecoveryStore(),
    );
    addTearDown(b.api.close);
    final result = await b.loadApprovedCart();
    expect(result, isA<ServiceSuccess<LiveApprovedKioskCart>>());
    final cart = (result as ServiceSuccess<LiveApprovedKioskCart>).value;
    addTearDown(cart.dispose);
    expect(cart.products.map((p) => p.id), ['a', 'b']);
    expect(cart.productQuantities, {'a': 1, 'b': 1});
    expect(cart.totalWon, 7500);
    expect(cart.isApprovalRestricted, isTrue);
    expect(() => cart.setQuantity(0, 2), throwsArgumentError);
    cart.remove(0);
    expect(cart.totalWon, 4000);
  });

  test('Unpaired user and disabled policy never fetch approval list', () async {
    var purchases = 0;
    final b = recovery.configured(
      MockClient((r) async {
        if (r.url.path.endsWith('/session')) {
          return fixtures.json(recovery.session(paired: false));
        }
        purchases++;
        throw StateError('must not fetch member data');
      }),
      MemoryOrderRecoveryStore(),
    );
    addTearDown(b.api.close);
    expect(
      await b.loadApprovedCart(),
      isA<ServiceFailure<LiveApprovedKioskCart>>(),
    );
    expect(purchases, 0);
    final disabled = recovery.configured(
      MockClient((_) async => throw StateError('must not send request')),
      MemoryOrderRecoveryStore(),
      allowed: false,
    );
    addTearDown(disabled.api.close);
    expect(
      await disabled.loadApprovedCart(),
      isA<ServiceFailure<LiveApprovedKioskCart>>(),
    );
  });

  test('Other member and duplicate approvals are rejected', () async {
    for (final values in [
      [approval('a', user: 'other')],
      [approval('a'), approval('a')],
    ]) {
      final b = recovery.configured(
        MockClient(
          (r) async => fixtures.json(
            r.url.path.endsWith('/session') ? recovery.session() : values,
          ),
        ),
        MemoryOrderRecoveryStore(),
      );
      expect(
        await b.loadApprovedCart(),
        isA<ServiceFailure<LiveApprovedKioskCart>>(),
      );
      expect(b.approvedPurchases, isEmpty);
      b.api.close();
    }
  });

  test(
    'Missing price is not free; stale price and changed member block checkout',
    () async {
      int? price;
      var user = 'mock-user';
      final b = recovery.configured(
        MockClient(
          (r) async => fixtures.json(
            r.url.path.endsWith('/session')
                ? {...recovery.session(), 'user_id': user}
                : [approval('a', price: price, user: user)],
          ),
        ),
        MemoryOrderRecoveryStore(),
      );
      addTearDown(b.api.close);
      final result =
          await b.loadApprovedCart() as ServiceSuccess<LiveApprovedKioskCart>;
      final cart = result.value;
      addTearDown(cart.dispose);
      expect(cart.hasUnknownPrice, isTrue);
      expect(await cart.validateSelection(), contains('가격'));
      price = 3500;
      expect(await cart.validateSelection(), contains('변경'));
      user = 'other';
      expect(await cart.validateSelection(), contains('회원이 변경'));
    },
  );

  testWidgets(
    'Server approved cart reuses payment screen and never simulates payment/dispense',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final paths = <String>[];
      final b = recovery.configured(
        MockClient((r) async {
          paths.add('${r.method} ${r.url.path}');
          return fixtures.json(
            r.url.path.endsWith('/session')
                ? recovery.session()
                : [approval('a', quantity: 3, price: 10001)],
          );
        }),
        MemoryOrderRecoveryStore(),
      );
      addTearDown(b.api.close);
      final result =
          await b.loadApprovedCart() as ServiceSuccess<LiveApprovedKioskCart>;
      final cart = result.value;
      addTearDown(cart.dispose);
      await tester.pumpWidget(
        fixtures.app(b, KioskCartScreen(cart: cart, showMember: true)),
      );
      expect(find.text('서버 승인 약 a'), findsOneWidget);
      expect(find.text('테스트회원 님'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('cart-checkout')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskPaymentScreen), findsOneWidget);
      expect(find.text('3개'), findsOneWidget);
      expect(find.text('10,001원'), findsWidgets);
      expect(find.text('30,003원'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('payment-complete')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskDispensingScreen), findsNothing);
      expect(find.textContaining('실제 결제 장치'), findsOneWidget);
      expect(paths.every((path) => path.startsWith('GET ')), isTrue);
    },
  );

  testWidgets('Live home opens server approvals instead of demo cart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final b = recovery.configured(
      MockClient(
        (r) async => fixtures.json(
          r.url.path.endsWith('/session')
              ? recovery.session()
              : [approval('a'), approval('b')],
        ),
      ),
      MemoryOrderRecoveryStore(),
    );
    addTearDown(b.api.close);
    await tester.pumpWidget(
      fixtures.app(
        b,
        KioskHomeRouter(liveSession: KioskSession.fromJson(recovery.session())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('linked-approved-banner')));
    await tester.pumpAndSettle();
    expect(find.byType(KioskCartScreen), findsOneWidget);
    expect(find.text('서버 승인 약 a'), findsOneWidget);
    expect(find.text('서버 승인 약 b'), findsOneWidget);
    expect(find.text('타이레놀정 500mg (8정)'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
