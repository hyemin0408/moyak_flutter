import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moyak_flutter/models/moyak_api_models.dart';
import 'package:moyak_flutter/services/kiosk_backend.dart';
import 'package:moyak_flutter/services/moyak_api_client.dart';
import 'package:moyak_flutter/services/service_result.dart';

void main() {
  test(
    'team-demo is a label, not authorization; all three settings are required',
    () async {
      for (final settings in [
        (machine: '', environment: 'team-demo', allow: true, expected: false),
        (machine: 'VM-001', environment: '', allow: true, expected: false),
        (
          machine: 'VM-001',
          environment: 'team-demo',
          allow: false,
          expected: false,
        ),
        (
          machine: 'VM-001',
          environment: 'team-demo',
          allow: true,
          expected: true,
        ),
      ]) {
        var calls = 0;
        final api = MoyakApiClient(
          client: MockClient((request) async {
            calls++;
            expect(
              request.url.toString(),
              'https://moyak-backend.onrender.com/vending/machines/VM-001/products',
            );
            expect(request.method, 'GET');
            return http.Response('[]', 200);
          }),
        );
        final backend = KioskBackend(
          api: api,
          machineId: settings.machine,
          environment: settings.environment,
          allowMutations: settings.allow,
        );
        expect(backend.mutationError == null, settings.expected);
        final result = await api.kioskProducts('VM-001');
        if (settings.expected) {
          expect(result, isA<ServiceSuccess<List<KioskProduct>>>());
        } else {
          expect(result, isA<ServiceFailure<List<KioskProduct>>>());
        }
        expect(calls, settings.expected ? 1 : 0);
        api.close();
      }
    },
  );

  testWidgets(
    '73-second cold response fits the existing bounded 75-second timeout',
    (tester) async {
      var calls = 0;
      final api = MoyakApiClient(
        client: MockClient((_) async {
          calls++;
          await Future<void>.delayed(const Duration(seconds: 73));
          return http.Response('{"status":"ok"}', 200);
        }),
      );
      addTearDown(api.close);
      expect(api.timeout, const Duration(seconds: 75));
      ServiceResult<bool>? result;
      final request = api.health().then((value) => result = value);
      await tester.pump();
      await tester.pump(const Duration(seconds: 72));
      expect(result, isNull);
      await tester.pump(const Duration(seconds: 1));
      await request;
      expect(result, isA<ServiceSuccess<bool>>());
      expect(calls, 1);
    },
  );

  testWidgets(
    'Response beyond 75 seconds returns timeout without automatic retry',
    (tester) async {
      var calls = 0;
      final api = MoyakApiClient(
        client: MockClient((_) async {
          calls++;
          await Future<void>.delayed(const Duration(seconds: 76));
          return http.Response('{"status":"ok"}', 200);
        }),
      );
      addTearDown(api.close);
      ServiceResult<bool>? result;
      final request = api.health().then((value) => result = value);
      await tester.pump();
      await tester.pump(const Duration(seconds: 75));
      await request;
      expect(result, isA<ServiceFailure<bool>>());
      expect(
        (result as ServiceFailure<bool>).error.code,
        ServiceErrorCode.timeout,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(calls, 1);
      expect(result, isA<ServiceFailure<bool>>());
    },
  );
}
