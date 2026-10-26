import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moyak_flutter/main.dart';
import 'package:moyak_flutter/models/moyak_api_models.dart';
import 'package:moyak_flutter/screens/kiosk_product_list_screen.dart';
import 'package:moyak_flutter/screens/kiosk_cart_screen.dart';
import 'package:moyak_flutter/screens/kiosk_payment_screen.dart';
import 'package:moyak_flutter/screens/kiosk_device_pairing_screen.dart';
import 'package:moyak_flutter/screens/kiosk_auth_complete_screen.dart';
import 'package:moyak_flutter/screens/kiosk_no_approved_home_screen.dart';
import 'package:moyak_flutter/screens/kiosk_dispensing_screen.dart';
import 'package:moyak_flutter/services/kiosk_backend.dart';
import 'package:moyak_flutter/services/moyak_api_client.dart';
import 'package:moyak_flutter/services/service_result.dart';

http.Response json(Object value, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(value)), status);
Map<String, Object?> product(String id, {int stock = 4}) => {
  'id': id,
  'item_seq': 'seq-$id',
  'item_name': '서버 상품 $id',
  'company': '서버 제조사',
  'category': '상처/연고',
  'badge': null,
  'price': 1200,
  'stock': stock,
};
Map<String, Object?> order({String status = 'cart', int total = 2600}) => {
  'id': 'order-test',
  'machine_id': 'test-machine',
  'status': status,
  'total_amount': total,
  'created_at': '2026-10-21T00:00:00',
  'paid_at': null,
  'dispensed_at': null,
  'items': [
    {'item_name': '서버 상품 a', 'quantity': 2, 'unit_price': 1300},
  ],
};
KioskBackend backend(
  http.Client client, {
  bool allowed = true,
  String machine = 'test-machine',
}) => KioskBackend(
  api: MoyakApiClient(client: client),
  machineId: machine,
  allowMutations: allowed,
  environment: allowed ? 'mock-only' : '',
);
Widget app(KioskBackend b, Widget home) => KioskBackendScope(
  backend: b,
  child: MaterialApp(home: home),
);

void main() {
  test('Missing machine and unapproved configuration make zero requests, including catalog seeding GET', () async {
    var calls = 0;
    final b = backend(
      MockClient((_) async {
        calls++;
        throw StateError('No network permitted');
      }),
      allowed: false,
    );
    addTearDown(b.api.close);
    final cart = LiveKioskCart(b);
    addTearDown(cart.dispose);
    expect(await cart.load(), isFalse);
    expect(await cart.createOrder(), isFalse);
    expect(await b.rotateQr(), isA<ServiceFailure<KioskQr>>());
    expect(calls, 0);
  });

  test('IDs survive catalog reordering; unknown images, stock limits and duplicate IDs stay explicit', () async {
    var load = 0;
    final b = backend(
      MockClient(
        (_) async => json(
          ++load == 1
              ? [product('a'), product('b', stock: 0)]
              : load == 2
              ? [product('b', stock: 0), product('a')]
              : [product('a'), product('a')],
        ),
      ),
    );
    addTearDown(b.api.close);
    final cart = LiveKioskCart(b);
    addTearDown(cart.dispose);
    expect(await cart.load(), isTrue);
    expect(cart.quantities, isEmpty);
    expect(cart.products.first.image, isEmpty);
    cart.setQuantity(0, 2);
    expect(() => cart.add(1), throwsArgumentError);
    expect(await cart.load(), isTrue);
    expect(cart.productQuantities, {'a': 2});
    expect(cart.quantities, {1: 2});
    expect(cart.totalWon, 2400);
    expect(await cart.load(), isFalse);
    expect(cart.error, contains('ID'));
  });

  test('Create uses server IDs, blocks concurrent creation and edits, cancellation unlocks', () async {
    final pending = Completer<http.Response>();
    var posts = 0;
    final b = backend(
      MockClient((r) async {
        if (r.method == 'GET') {
          return r.url.path.endsWith('/products')
              ? json([product('a')])
              : json(order());
        }
        if (r.url.path.endsWith('/cancel')) {
          return json(order(status: 'cancelled'));
        }
        posts++;
        expectSync(jsonDecode(r.body), {
          'items': [
            {'product_id': 'a', 'quantity': 2},
          ],
        });
        return pending.future;
      }),
    );
    addTearDown(b.api.close);
    final cart = LiveKioskCart(b);
    addTearDown(cart.dispose);
    await cart.load();
    cart.setQuantity(0, 2);
    final first = cart.createOrder();
    expect(await cart.createOrder(), isFalse);
    expect(() => cart.add(0), throwsArgumentError);
    pending.complete(json(order()));
    expect(await first, isTrue);
    expect(
      cart.order!.total,
      2600,
    ); // server price replaces local estimate 2400
    expect(await cart.createOrder(), isFalse);
    expect(posts, 1);
    expect(await cart.cancelOrder(), isTrue);
    expect(cart.order, isNull);
    cart.setQuantity(0, 1);
  });

  test(
    'Ambiguous POST response prevents retry even from another cart',
    () async {
      var posts = 0;
      final b = backend(
        MockClient((r) async {
          if (r.method == 'GET') {
            return r.url.path.endsWith('/products')
                ? json([product('a')])
                : json(order());
          }
          posts++;
          return http.Response('broken successful response', 200);
        }),
      );
      addTearDown(b.api.close);
      final cart = LiveKioskCart(b);
      addTearDown(cart.dispose);
      await cart.load();
      cart.setQuantity(0, 2);
      expect(await cart.createOrder(), isFalse);
      expect(cart.uncertain, isTrue);
      final second = LiveKioskCart(b);
      addTearDown(second.dispose);
      expect(await second.createOrder(), isFalse);
      expect(posts, 1);
    },
  );

  test(
    'Conflict keeps cart, cancellation failure preserves pending order',
    () async {
      var conflict = true;
      final b = backend(
        MockClient((r) async {
          if (r.method == 'GET') {
            return r.url.path.endsWith('/products')
                ? json([product('a')])
                : json(order());
          }
          if (r.url.path.endsWith('/cancel')) {
            return json({'detail': 'unavailable'}, 503);
          }
          return conflict ? json({'detail': '재고 부족'}, 409) : json(order());
        }),
      );
      addTearDown(b.api.close);
      final cart = LiveKioskCart(b);
      addTearDown(cart.dispose);
      await cart.load();
      cart.setQuantity(0, 2);
      expect(await cart.createOrder(), isFalse);
      expect(cart.productQuantities, {'a': 2});
      expect(cart.uncertain, isFalse);
      conflict = false;
      expect(await cart.createOrder(), isTrue);
      expect(await cart.cancelOrder(), isFalse);
      expect(cart.order, isNotNull);
    },
  );

  testWidgets(
    'Existing product-cart-payment flow uses server data and never calls pay/dispense',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final paths = <String>[];
      final b = backend(
        MockClient((r) async {
          paths.add(r.url.path);
          if (r.method == 'GET') {
            return r.url.path.endsWith('/products')
                ? json([product('a')])
                : json(order());
          }
          if (r.url.path.endsWith('/cancel')) {
            return json(order(status: 'cancelled'));
          }
          return json(order());
        }),
      );
      addTearDown(b.api.close);
      final cart = LiveKioskCart(b);
      addTearDown(cart.dispose);
      await cart.load();
      await tester.pumpWidget(app(b, KioskProductListScreen(cart: cart)));
      await tester.pumpAndSettle();
      expect(find.text('서버 상품 a'), findsOneWidget);
      expect(find.text('대일밴드 뉴 표준형 20매'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('product-card-0')));
      await tester.pump();
      expect(find.textContaining('상세 정보 API'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('add-product-0')));
      await tester.tap(find.byKey(const ValueKey('add-product-0')));
      await tester.tap(find.byKey(const ValueKey('complete-selection')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskCartScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('cart-checkout')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskPaymentScreen), findsOneWidget);
      expect(find.text('2,600원'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('payment-complete')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskDispensingScreen), findsNothing);
      expect(
        paths.any((p) => p.endsWith('/pay') || p.endsWith('/dispense')),
        isFalse,
      );
      await tester.tap(find.byKey(const ValueKey('payment-cancel')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskCartScreen), findsOneWidget);
      expect(paths, contains('/vending/orders/order-test/cancel'));
      expect(cart.productQuantities, {'a': 2});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Catalog loading, empty, errors and missing configuration have no demo fallback',
    (tester) async {
      for (final mode in ['empty', 'error', 'missing']) {
        final b = backend(
          MockClient(
            (_) async =>
                mode == 'empty' ? json([]) : json({'detail': 'error'}, 503),
          ),
          machine: mode == 'missing' ? '' : 'test-machine',
        );
        await tester.pumpWidget(app(b, const KioskProductListScreen()));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.text('대일밴드 뉴 표준형 20매'), findsNothing);
        expect(
          find.textContaining(
            mode == 'empty'
                ? '검색 결과가 없습니다'
                : mode == 'missing'
                ? '기기 ID가 설정'
                : '서버 서비스를 사용할',
          ),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
        b.api.close();
      }
    },
  );

  testWidgets(
    'Configured QR polls real session contract and navigates existing homes without claiming identity verification',
    (tester) async {
      var polls = 0;
      final paths = <String>[];
      final b = backend(
        MockClient((r) async {
          paths.add(r.url.path);
          if (r.url.path == '/vending/purchases') return json([]);
          if (r.url.path.endsWith('/rotate-qr')) {
            return json({
              'machine_id': 'test-machine',
              'qr_token': 'mock-token',
              'qr_token_expires_at': DateTime.now()
                  .toUtc()
                  .add(const Duration(minutes: 3))
                  .toIso8601String(),
              'qr_svg': '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"><rect width="20" height="20"/></svg>',
            });
          }
          polls++;
          if (polls == 1) {
            return json({'machine_id': 'test-machine', 'paired': false});
          }
          return json({
            'machine_id': 'test-machine',
            'paired': true,
            'user_id': 'mock-user',
            'user_display_name': '테*트',
            'purchase': null,
          });
        }),
      );
      addTearDown(b.api.close);
      await tester.pumpWidget(app(b, const KioskDevicePairingScreen()));
      await tester.pump();
      await tester.pump();
      expect(
        find.byKey(const ValueKey('pairing-preview-complete')),
        findsNothing,
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byType(KioskAuthCompleteScreen), findsOneWidget);
      expect(find.text('기기 연동 완료'), findsOneWidget);
      expect(find.text('본인인증 완료'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('auth-preview-continue')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskNoApprovedHomeScreen), findsOneWidget);
      expect(find.text('테*트 님'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      expect(polls, 3); // Initial session, QR poll, and fresh home entry.
      expect(paths.where((p) => p.endsWith('/rotate-qr')).length, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'QR expiry hides SVG, stops polling and does not rotate automatically',
    (tester) async {
      var rotations = 0, polls = 0;
      final b = backend(
        MockClient((r) async {
          if (r.method == 'POST') {
            rotations++;
            return json({
              'machine_id': 'test-machine',
              'qr_token': 'mock-token',
              'qr_token_expires_at': DateTime.now()
                  .toUtc()
                  .add(const Duration(seconds: 2))
                  .toIso8601String(),
              'qr_svg': '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"/>',
            });
          }
          polls++;
          return json({'machine_id': 'test-machine', 'paired': false});
        }),
      );
      addTearDown(b.api.close);
      await tester.pumpWidget(app(b, const KioskDevicePairingScreen()));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      expect(find.textContaining('QR 유효 시간이 지났습니다'), findsOneWidget);
      expect(find.byType(KioskAuthCompleteScreen), findsNothing);
      expect(rotations, 1);
      expect(polls, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Normal launch without configuration never uses seeded example products or server mutations',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const channel = MethodChannel('moyak/order_recovery');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async => call.method == 'read' ? null : true,
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final paths = <String>[];
      final api = MoyakApiClient(
        client: MockClient((request) async {
          paths.add(request.url.path);
          return http.Response(
            jsonEncode({
              'truncated': false,
              'items': [
                {'code': 'VM-001', 'name': '등록된 테스트 위치', 'address': '테스트 주소'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      await tester.pumpWidget(KioskApplication(api: api));
      await tester.pumpAndSettle();
      expect(find.text('모약 · 설치 기기 설정'), findsOneWidget);
      expect(find.byType(KioskStartScreen), findsNothing);
      await tester.tap(find.text('등록된 테스트 위치'));
      await tester.pump();
      await tester.tap(find.text('선택한 자판기로 설정'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('kiosk-start-button')));
      await tester.pumpAndSettle();
      // Home first menu uses the normal Navigator path and inherited backend.
      await tester.tap(find.byKey(const ValueKey('menu-route-0')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskProductListScreen), findsOneWidget);
      expect(find.textContaining('승인된 테스트 환경 설정이 필요합니다'), findsOneWidget);
      expect(paths, ['/api/v1/map/machines']);
      expect(find.text('대일밴드 뉴 표준형 20매'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('기기 설정'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('기기 설정 열기'));
      await tester.pumpAndSettle();
      expect(find.text('설치 기기 변경'), findsOneWidget);
      expect(find.textContaining('현재 기기: VM-001'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(KioskStartScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
