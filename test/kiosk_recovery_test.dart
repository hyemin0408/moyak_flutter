import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moyak_flutter/models/moyak_api_models.dart';
import 'package:moyak_flutter/screens/kiosk_auth_complete_screen.dart';
import 'package:moyak_flutter/screens/kiosk_device_pairing_screen.dart';
import 'package:moyak_flutter/screens/kiosk_home_router.dart';
import 'package:moyak_flutter/screens/kiosk_linked_home_screen.dart';
import 'package:moyak_flutter/screens/kiosk_no_approved_home_screen.dart';
import 'package:moyak_flutter/screens/kiosk_menu_screen.dart';
import 'package:moyak_flutter/screens/kiosk_payment_screen.dart';
import 'package:moyak_flutter/services/kiosk_backend.dart';
import 'package:moyak_flutter/services/moyak_api_client.dart';
import 'package:moyak_flutter/services/order_recovery_store.dart';
import 'package:moyak_flutter/services/service_result.dart';

import 'kiosk_backend_integration_test.dart' as fixtures;

KioskBackend configured(
  http.Client client,
  OrderRecoveryStore store, {
  bool allowed = true,
  String machine = 'test-machine',
}) => KioskBackend(
  api: MoyakApiClient(client: client),
  machineId: machine,
  environment: 'mock-only',
  allowMutations: allowed,
  recoveryStore: store,
);

Map<String, Object?> session({bool paired = true, bool approved = false}) => {
  'machine_id': 'test-machine',
  'paired': paired,
  'user_id': paired ? 'mock-user' : null,
  'user_display_name': paired ? '테스트회원' : null,
  'purchase': approved
      ? {'id': 'approval-test', 'drug_item_name': '승인 예시', 'status': 'pending'}
      : null,
};

class BrokenStore implements OrderRecoveryStore {
  @override
  Future<OrderRecoveryRecord?> read(String key) async => null;
  @override
  Future<void> write(String key, OrderRecoveryRecord? record) async =>
      throw StateError('disk unavailable');
}

void main() {
  test('Order payload is fixed before asynchronous recovery access', () async {
    Map<String, dynamic>? sent;
    final b = configured(
      MockClient((r) async {
        sent = jsonDecode(r.body) as Map<String, dynamic>;
        return fixtures.json(fixtures.order());
      }),
      MemoryOrderRecoveryStore(),
    );
    addTearDown(b.api.close);
    final items = {'a': 2};
    final request = b.submitOrder(items);
    items['a'] = 100;
    items['other'] = 1;
    expect(await request, isTrue);
    expect(sent, {
      'items': [
        {'product_id': 'a', 'quantity': 2},
      ],
    });
  });

  test(
    'QR rotation serializes mutation and blocks session reads until complete',
    () async {
      final pending = Completer<http.Response>();
      var calls = 0;
      final b = configured(
        MockClient((_) async {
          calls++;
          return pending.future;
        }),
        MemoryOrderRecoveryStore(),
      );
      addTearDown(b.api.close);
      final first = b.rotateQr();
      expect(await b.rotateQr(), isA<ServiceFailure<KioskQr>>());
      expect(await b.querySession(), isA<ServiceFailure<KioskSession>>());
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
      pending.complete(fixtures.json({'detail': 'unavailable'}, 503));
      expect(await first, isA<ServiceFailure<KioskQr>>());
      expect(b.session, isNull);
    },
  );

  test('Only backend pending approval is eligible for the approved home', () {
    final data = session(approved: true);
    expect(KioskSession.fromJson(data).hasPendingPurchase, isTrue);
    for (final status in ['expired', 'dispensed', 'paid', 'unknown']) {
      data['purchase'] = {
        'id': 'approval-test',
        'drug_item_name': '승인 예시',
        'status': status,
      };
      expect(KioskSession.fromJson(data).hasPendingPurchase, isFalse);
    }
    data['paired'] = false;
    data['purchase'] = {
      'id': 'approval-test',
      'drug_item_name': '승인 예시',
      'status': 'pending',
    };
    expect(KioskSession.fromJson(data).hasPendingPurchase, isFalse);
  });

  testWidgets(
    'Resume during pending order read queues a fresh read after stale reply',
    (tester) async {
      final oldRead = Completer<http.Response>();
      var reads = 0;
      final b = configured(
        MockClient((r) async {
          if (r.method == 'POST') return fixtures.json(fixtures.order());
          reads++;
          return reads == 1
              ? oldRead.future
              : fixtures.json(fixtures.order(status: 'cancelled'));
        }),
        MemoryOrderRecoveryStore(),
      );
      addTearDown(b.api.close);
      await b.submitOrder({'a': 2});
      final cart = LiveKioskCart(b);
      addTearDown(cart.dispose);
      await tester.pumpWidget(fixtures.app(b, KioskPaymentScreen(cart: cart)));
      await tester.pump();
      expect(reads, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(reads, 1);
      oldRead.complete(fixtures.json(fixtures.order()));
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(cart.order, isNull);
      expect(find.textContaining('주문이 취소 또는 만료되었습니다'), findsOneWidget);
    },
  );

  testWidgets(
    'Payment resume observes server expiry without pay or cancel mutation',
    (tester) async {
      var expired = false;
      final methods = <String>[];
      final b = configured(
        MockClient((r) async {
          methods.add(r.method);
          return fixtures.json(
            fixtures.order(status: expired ? 'cancelled' : 'cart'),
          );
        }),
        MemoryOrderRecoveryStore(),
      );
      addTearDown(b.api.close);
      expect(await b.submitOrder({'a': 2}), isTrue);
      final cart = LiveKioskCart(b);
      addTearDown(cart.dispose);
      await tester.pumpWidget(fixtures.app(b, KioskPaymentScreen(cart: cart)));
      await tester.pumpAndSettle();
      expect(find.text('서버 상품 a'), findsOneWidget);
      expired = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(cart.order, isNull);
      expect(find.textContaining('주문이 취소 또는 만료되었습니다'), findsOneWidget);
      expect(
        find.text('서버 상품 a'),
        findsOneWidget,
      ); // Retain original review snapshot.
      expect(methods, ['POST', 'GET', 'GET']);
    },
  );

  test(
    'Lost cancel reply is recovered by GET without sending cancellation twice',
    () async {
      var cancelled = false, cancels = 0;
      final b = configured(
        MockClient((r) async {
          if (r.url.path.endsWith('/cancel')) {
            cancels++;
            cancelled = true;
            return fixtures.json({'detail': 'reply lost'}, 503);
          }
          return fixtures.json(
            fixtures.order(status: cancelled ? 'cancelled' : 'cart'),
          );
        }),
        MemoryOrderRecoveryStore(),
      );
      addTearDown(b.api.close);
      expect(await b.submitOrder({'a': 2}), isTrue);
      expect(await b.cancelOrder(), isFalse);
      expect(b.orderUncertain, isTrue);
      expect(await b.cancelOrder(), isTrue);
      expect(b.pendingOrder, isNull);
      expect(b.orderUncertain, isFalse);
      expect(cancels, 1);
    },
  );

  test(
    'Unbound client and disabled policy block ALL vending reads and writes',
    () async {
      var calls = 0;
      final api = MoyakApiClient(
        client: MockClient((_) async {
          calls++;
          throw StateError('no network');
        }),
      );
      addTearDown(api.close);
      expect(
        await api.kioskOrder('unknown'),
        isA<ServiceFailure<KioskOrder>>(),
      );
      final b = KioskBackend(
        api: api,
        machineId: 'test-machine',
        environment: 'mock-only',
      );
      expect(await b.syncOrder(), isFalse);
      expect(await b.cancelOrder(), isFalse);
      expect(await b.querySession(), isA<ServiceFailure<KioskSession>>());
      expect(await b.rotateQr(), isA<ServiceFailure<KioskQr>>());
      expect(
        await api.kioskProducts('test-machine'),
        isA<ServiceFailure<List<KioskProduct>>>(),
      );
      expect(
        await api.createKioskOrder('test-machine', {'a': 2}),
        isA<ServiceFailure<KioskOrder>>(),
      );
      expect(
        await api.cancelKioskOrder('unknown'),
        isA<ServiceFailure<KioskOrder>>(),
      );
      expect(calls, 0);
    },
  );

  test('Known order survives app restart, expires only on server confirmation and is not submitted again', () async {
    final store = MemoryOrderRecoveryStore();
    var posts = 0, reads = 0;
    var expired = false;
    http.Client client() => MockClient((r) async {
      if (r.method == 'POST') {
        posts++;
        return fixtures.json(fixtures.order());
      }
      if (r.url.path.endsWith('/products')) {
        return fixtures.json([fixtures.product('a')]);
      }
      reads++;
      return fixtures.json(
        fixtures.order(status: expired ? 'cancelled' : 'cart'),
      );
    });
    final first = configured(client(), store);
    addTearDown(first.api.close);
    expect(await first.submitOrder({'a': 2}), isTrue);
    final restarted = configured(client(), store);
    addTearDown(restarted.api.close);
    final cart = LiveKioskCart(restarted);
    addTearDown(cart.dispose);
    expect(
      await cart.load(),
      isFalse,
    ); // Existing payment must be reviewed first.
    expect(cart.order!.id, 'order-test');
    expect(cart.displayOrder!.lines.single.quantity, 2);
    expect(cart.displayOrder!.createdAt!.isUtc, isTrue);
    expect(await restarted.submitOrder({'a': 2}), isFalse);
    expect(posts, 1);
    expect(reads, 2);
    expired = true;
    expect(await cart.load(), isTrue);
    expect(cart.order, isNull);
    expect(cart.uncertain, isFalse);
    expect(posts, 1);
    final third = configured(client(), store);
    addTearDown(third.api.close);
    expect(await third.syncOrder(), isTrue);
    expect(third.pendingOrder, isNull);
    expect(reads, 3); // Cleared journal does not query a non-existent order.
  });

  test('Lost POST response survives restart and blocks retries without guessing order ID', () async {
    final store = MemoryOrderRecoveryStore();
    var calls = 0;
    http.Client client() => MockClient((_) async {
      calls++;
      return http.Response('broken', 200);
    });
    final first = configured(client(), store);
    addTearDown(first.api.close);
    expect(await first.submitOrder({'a': 2}), isFalse);
    final restarted = configured(client(), store);
    addTearDown(restarted.api.close);
    expect(await restarted.syncOrder(), isFalse);
    expect(await restarted.submitOrder({'a': 2}), isFalse);
    expect(restarted.orderUncertain, isTrue);
    expect(restarted.recoveryOrderId, isNull);
    expect(calls, 1);
  });

  test('404 on recovered order retains ID and never infers cancellation or sends POST', () async {
    final store = MemoryOrderRecoveryStore();
    final first = configured(
      MockClient((_) async => fixtures.json(fixtures.order())),
      store,
    );
    addTearDown(first.api.close);
    expect(await first.submitOrder({'a': 2}), isTrue);
    final methods = <String>[];
    final restarted = configured(
      MockClient((r) async {
        methods.add(r.method);
        return fixtures.json({'detail': 'missing'}, 404);
      }),
      store,
    );
    addTearDown(restarted.api.close);
    expect(await restarted.syncOrder(), isFalse);
    expect(await restarted.submitOrder({'a': 2}), isFalse);
    expect(restarted.recoveryOrderId, 'order-test');
    expect(restarted.orderUncertain, isTrue);
    expect(methods, ['GET', 'GET']);
  });

  test('One shared order lock protects distinct carts and writes journal before POST', () async {
    final store = MemoryOrderRecoveryStore();
    final response = Completer<http.Response>();
    var posts = 0;
    final b = configured(
      MockClient((r) async {
        posts++;
        return response.future;
      }),
      store,
    );
    addTearDown(b.api.close);
    final first = b.submitOrder({'a': 2});
    expect(await b.submitOrder({'a': 2}), isFalse);
    expect(await b.cancelOrder(), isFalse);
    await Future<void>.delayed(Duration.zero);
    final restarted = configured(
      MockClient((_) async => throw StateError('No retry permitted')),
      store,
    );
    addTearDown(restarted.api.close);
    expect(
      await restarted.syncOrder(),
      isFalse,
    ); // In-flight POST marker already durable.
    response.complete(fixtures.json(fixtures.order()));
    expect(await first, isTrue);
    expect(posts, 1);
  });

  test(
    'Failed durable write prevents POST and journal is scoped by machine',
    () async {
      var calls = 0;
      final blocked = configured(
        MockClient((_) async {
          calls++;
          throw StateError('no network');
        }),
        BrokenStore(),
      );
      addTearDown(blocked.api.close);
      expect(await blocked.submitOrder({'a': 2}), isFalse);
      expect(calls, 0);
      final store = MemoryOrderRecoveryStore();
      final first = configured(
        MockClient((_) async => http.Response('broken', 200)),
        store,
      );
      addTearDown(first.api.close);
      await first.submitOrder({'a': 2});
      final other = configured(
        MockClient((_) async {
          calls++;
          throw StateError('no network');
        }),
        store,
        machine: 'other-machine',
      );
      addTearDown(other.api.close);
      expect(await other.syncOrder(), isTrue);
      expect(other.orderUncertain, isFalse);
      expect(calls, 0);
    },
  );

  test(
    'Platform journal persists only minimal record and refuses failed commit',
    () async {
      const channel = MethodChannel('moyak/order_recovery');
      final values = <String, String>{};
      var commit = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            final args = call.arguments as Map;
            final key = args['key'] as String;
            if (call.method == 'read') return values[key];
            if (!commit) return false;
            final value = args['value'] as String?;
            if (value == null) {
              values.remove(key);
            } else {
              values[key] = value;
            }
            return true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await const PlatformOrderRecoveryStore().write(
        'scope',
        const OrderRecoveryRecord(orderId: 'order-test', uncertain: true),
      );
      final restored = await const PlatformOrderRecoveryStore().read('scope');
      expect(restored!.orderId, 'order-test');
      expect(restored.uncertain, isTrue);
      expect(
        values['scope'],
        '{"v":1,"order_id":"order-test","uncertain":true}',
      );
      commit = false;
      await expectLater(
        const PlatformOrderRecoveryStore().write('scope', null),
        throwsStateError,
      );
      expect(
        () => OrderRecoveryRecord.decode('corrupt'),
        throwsFormatException,
      );
    },
  );

  test(
    'Late session response cannot restore member after QR invalidation',
    () async {
      final response = Completer<http.Response>();
      final b = configured(
        MockClient(
          (r) async => r.method == 'GET'
              ? response.future
              : fixtures.json({'detail': 'unavailable'}, 503),
        ),
        MemoryOrderRecoveryStore(),
      );
      addTearDown(b.api.close);
      final old = b.querySession();
      expect(identical(old, b.querySession()), isTrue);
      await b.rotateQr();
      response.complete(fixtures.json(session()));
      expect(await old, isA<ServiceFailure<KioskSession>>());
      expect(b.session, isNull);
    },
  );

  testWidgets(
    'Existing paired QR session navigates without rotating or resetting user',
    (tester) async {
      final methods = <String>[];
      final b = configured(
        MockClient((r) async {
          methods.add(r.method);
          return fixtures.json(session());
        }),
        MemoryOrderRecoveryStore(),
      );
      addTearDown(b.api.close);
      await tester.pumpWidget(
        fixtures.app(b, const KioskDevicePairingScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(KioskAuthCompleteScreen), findsOneWidget);
      expect(methods, ['GET']);
    },
  );

  testWidgets(
    'QR resume reuses valid code; unknown session never triggers rotation',
    (tester) async {
      var rotations = 0, reads = 0;
      var fail = false;
      final b = configured(
        MockClient((r) async {
          if (r.method == 'POST') {
            rotations++;
            return fixtures.json({
              'machine_id': 'test-machine',
              'qr_token': 'mock-token',
              'qr_token_expires_at': DateTime.now()
                  .toUtc()
                  .add(const Duration(minutes: 3))
                  .toIso8601String(),
              'qr_svg': '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"/>',
            });
          }
          reads++;
          return fail
              ? fixtures.json({'detail': 'unavailable'}, 503)
              : fixtures.json(session(paired: false));
        }),
        MemoryOrderRecoveryStore(),
      );
      addTearDown(b.api.close);
      await tester.pumpWidget(
        fixtures.app(b, const KioskDevicePairingScreen()),
      );
      await tester.pump();
      await tester.pump();
      expect(rotations, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(reads, 2);
      expect(rotations, 1);
      fail = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(reads, 3);
      expect(rotations, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Home resume refreshes approval and removes stale member when unpaired',
    (tester) async {
      var approved = false, paired = true, calls = 0;
      final b = configured(
        MockClient((request) async {
          if (request.url.path == '/vending/purchases') {
            return fixtures.json(
              approved
                  ? [
                      {
                        'id': 'approval-test',
                        'user_id': 'mock-user',
                        'drug_item_seq': 'test-seq',
                        'drug_item_name': '승인 예시',
                        'status': 'pending',
                        'price': 3500,
                        'expires_at': DateTime.now()
                            .toUtc()
                            .add(const Duration(days: 1))
                            .toIso8601String(),
                      },
                    ]
                  : [],
            );
          }
          calls++;
          return fixtures.json(session(approved: approved, paired: paired));
        }),
        MemoryOrderRecoveryStore(),
      );
      addTearDown(b.api.close);
      await tester.pumpWidget(
        fixtures.app(
          b,
          KioskHomeRouter(liveSession: KioskSession.fromJson(session())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(KioskNoApprovedHomeScreen), findsOneWidget);
      approved = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(KioskLinkedHomeScreen), findsOneWidget);
      approved = false;
      paired = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(KioskMenuScreen), findsOneWidget);
      expect(b.session, isNull);
      expect(calls, 3);
    },
  );
}
