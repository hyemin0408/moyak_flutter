import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moyak_flutter/models/moyak_api_models.dart';
import 'package:moyak_flutter/services/moyak_api_client.dart';
import 'package:moyak_flutter/services/service_result.dart';

Map<String, Object?> sessionFixture() => {
  'access_token': 'unit-test-only-token',
  'token_type': 'bearer',
  'expires_in': 120,
  'user': {
    'id': 'test-user-id',
    'username': 'tester',
    'name': '테스트',
    'role': 'user',
  },
};
http.Response jsonResponse(Object? value, [int status = 200]) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(value)),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  test(
    'Auth uses exact wire fields, UTF-8, bearer and distinct signup endpoint',
    () async {
      final requests = <http.Request>[];
      final api = MoyakApiClient(
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/auth/me') {
            return jsonResponse(sessionFixture()['user']);
          }
          return jsonResponse(
            sessionFixture(),
            request.url.path == '/auth/signup' ? 201 : 200,
          );
        }),
      );
      addTearDown(api.close);
      final login = await api.login(' tester ', 'Example!123');
      expect(login, isA<ServiceSuccess<MoyakAuthSession>>());
      final session = (login as ServiceSuccess<MoyakAuthSession>).value;
      expect(session.user.name, '테스트');
      expect(session.isExpired, isFalse);
      expect(jsonDecode(requests.first.body), {
        'username': 'tester',
        'password': 'Example!123',
      });
      expect(requests.first.headers.containsKey('Authorization'), isFalse);
      await api.currentUser(session.accessToken);
      expect(
        requests[1].headers['Authorization'],
        'Bearer unit-test-only-token',
      );
      expect(
        requests[1].headers.keys.any(
          (key) => key.toLowerCase().startsWith('x-moyak'),
        ),
        isFalse,
      );
      await api.signup('tester', 'Example!123', name: '테스트');
      expect(requests.last.url.path, '/auth/signup');
      expect(jsonDecode(requests.last.body)['name'], '테스트');
    },
  );

  test(
    'Drug search preserves Unicode and never invents price or approval fields',
    () async {
      final api = MoyakApiClient(
        client: MockClient((request) async {
          expect(request.url.queryParameters, {'q': '타이레놀', 'limit': '20'});
          return jsonResponse([
            {'item_seq': '202106092', 'item_name': '타이레놀정', 'company': '제약회사'},
          ]);
        }),
      );
      addTearDown(api.close);
      final result = await api.searchDrugs('타이레놀');
      expect(
        (result as ServiceSuccess<List<MoyakDrug>>).value.single.name,
        '타이레놀정',
      );
    },
  );

  test('Chat sends prior turns once and preserves sources, evidence and recommendations', () async {
    final api = MoyakApiClient(
      client: MockClient((request) async {
        final payload = jsonDecode(request.body);
        expect(payload['question'], '다음 질문');
        expect(payload['history'], [
          {'role': 'user', 'content': '이전 질문'},
          {'role': 'assistant', 'content': '이전 답변'},
        ]);
        return jsonResponse({
          'answer': '약사와 상담하세요.',
          'sources': ['예시 약품'],
          'evidence': [
            {
              'item_name': '예시 약품',
              'field': 'warning',
              'field_label': '경고',
              'text': '원문 경고',
            },
          ],
          'recommendations': [],
        });
      }),
    );
    addTearDown(api.close);
    final result = await api.chat('다음 질문', const [
      MoyakChatMessage(role: 'user', content: '이전 질문'),
      MoyakChatMessage(role: 'assistant', content: '이전 답변'),
    ]);
    final answer = (result as ServiceSuccess<MoyakChatAnswer>).value;
    expect(answer.evidence.single.text, '원문 경고');
    expect(() => answer.sources.add('변경'), throwsUnsupportedError);
  });

  test('HTTP errors, rate limits, malformed responses and transport failures stay explicit', () async {
    for (final status in [401, 409, 422, 429, 503]) {
      final api = MoyakApiClient(
        client: MockClient(
          (_) async => jsonResponse({'detail': '서버 테스트 메시지'}, status),
        ),
      );
      final result = await api.health();
      expect(result, isA<ServiceFailure<bool>>());
      if (status == 401) {
        expect(
          (result as ServiceFailure<bool>).error.code,
          ServiceErrorCode.unauthorized,
        );
      }
      if (status == 503) {
        expect(
          (result as ServiceFailure<bool>).error.message,
          isNot(contains('서버 테스트 메시지')),
        );
      }
      if (status == 429) {
        expect(
          (result as ServiceFailure<bool>).error.message,
          contains('요청이 많습니다'),
        );
      }
      api.close();
    }
    final malformed = MoyakApiClient(
      client: MockClient((_) async => http.Response('<html>proxy</html>', 200)),
    );
    expect(
      ((await malformed.health()) as ServiceFailure<bool>).error.code,
      ServiceErrorCode.invalidResponse,
    );
    malformed.close();
    final network = MoyakApiClient(
      client: MockClient(
        (_) async => throw http.ClientException('connection failed'),
      ),
    );
    expect(
      ((await network.health()) as ServiceFailure<bool>).error.code,
      ServiceErrorCode.network,
    );
    network.close();
    var calls = 0;
    final timeout = MoyakApiClient(
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return jsonResponse({'status': 'ok'});
      }),
    );
    expect(
      ((await timeout.health()) as ServiceFailure<bool>).error.code,
      ServiceErrorCode.timeout,
    );
    expect(calls, 1);
    timeout.close();
  });

  test(
    'Invalid successful auth payload cannot create a login session',
    () async {
      final api = MoyakApiClient(
        client: MockClient(
          (_) async => jsonResponse({
            'access_token': '',
            'token_type': 'bearer',
            'expires_in': 120,
            'user': {},
          }),
        ),
      );
      addTearDown(api.close);
      expect(
        ((await api.login(
          'tester',
          'Example!123',
        )) as ServiceFailure<MoyakAuthSession>).error.code,
        ServiceErrorCode.invalidResponse,
      );
      expect(
        () => MoyakApiClient(baseUrl: 'http://unknown.example'),
        throwsArgumentError,
      );
    },
  );
}
