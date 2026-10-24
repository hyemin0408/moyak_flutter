import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/moyak_api_models.dart';
import 'service_result.dart';

/// Confirmed deployment from the repository README. Overridable at build time.
const moyakApiBaseUrl = String.fromEnvironment(
  'MOYAK_API_BASE_URL',
  defaultValue: 'https://moyak-backend.onrender.com',
);

/// No demo identities, no fabricated responses, no automatic POST retries.
class MoyakApiClient {
  MoyakApiClient({
    http.Client? client,
    String baseUrl = moyakApiBaseUrl,
    this.timeout = const Duration(seconds: 75),
  }) : _client = client ?? http.Client(),
       _baseUrl = Uri.parse(baseUrl) {
    if (_baseUrl.scheme != 'https' ||
        !_baseUrl.hasAuthority ||
        _baseUrl.userInfo.isNotEmpty ||
        _baseUrl.hasQuery ||
        _baseUrl.hasFragment) {
      throw ArgumentError('MOYAK_API_BASE_URL must be an absolute HTTPS URL');
    }
  }
  final http.Client _client;
  final Uri _baseUrl;
  final Duration timeout;
  String get serverLabel => _baseUrl.origin;
  String get recoveryNamespace => _baseUrl.toString();
  String? Function()? _kioskPolicy;
  void bindKioskPolicy(String? Function() policy) {
    if (_kioskPolicy != null) {
      throw StateError('Kiosk policy already configured');
    }
    _kioskPolicy = policy;
  }

  void close() => _client.close();

  Future<ServiceResult<T>> _request<T>(
    String method,
    String path,
    T Function(Object?) parse, {
    Map<String, String>? query,
    Object? body,
    String? token,
  }) async {
    if (path.startsWith('/vending/')) {
      final error = _kioskPolicy == null
          ? '키오스크 서버 요청 정책이 설정되지 않았습니다.'
          : _kioskPolicy!();
      if (error != null) {
        return ServiceFailure(
          ServiceError(code: ServiceErrorCode.notConfigured, message: error),
        );
      }
    }
    try {
      final uri = _baseUrl.replace(
        path: '${_baseUrl.path.replaceFirst(RegExp(r'/$'), '')}$path',
        queryParameters: query,
      );
      final request = http.Request(method, uri)
        ..headers['Accept'] = 'application/json';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json; charset=utf-8';
        request.body = jsonEncode(body);
      }
      final response = await (() async => http.Response.fromStream(
        await _client.send(request),
      ))().timeout(timeout);
      Object? decoded;
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        if (response.statusCode >= 200 && response.statusCode < 300) rethrow;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return ServiceFailure(_httpError(response.statusCode, decoded));
      }
      return ServiceSuccess(parse(decoded));
    } on TimeoutException {
      return const ServiceFailure(
        ServiceError(
          code: ServiceErrorCode.timeout,
          message: '서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.',
        ),
      );
    } on http.ClientException {
      return const ServiceFailure(
        ServiceError(
          code: ServiceErrorCode.network,
          message: '서버에 연결하지 못했습니다. 네트워크 연결을 확인해 주세요.',
        ),
      );
    } on FormatException {
      return const ServiceFailure(
        ServiceError(
          code: ServiceErrorCode.invalidResponse,
          message: '서버 응답 형식을 확인할 수 없습니다. 잠시 후 다시 시도해 주세요.',
        ),
      );
    }
  }

  ServiceError _httpError(int status, Object? body) {
    final code = switch (status) {
      401 => ServiceErrorCode.unauthorized,
      403 => ServiceErrorCode.forbidden,
      404 => ServiceErrorCode.notFound,
      409 => ServiceErrorCode.conflict,
      400 || 422 => ServiceErrorCode.validation,
      _ => ServiceErrorCode.unavailable,
    };
    String message = switch (status) {
      401 => '로그인이 필요하거나 로그인 정보가 올바르지 않습니다.',
      403 => '접근 권한이 없습니다.',
      404 => '요청한 정보를 찾을 수 없습니다.',
      409 => '이미 처리되었거나 중복된 요청입니다.',
      400 || 422 => '입력한 내용을 확인해 주세요.',
      429 => '요청이 많습니다. 잠시 기다린 뒤 다시 시도해 주세요.',
      _ => '서버 서비스를 사용할 수 없습니다. 잠시 후 다시 시도해 주세요.',
    };
    // Validation errors are displayed by field location, not by echoing inputs.
    if (status >= 400 &&
        status < 500 &&
        status != 429 &&
        body is Map<String, dynamic>) {
      final detail = body['detail'];
      if (detail is String && detail.length <= 300) message = detail;
    }
    return ServiceError(code: code, message: message);
  }

  Future<ServiceResult<bool>> health() => _request('GET', '/health', (value) {
    if (apiString(apiObject(value), 'status') != 'ok') {
      throw const FormatException('Invalid health');
    }
    return true;
  });
  Future<ServiceResult<List<KioskProduct>>> kioskProducts(String machineId) =>
      _request(
        'GET',
        '/vending/machines/${Uri.encodeComponent(machineId)}/products',
        (v) => apiList(v, KioskProduct.fromJson),
      );

  Future<ServiceResult<KioskOrder>> createKioskOrder(
    String machineId,
    Map<String, int> quantities,
  ) => _request(
    'POST',
    '/vending/machines/${Uri.encodeComponent(machineId)}/orders',
    KioskOrder.fromJson,
    body: {
      'items': [
        for (final e in quantities.entries)
          {'product_id': e.key, 'quantity': e.value},
      ],
    },
  );

  Future<ServiceResult<KioskOrder>> kioskOrder(String id) => _request(
    'GET',
    '/vending/orders/${Uri.encodeComponent(id)}',
    KioskOrder.fromJson,
  );
  Future<ServiceResult<KioskOrder>> cancelKioskOrder(String id) => _request(
    'POST',
    '/vending/orders/${Uri.encodeComponent(id)}/cancel',
    KioskOrder.fromJson,
  );
  Future<ServiceResult<KioskQr>> rotateKioskQr(String machineId) => _request(
    'POST',
    '/vending/machines/${Uri.encodeComponent(machineId)}/rotate-qr',
    KioskQr.fromJson,
  );
  Future<ServiceResult<KioskSession>> kioskSession(String machineId) =>
      _request(
        'GET',
        '/vending/machines/${Uri.encodeComponent(machineId)}/session',
        KioskSession.fromJson,
      );
  Future<ServiceResult<List<KioskApprovedPurchase>>> kioskPurchases(
    String userId,
  ) => _request(
    'GET',
    '/vending/purchases',
    (value) => apiList(value, KioskApprovedPurchase.fromJson),
    query: {'user_id': userId},
  );
  Future<ServiceResult<bool>> usernameAvailable(String username) =>
      _request('GET', '/auth/username-available', (value) {
        final available = apiObject(value)['available'];
        if (available is! bool) {
          throw const FormatException('Invalid availability');
        }
        return available;
      }, query: {'username': username.trim()});
  Future<ServiceResult<MoyakAuthSession>> login(
    String username,
    String password,
  ) => _request(
    'POST',
    '/auth/login',
    MoyakAuthSession.fromJson,
    body: {'username': username.trim(), 'password': password},
  );
  Future<ServiceResult<MoyakAuthSession>> signup(
    String username,
    String password, {
    String? name,
  }) => _request(
    'POST',
    '/auth/signup',
    MoyakAuthSession.fromJson,
    body: {
      'username': username.trim(),
      'password': password,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
    },
  );
  Future<ServiceResult<MoyakUser>> currentUser(String token) =>
      _request('GET', '/auth/me', MoyakUser.fromJson, token: token);
  Future<ServiceResult<List<MoyakDrug>>> searchDrugs(String query) => _request(
    'GET',
    '/drugs/search',
    (value) => apiList(value, MoyakDrug.fromJson),
    query: {'q': query.trim(), 'limit': '20'},
  );
  Future<ServiceResult<MoyakChatAnswer>> chat(
    String question,
    List<MoyakChatMessage> history,
  ) => _request(
    'POST',
    '/chat',
    MoyakChatAnswer.fromJson,
    body: {
      'question': question.trim(),
      'history': history.map((m) => m.toJson()).toList(),
    },
  );
}
