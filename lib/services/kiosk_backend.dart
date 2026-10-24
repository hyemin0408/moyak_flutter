import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../demo/demo_cart.dart';
import '../demo/demo_products.dart';
import '../models/moyak_api_models.dart';
import 'moyak_api_client.dart';
import 'service_result.dart';
import 'order_recovery_store.dart';

final kioskRouteObserver = RouteObserver<ModalRoute<void>>();

/// No guessed machine ID. Mutations require an explicitly approved environment.
class KioskBackend {
  KioskBackend({
    required this.api,
    required this.machineId,
    this.allowMutations = false,
    this.environment = '',
    OrderRecoveryStore? recoveryStore,
  }) : recoveryStore = recoveryStore ?? MemoryOrderRecoveryStore() {
    api.bindKioskPolicy(() => mutationError);
  }
  final OrderRecoveryStore recoveryStore;
  final MoyakApiClient api;
  final String machineId, environment;
  final bool allowMutations;
  // Application-wide guard survives leaving a screen after an ambiguous POST.
  bool orderUncertain = false;
  KioskOrder? pendingOrder;
  KioskOrder? latestOrder;
  String? recoveryOrderId;
  String? orderError;
  bool orderBusy = false;
  bool _restored = false;
  bool _qrBusy = false;
  int _sessionEpoch = 0;
  Future<ServiceResult<KioskSession>>? _sessionRead;
  KioskSession? session;
  List<KioskApprovedPurchase> approvedPurchases = const [];
  String get memberLabel => '${session?.displayName ?? '연동 회원'} 님';
  String? get configurationError =>
      machineId.trim().isEmpty ? '키오스크 기기 ID가 설정되지 않았습니다.' : null;
  String? get mutationError =>
      configurationError ??
      (!allowMutations || environment.trim().isEmpty
          ? '승인된 테스트 환경 설정이 필요합니다. 서버 변경 요청을 보내지 않았습니다.'
          : null);

  String get _recoveryKey =>
      jsonEncode([api.recoveryNamespace, environment, machineId]);

  Future<bool> _restore() async {
    if (_restored) return true;
    try {
      final record = await recoveryStore.read(_recoveryKey);
      recoveryOrderId = record?.orderId;
      orderUncertain = record?.uncertain ?? false;
      _restored = true;
      return true;
    } catch (_) {
      orderError = '주문 복구 기록을 읽지 못했습니다. 중복 주문 방지를 위해 직원에게 문의해 주세요.';
      orderUncertain = true;
      return false;
    }
  }

  Future<bool> _save(OrderRecoveryRecord? record) async {
    try {
      await recoveryStore.write(_recoveryKey, record);
      recoveryOrderId = record?.orderId;
      orderUncertain = record?.uncertain ?? false;
      return true;
    } catch (_) {
      orderUncertain = true;
      orderError = '주문 복구 기록을 저장하지 못했습니다. 자동 재주문하지 않습니다.';
      return false;
    }
  }

  Future<bool> _syncOrderLocked() async {
    if (!await _restore()) return false;
    final id = pendingOrder?.id ?? recoveryOrderId;
    if (id == null) {
      if (orderUncertain) {
        orderError = '주문 ID를 받지 못한 요청이 있습니다. 서버 확인 전 재주문할 수 없습니다.';
      }
      return !orderUncertain;
    }
    final result = await api.kioskOrder(id);
    switch (result) {
      case ServiceSuccess<KioskOrder>():
        final value = result.value;
        if (value.id != id || value.machineId != machineId) {
          orderUncertain = true;
          orderError = '복구한 주문의 기기 또는 주문 ID가 일치하지 않습니다.';
          return false;
        }
        latestOrder = value;
        if (value.status == 'cancelled') {
          if (!await _save(null)) return false;
          pendingOrder = null;
          orderError = null;
          return true;
        }
        pendingOrder = value;
        if (!await _save(OrderRecoveryRecord(orderId: id, uncertain: false))) {
          return false;
        }
        // Backend paid/dispensed values are not proof of PG or hardware success.
        orderError = value.status == 'cart'
            ? null
            : '서버 주문 상태: ${value.status}. 실제 결제·배출 결과는 별도 확인이 필요합니다.';
        return true;
      case ServiceFailure<KioskOrder>():
        orderUncertain = true;
        orderError = result.error.message;
        // 404 may mean a reset DB; never infer cancellation or resubmit.
        return false;
    }
  }

  Future<bool> syncOrder() async {
    if (orderBusy) return false;
    orderError = mutationError;
    if (orderError != null) return false;
    orderBusy = true;
    try {
      return await _syncOrderLocked();
    } finally {
      orderBusy = false;
    }
  }

  Future<bool> submitOrder(Map<String, int> items) async {
    if (orderBusy) return false;
    // Capture before the first await: callers must not mutate an in-flight cart.
    final requestedItems = Map<String, int>.unmodifiable(items);
    orderError = mutationError;
    if (orderError != null) return false;
    orderBusy = true;
    try {
      if (!await _restore()) return false;
      if (pendingOrder != null || recoveryOrderId != null || orderUncertain) {
        await _syncOrderLocked();
        orderError ??= '기존 주문 상태를 확인했습니다. 새 주문은 보내지 않았습니다.';
        return false;
      }
      if (requestedItems.isEmpty ||
          requestedItems.entries.any(
            (e) => e.key.trim().isEmpty || e.value < 1,
          )) {
        orderError = '장바구니 상품과 수량을 확인해 주세요.';
        return false;
      }
      // Durable uncertainty marker BEFORE sending POST, including crash window.
      if (!await _save(const OrderRecoveryRecord(uncertain: true))) {
        return false;
      }
      final result = await api.createKioskOrder(machineId, requestedItems);
      switch (result) {
        case ServiceSuccess<KioskOrder>():
          pendingOrder = result.value;
          latestOrder = result.value;
          if (!await _save(
            OrderRecoveryRecord(orderId: result.value.id, uncertain: true),
          )) {
            return false;
          }
          if (result.value.machineId != machineId ||
              result.value.status != 'cart' ||
              result.value.lines.length != requestedItems.length ||
              result.value.lines.fold<int>(0, (s, l) => s + l.quantity) !=
                  requestedItems.values.fold<int>(0, (s, q) => s + q)) {
            orderError = '주문 응답이 요청과 일치하지 않습니다. 자동 재요청하지 않습니다.';
            return false;
          }
          if (!await _save(
            OrderRecoveryRecord(orderId: result.value.id, uncertain: false),
          )) {
            return false;
          }
          orderError = null;
          return true;
        case ServiceFailure<KioskOrder>():
          if ({
            ServiceErrorCode.validation,
            ServiceErrorCode.conflict,
            ServiceErrorCode.notFound,
            ServiceErrorCode.unauthorized,
            ServiceErrorCode.forbidden,
          }.contains(result.error.code)) {
            if (!await _save(null)) return false;
          }
          orderError = result.error.message;
          return false;
      }
    } finally {
      orderBusy = false;
    }
  }

  Future<bool> cancelOrder() async {
    if (orderBusy) return false;
    orderError = mutationError;
    if (orderError != null) return false;
    orderBusy = true;
    try {
      if (!await _syncOrderLocked()) return false;
      final order = pendingOrder;
      if (order == null) return !orderUncertain;
      if (order.status != 'cart') {
        orderError = '미결제 주문만 취소할 수 있습니다. 서버 상태를 확인해 주세요.';
        return false;
      }
      final result = await api.cancelKioskOrder(order.id);
      switch (result) {
        case ServiceSuccess<KioskOrder>():
          if (result.value.id != order.id ||
              result.value.machineId != machineId ||
              result.value.status != 'cancelled') {
            orderUncertain = true;
            orderError = '주문 취소 상태를 확인할 수 없습니다.';
            return false;
          }
          latestOrder = result.value;
          if (!await _save(null)) return false;
          pendingOrder = null;
          orderError = null;
          return true;
        case ServiceFailure<KioskOrder>():
          orderUncertain = true;
          orderError = result.error.message;
          return false;
      }
    } finally {
      orderBusy = false;
    }
  }

  Future<ServiceResult<KioskSession>> querySession() {
    final existing = _sessionRead;
    if (existing != null) return existing;
    late final Future<ServiceResult<KioskSession>> attempt;
    attempt = _querySession().whenComplete(() {
      if (identical(_sessionRead, attempt)) _sessionRead = null;
    });
    _sessionRead = attempt;
    return attempt;
  }

  void invalidateSessionReads() {
    _sessionEpoch++;
    _sessionRead = null;
  }

  Future<ServiceResult<LiveApprovedKioskCart>> loadApprovedCart({
    KioskSession? verifiedSession,
  }) async {
    final error = mutationError;
    if (error != null) {
      return ServiceFailure(
        ServiceError(code: ServiceErrorCode.notConfigured, message: error),
      );
    }
    KioskSession linked;
    if (verifiedSession == null) {
      final result = await querySession();
      if (result is ServiceFailure<KioskSession>) {
        return ServiceFailure(result.error);
      }
      linked = (result as ServiceSuccess<KioskSession>).value;
    } else {
      linked = verifiedSession;
    }
    if (!linked.paired ||
        linked.machineId != machineId ||
        linked.userId == null ||
        !identical(session, linked)) {
      approvedPurchases = const [];
      return const ServiceFailure(
        ServiceError(
          code: ServiceErrorCode.unauthorized,
          message: '휴대폰 앱에서 이 기기를 연결한 뒤 승인 약을 확인해 주세요.',
        ),
      );
    }
    final epoch = _sessionEpoch;
    final result = await api.kioskPurchases(linked.userId!);
    if (epoch != _sessionEpoch || !identical(session, linked)) {
      return const ServiceFailure(
        ServiceError(
          code: ServiceErrorCode.conflict,
          message: '기기 연결이 변경되었습니다. 승인 목록을 다시 확인해 주세요.',
        ),
      );
    }
    switch (result) {
      case ServiceFailure<List<KioskApprovedPurchase>>():
        approvedPurchases = const [];
        return ServiceFailure(result.error);
      case ServiceSuccess<List<KioskApprovedPurchase>>():
        final values = result.value;
        if (values.any((p) => p.userId != linked.userId) ||
            values.map((p) => p.id).toSet().length != values.length) {
          approvedPurchases = const [];
          return const ServiceFailure(
            ServiceError(
              code: ServiceErrorCode.invalidResponse,
              message: '승인 목록의 회원 또는 승인 ID를 확인할 수 없습니다.',
            ),
          );
        }
        approvedPurchases = List.unmodifiable(values.where((p) => p.available));
        return ServiceSuccess(
          LiveApprovedKioskCart(this, linked.userId!, approvedPurchases),
        );
    }
  }

  Future<ServiceResult<KioskSession>> _querySession() async {
    final error = mutationError;
    if (error != null) {
      return ServiceFailure(
        ServiceError(code: ServiceErrorCode.notConfigured, message: error),
      );
    }
    if (_qrBusy) {
      return const ServiceFailure(
        ServiceError(
          code: ServiceErrorCode.conflict,
          message: '기기 QR을 갱신 중입니다. 완료 후 세션을 다시 확인해 주세요.',
        ),
      );
    }
    final epoch = _sessionEpoch;
    final result = await api.kioskSession(machineId);
    if (epoch != _sessionEpoch) {
      return const ServiceFailure(
        ServiceError(
          code: ServiceErrorCode.conflict,
          message: '기기 세션이 변경되었습니다. 다시 확인해 주세요.',
        ),
      );
    }
    if (result is ServiceSuccess<KioskSession>) {
      if (result.value.machineId != machineId) {
        session = null;
        approvedPurchases = const [];
        return const ServiceFailure(
          ServiceError(
            code: ServiceErrorCode.invalidResponse,
            message: '기기 세션이 일치하지 않습니다.',
          ),
        );
      }
      session = result.value.paired ? result.value : null;
      if (session == null) approvedPurchases = const [];
    } else {
      session = null;
      approvedPurchases = const [];
    }
    return result;
  }

  Future<ServiceResult<KioskQr>> rotateQr() async {
    final error = mutationError;
    if (error != null) {
      return ServiceFailure(
        ServiceError(code: ServiceErrorCode.notConfigured, message: error),
      );
    }
    if (_qrBusy) {
      return const ServiceFailure(
        ServiceError(
          code: ServiceErrorCode.conflict,
          message: '기기 QR 요청을 처리 중입니다.',
        ),
      );
    }
    _qrBusy = true;
    invalidateSessionReads();
    session = null;
    approvedPurchases = const [];
    try {
      return await api.rotateKioskQr(machineId);
    } finally {
      invalidateSessionReads();
      _qrBusy = false;
    }
  }
}

/// Lives above Navigator so existing routes share the same configured client.
class KioskBackendScope extends InheritedWidget {
  const KioskBackendScope({
    super.key,
    required this.backend,
    required super.child,
  });
  final KioskBackend backend;
  static KioskBackend? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KioskBackendScope>()?.backend;
  @override
  bool updateShouldNotify(KioskBackendScope oldWidget) =>
      backend != oldWidget.backend;
}

/// Server-approved quantities are fixed; price is the entire approval line total.
/// Approval IDs never enter the ordinary product-order API or payment preview.
class LiveApprovedKioskCart extends DemoCart {
  LiveApprovedKioskCart(
    this.backend,
    this.userId,
    List<KioskApprovedPurchase> values,
  ) : approvals = List.unmodifiable(values),
      super(
        products: [
          for (final p in values)
            DemoProduct(
              p.name,
              '약사 승인',
              p.price ?? 0,
              p.price == null ? '가격 확인 필요' : '${p.price}원',
              demoProducts.where((d) => d.name == p.name).firstOrNull?.image ??
                  '',
              const [],
              0,
              0,
              id: p.id,
            ),
        ],
        quantities: {
          for (var i = 0; i < values.length; i++) i: values[i].quantity,
        },
        approvedLimits: {
          for (var i = 0; i < values.length; i++) i: values[i].quantity,
        },
      );
  final KioskBackend backend;
  final String userId;
  final List<KioskApprovedPurchase> approvals;
  @override
  int get totalWon =>
      quantities.keys.fold(0, (sum, i) => sum + (approvals[i].price ?? 0));

  @override
  void setQuantity(int index, int quantity) {
    if (index < 0 ||
        index >= approvals.length ||
        quantity != approvals[index].quantity) {
      throw ArgumentError('Approved quantity cannot be changed');
    }
    super.setQuantity(index, quantity);
  }

  bool get hasUnknownPrice =>
      quantities.keys.any((i) => approvals[i].price == null);

  Future<String?> validateSelection() async {
    final selected = Map<String, int>.of(productQuantities);
    if (selected.isEmpty) return '장바구니가 비어 있습니다.';
    final result = await backend.loadApprovedCart();
    switch (result) {
      case ServiceFailure<LiveApprovedKioskCart>():
        return result.error.message;
      case ServiceSuccess<LiveApprovedKioskCart>():
        final fresh = result.value;
        try {
          if (fresh.userId != userId) {
            clear();
            return '기기에 연결된 회원이 변경되었습니다. 홈에서 다시 확인해 주세요.';
          }
          if (selected.length != productQuantities.length ||
              selected.entries.any(
                (e) => productQuantities[e.key] != e.value,
              )) {
            return '선택한 약이 변경되었습니다. 장바구니를 다시 확인해 주세요.';
          }
          final current = {for (final p in fresh.approvals) p.id: p};
          for (final index in quantities.keys) {
            final previous = approvals[index];
            final now = current[previous.id];
            if (now == null ||
                now.price != previous.price ||
                now.quantity != previous.quantity ||
                now.name != previous.name ||
                now.itemSeq != previous.itemSeq) {
              return '승인 상태 또는 가격이 변경되었습니다. 홈에서 목록을 다시 확인해 주세요.';
            }
          }
          return hasUnknownPrice
              ? '승인 약 가격을 확인할 수 없습니다. 담당 약사에게 문의해 주세요.'
              : null;
        } finally {
          fresh.dispose();
        }
    }
  }
}

class LiveKioskCart extends DemoCart {
  LiveKioskCart(this.backend) : super(products: const [], quantities: const {});
  final KioskBackend backend;
  KioskOrder? get order => backend.pendingOrder;
  set order(KioskOrder? value) => backend.pendingOrder = value;
  bool busy = false;
  bool get uncertain => backend.orderUncertain;
  set uncertain(bool value) => backend.orderUncertain = value;
  String? error;
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  KioskOrder? get displayOrder => backend.latestOrder ?? order;

  Future<bool> load() async {
    if (busy || backend.orderBusy) return false;
    busy = true;
    notifyListeners();
    try {
      if (!await backend.syncOrder()) {
        error = backend.orderError;
        return false;
      }
      if (order != null) {
        error = '기존 주문을 복구했습니다. 주문 내역을 확인해 주세요.';
        return false;
      }
      final result = await backend.api.kioskProducts(backend.machineId);
      switch (result) {
        case ServiceSuccess<List<KioskProduct>>():
          try {
            replaceProducts(result.value.map(_present).toList());
            error = null;
          } on ArgumentError {
            error = '서버 상품 ID가 중복되거나 올바르지 않습니다.';
          }
        case ServiceFailure<List<KioskProduct>>():
          error = result.error.message;
      }
      return error == null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> syncOrder() async {
    if (busy) return false;
    busy = true;
    notifyListeners();
    try {
      final ok = await backend.syncOrder();
      error = backend.orderError;
      return ok;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> createOrder() async {
    if (busy) return false;
    busy = true;
    notifyListeners();
    try {
      final ok = await backend.submitOrder(Map.of(productQuantities));
      error = backend.orderError;
      return ok;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> cancelOrder() async {
    if (busy) return false;
    busy = true;
    notifyListeners();
    try {
      final ok = await backend.cancelOrder();
      error = backend.orderError;
      return ok;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  void setQuantity(int index, int quantity) {
    if (busy || backend.orderBusy || order != null || uncertain) {
      throw ArgumentError('Order locked');
    }
    super.setQuantity(index, quantity);
  }

  @override
  void remove(int index) {
    if (busy || backend.orderBusy || order != null || uncertain) return;
    super.remove(index);
  }

  static DemoProduct _present(KioskProduct p) {
    const categories = [
      '전체',
      '진통/해열제',
      '소화/위장약',
      '감기약/기침약',
      '상처/연고',
      '안대/밴드/기타',
    ];
    // Exact known catalog names only; unknown items never borrow another drug's image.
    final known = demoProducts.where((d) => d.name == p.name).firstOrNull;
    return DemoProduct(
      p.name,
      p.badge,
      p.price,
      '${p.price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원',
      known?.image ?? '',
      [if (categories.indexOf(p.category) > 0) categories.indexOf(p.category)],
      known?.imageX ?? 45,
      known?.imageY ?? 12,
      id: p.id,
      stock: p.stock,
      company: p.company,
      itemSeq: p.itemSeq,
    );
  }
}
