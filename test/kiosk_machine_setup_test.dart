import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moyak_flutter/models/kiosk_machine.dart';
import 'package:moyak_flutter/screens/kiosk_machine_setup_screen.dart';
import 'package:moyak_flutter/services/kiosk_machine_store.dart';
import 'package:moyak_flutter/services/moyak_api_client.dart';
import 'package:moyak_flutter/services/service_result.dart';
import 'package:moyak_flutter/services/kiosk_backend.dart';
import 'package:moyak_flutter/services/order_recovery_store.dart';
import 'package:moyak_flutter/models/moyak_api_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const machine = KioskMachine(
    code: 'VM-001',
    name: '동양미래대학교 학생회관',
    address: '서울 구로구 경인로 445',
  );
  test('machine change blocks carts, paired users and recovery on either machine without HTTP', () async {
    var calls = 0;
    final api = MoyakApiClient(
      client: MockClient((_) async {
        calls++;
        throw StateError('Machine change must not call server');
      }),
    );
    addTearDown(api.close);
    final store = MemoryOrderRecoveryStore();
    final backend = KioskBackend(
      api: api,
      machineId: 'VM-001',
      environment: 'test',
      recoveryStore: store,
    );
    expect(await backend.machineChangeError(), isNull);
    final cart = LiveKioskCart(backend);
    cart.busy = true;
    expect(await backend.machineChangeError(), isNotNull);
    cart.busy = false;
    backend.session = KioskSession.fromJson({
      'machine_id': 'VM-001',
      'paired': true,
      'user_id': 'test-user',
    });
    expect(await backend.machineChangeError(), isNotNull);
    backend.session = null;
    backend.orderUncertain = true;
    expect(await backend.machineChangeError(), isNotNull);
    backend.orderUncertain = false;
    for (final code in ['VM-001', 'VM-002']) {
      final key = jsonEncode([api.recoveryNamespace, 'test', code]);
      await store.write(
        key,
        const OrderRecoveryRecord(orderId: 'unresolved', uncertain: false),
      );
      expect(
        await backend.machineChangeError(targetMachineId: 'VM-002'),
        isNotNull,
      );
      await store.write(key, null);
    }
    cart.dispose();
    expect(await backend.machineChangeError(targetMachineId: 'VM-002'), isNull);
    expect(calls, 0);
  });
  test(
    'directory uses code rather than map UUID and rejects ambiguity',
    () async {
      for (final duplicate in [false, true]) {
        final api = MoyakApiClient(
          client: MockClient((r) async {
            expect(r.method, 'GET');
            expect(r.url.path, '/api/v1/map/machines');
            final row = {...machine.toJson(), 'id': 'map-uuid-not-order-code'};
            return http.Response(
              jsonEncode({
                'truncated': false,
                'items': [row, if (duplicate) row],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        );
        final result = await api.kioskMachines();
        if (duplicate) {
          expect(result, isA<ServiceFailure<List<KioskMachine>>>());
        } else {
          expect(
            (result as ServiceSuccess<List<KioskMachine>>).value.single.code,
            'VM-001',
          );
        }
        api.close();
      }
    },
  );

  test(
    'installation persists per server, restores and fails on failed commit',
    () async {
      const channel = MethodChannel('moyak/order_recovery');
      final saved = <String, String>{};
      var fail = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            final args = call.arguments as Map;
            final key = args['key'] as String;
            if (call.method == 'read') return saved[key];
            if (fail) return false;
            saved[key] = args['value'] as String;
            return true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      const store = KioskMachineStore();
      expect(await store.read('server-a'), isNull);
      await store.write('server-a', machine);
      expect(
        (await const KioskMachineStore().read('server-a'))!.name,
        machine.name,
      );
      expect(await store.read('server-b'), isNull);
      fail = true;
      await expectLater(store.write('server-a', machine), throwsStateError);
    },
  );

  testWidgets(
    'operator selects real location, selection does not call vending API',
    (tester) async {
      final paths = <String>[];
      final api = MoyakApiClient(
        client: MockClient((r) async {
          paths.add(r.url.path);
          return http.Response(
            jsonEncode({
              'truncated': false,
              'items': [machine.toJson()],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(api.close);
      KioskMachine? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: KioskMachineSetupScreen(
            api: api,
            onSelected: (m) async {
              selected = m;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(selected, isNull);
      await tester.tap(find.text(machine.name));
      await tester.pump();
      await tester.ensureVisible(find.text('선택한 자판기로 설정'));
      await tester.tap(find.text('선택한 자판기로 설정'));
      await tester.pump();
      expect(selected!.code, 'VM-001');
      expect(paths, ['/api/v1/map/machines']);
    },
  );
}
