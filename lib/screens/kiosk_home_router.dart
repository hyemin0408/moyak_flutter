import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../demo/demo_approved_cart.dart';
import '../demo/demo_cart.dart';
import 'kiosk_cart_screen.dart';

import 'kiosk_linked_home_screen.dart';
import 'kiosk_menu_screen.dart';
import 'kiosk_no_approved_home_screen.dart';
import '../models/moyak_api_models.dart';
import '../services/kiosk_backend.dart';
import '../services/service_result.dart';

/// In-memory UI examples only. These values are never authentication evidence.
enum HomePreviewState { signedOut, approvedMedicines, noApprovedMedicines }

/// Reuses existing homes; a paired machine session is not external identity proof.
class KioskHomeRouter extends StatefulWidget {
  const KioskHomeRouter({
    super.key,
    this.initialPreviewState = HomePreviewState.signedOut,
    this.liveSession,
  });

  final HomePreviewState initialPreviewState;
  final KioskSession? liveSession;

  @override
  State<KioskHomeRouter> createState() => _KioskHomeRouterState();
}

class _KioskHomeRouterState extends State<KioskHomeRouter>
    with WidgetsBindingObserver, RouteAware {
  KioskSession? _liveSession;
  KioskBackend? _backend;
  ModalRoute<void>? _route;
  bool _sessionBusy = false;
  int _sessionGeneration = 0;
  bool get _liveMode => widget.liveSession != null;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _backend = KioskBackendScope.maybeOf(context);
    final route = ModalRoute.of<void>(context);
    if (_route != route && route != null) {
      kioskRouteObserver.unsubscribe(this);
      _route = route;
      kioskRouteObserver.subscribe(this, route);
      if (_liveMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _refreshSession());
      }
    }
  }

  @override
  void didPopNext() {
    _refreshSession();
  }

  @override
  void didPushNext() {
    if (_liveMode) _backend?.invalidateSessionReads();
    _sessionGeneration++;
    _sessionBusy = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_liveMode) return;
    _sessionGeneration++;
    _sessionBusy = false;
    _backend?.invalidateSessionReads();
    if (state == AppLifecycleState.resumed && _route?.isCurrent == true) {
      _refreshSession();
    }
  }

  Future<void> _refreshSession() async {
    final backend = _backend;
    if (!mounted ||
        !_liveMode ||
        backend == null ||
        _sessionBusy ||
        _loggingOut ||
        _route?.isCurrent != true) {
      return;
    }
    _sessionBusy = true;
    final generation = _sessionGeneration;
    final result = await backend.querySession();
    ServiceResult<LiveApprovedKioskCart>? approvals;
    if (result is ServiceSuccess<KioskSession> && result.value.paired) {
      approvals = await backend.loadApprovedCart(verifiedSession: result.value);
    }
    if (!mounted || generation != _sessionGeneration) {
      if (approvals is ServiceSuccess<LiveApprovedKioskCart>) {
        approvals.value.dispose();
      }
      return;
    }
    _sessionBusy = false;
    setState(() {
      switch (result) {
        case ServiceSuccess<KioskSession>():
          _liveSession = result.value.paired ? result.value : null;
        case ServiceFailure<KioskSession>():
          _liveSession = null;
      }
      if (approvals is ServiceSuccess<LiveApprovedKioskCart>) {
        _approvedCart.dispose();
        _approvedCart = (approvals).value;
      } else if (approvals is ServiceFailure<LiveApprovedKioskCart>) {
        _liveSession =
            null; // Never display a stale or example approval as live.
      }
      _previewState = _liveSession == null
          ? HomePreviewState.signedOut
          : _approvedCart.quantities.isNotEmpty
          ? HomePreviewState.approvedMedicines
          : HomePreviewState.noApprovedMedicines;
    });
    if (result is ServiceFailure<KioskSession> ||
        approvals is ServiceFailure<LiveApprovedKioskCart>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('기기 연결 상태를 확인하지 못했습니다. 다시 확인하기 전 회원 정보를 표시하지 않습니다.'),
        ),
      );
    }
  }

  late HomePreviewState _previewState;
  late DemoCart _approvedCart;

  @override
  void initState() {
    super.initState();
    _liveSession = widget.liveSession;
    WidgetsBinding.instance.addObserver(this);
    _approvedCart = _liveMode
        ? DemoCart(
            products: const [],
            quantities: const {},
            approvedLimits: const {},
          )
        : createDemoApprovedCart();
    // Production stays signed out until real verified service data is available.
    _previewState = kDebugMode
        ? widget.initialPreviewState
        : HomePreviewState.signedOut;
    final session = _liveSession;
    if (session?.paired == true) {
      _previewState = session!.hasPendingPurchase
          ? HomePreviewState.approvedMedicines
          : HomePreviewState.noApprovedMedicines;
    }
  }

  Future<void> _selectPreviewState() async {
    if (!kDebugMode) return;
    final selected = await showDialog<HomePreviewState>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('개발용 홈 상태 선택 · 실제 인증 아님'),
        children: [
          for (final entry in const {
            HomePreviewState.signedOut: '비로그인 사용자',
            HomePreviewState.approvedMedicines: '인증 완료 예시 · 승인된 약 있음',
            HomePreviewState.noApprovedMedicines: '인증 완료 예시 · 승인된 약 없음',
          }.entries)
            SimpleDialogOption(
              key: ValueKey('home-preview-${entry.key.name}'),
              onPressed: () => Navigator.of(context).pop(entry.key),
              child: Text(entry.value),
            ),
        ],
      ),
    );
    if (mounted && selected != null) {
      if (selected == HomePreviewState.approvedMedicines &&
          _previewState != selected) {
        _approvedCart.dispose();
        _approvedCart = createDemoApprovedCart();
      }
      setState(() => _previewState = selected);
    }
  }

  void _logoutPreview() {
    if (_liveMode) {
      _logoutLive();
      return;
    }
    _approvedCart.clear();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('테스트용 로그아웃: 일반 홈으로 이동합니다. 실제 인증 세션 종료는 연결되지 않았습니다.'),
        ),
      );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const KioskHomeRouter()),
      (route) => route.isFirst,
    );
  }

  bool _loggingOut = false;
  Future<void> _logoutLive() async {
    if (_loggingOut) return;
    final backend = KioskBackendScope.maybeOf(context);
    if (backend == null) return;
    _sessionGeneration++;
    _loggingOut = true;
    // Backend invalidates paired user when rotating the machine QR.
    final result = await backend.rotateQr();
    if (!mounted) return;
    _loggingOut = false;
    if (result is ServiceFailure<KioskQr>) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error.message)));
      return;
    }
    backend.session = null;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const KioskHomeRouter()),
      (r) => r.isFirst,
    );
  }

  @override
  void dispose() {
    _sessionGeneration++;
    kioskRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _approvedCart.dispose();
    super.dispose();
  }

  bool _openingApprovals = false;
  Future<void> _openApprovedMedicines() async {
    if (_liveMode) {
      if (_openingApprovals || _sessionBusy || _loggingOut || _backend == null) {
        return;
      }
      _openingApprovals = true;
      final result = await _backend!.loadApprovedCart();
      _openingApprovals = false;
      if (!mounted) {
        if (result is ServiceSuccess<LiveApprovedKioskCart>) {
          result.value.dispose();
        }
        return;
      }
      if (result is ServiceFailure<LiveApprovedKioskCart>) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.error.message)));
        return;
      }
      final fresh = (result as ServiceSuccess<LiveApprovedKioskCart>).value;
      if (fresh.quantities.isEmpty) {
        fresh.dispose();
        await _refreshSession();
        return;
      }
      setState(() {
        _approvedCart.dispose();
        _approvedCart = fresh;
      });
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KioskCartScreen(
          cart: _approvedCart,
          showMember: true,
          onLogout: _logoutPreview,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = switch (_previewState) {
      HomePreviewState.signedOut => const KioskMenuScreen(),
      HomePreviewState.approvedMedicines => KioskLinkedHomeScreen(
        approvedCart: _approvedCart,
        onLogout: _logoutPreview,
        onApprovedMedicines: _openApprovedMedicines,
        memberName: _liveSession == null
            ? '지*민 님'
            : '${_liveSession!.displayName ?? '연동 회원'} 님',
        serverPurchaseName: _liveMode
            ? (_approvedCart.products.firstOrNull?.name ??
                  _liveSession?.purchase?['drug_item_name'] as String?)
            : null,
      ),
      HomePreviewState.noApprovedMedicines => KioskNoApprovedHomeScreen(
        onLogout: _logoutPreview,
        memberName: _liveSession == null
            ? '지*민 님'
            : '${_liveSession!.displayName ?? '연동 회원'} 님',
      ),
    };
    if (!kDebugMode || KioskBackendScope.maybeOf(context) != null) {
      return screen;
    }
    // Hidden developer gesture; no visible controls or production gesture.
    return GestureDetector(
      key: const ValueKey('home-preview-selector'),
      onLongPress: _selectPreviewState,
      child: screen,
    );
  }
}
