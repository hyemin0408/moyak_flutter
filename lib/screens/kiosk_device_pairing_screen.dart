import '../widgets/kiosk_viewport.dart';

import 'dart:async';

import '../services/kiosk_backend.dart';
import '../services/service_result.dart';
import '../models/moyak_api_models.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'kiosk_auth_complete_screen.dart';
import 'kiosk_home_router.dart';

/// Existing layout, using configured machine QR APIs during normal app launch.
class KioskDevicePairingScreen extends StatefulWidget {
  const KioskDevicePairingScreen({super.key});

  @override
  State<KioskDevicePairingScreen> createState() =>
      _KioskDevicePairingScreenState();
}

class _KioskDevicePairingScreenState extends State<KioskDevicePairingScreen>
    with WidgetsBindingObserver {
  KioskBackend? _backend;
  KioskQr? _qr;
  Timer? _poll;
  Timer? _expiryTimer;
  bool _initialized = false, _fetching = false, _paired = false, _active = true;
  String? _error;
  int _generation = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _backend = KioskBackendScope.maybeOf(context);
    if (_backend != null) Future.microtask(_begin);
  }

  @override
  void dispose() {
    _generation++;
    _poll?.cancel();
    _expiryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _generation++;
    _poll?.cancel();
    _expiryTimer?.cancel();
    _fetching = false;
    _backend?.invalidateSessionReads();
    if (_active && !_paired && _backend != null) _begin();
  }

  Future<void> _begin() async {
    if (!mounted || !_active || _fetching || _paired) return;
    final backend = _backend!;
    setState(() {
      _fetching = true;
      _error = backend.mutationError;
    });
    if (_error != null) {
      setState(() => _fetching = false);
      return;
    }
    final generation = _generation;
    // Initial entry and app resume both inspect the existing session FIRST.
    final session = await backend.querySession();
    if (!mounted || !_active || generation != _generation) return;
    if (session is ServiceFailure<KioskSession>) {
      setState(() {
        _fetching = false;
        _error = session.error.message;
      });
      if (_qr != null && DateTime.now().toUtc().isBefore(_qr!.expiresAt)) {
        _armExpiry();
        _schedule();
      }
      return; // Unknown session must never trigger a reset/rotation.
    }
    final value = (session as ServiceSuccess<KioskSession>).value;
    if (value.paired) {
      _finishPairing(value);
      return;
    }
    if (_qr != null && DateTime.now().toUtc().isBefore(_qr!.expiresAt)) {
      setState(() {
        _fetching = false;
        _error = null;
      });
      _armExpiry();
      _schedule();
      return;
    }
    setState(() => _qr = null);
    final result = await backend.rotateQr();
    if (!mounted || !_active || generation != _generation) return;
    setState(() {
      _fetching = false;
      switch (result) {
        case ServiceSuccess<KioskQr>():
          if (result.value.machineId != backend.machineId ||
              !DateTime.now().toUtc().isBefore(result.value.expiresAt)) {
            _error = '기기 QR 응답을 확인할 수 없습니다.';
          } else {
            _qr = result.value;
            _error = null;
          }
        case ServiceFailure<KioskQr>():
          _error = result.error.message;
      }
    });
    if (_qr != null) {
      _armExpiry();
      _schedule();
    }
  }

  void _finishPairing(KioskSession session) {
    if (!mounted || !_active || _paired) return;
    _paired = true;
    _fetching = false;
    _generation++;
    _poll?.cancel();
    _expiryTimer?.cancel();
    _backend!.session = session;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (completionContext) => KioskAuthCompleteScreen(
          deviceLinkOnly: true,
          memberName: session.displayName ?? '연동 회원',
          onPreviewContinue: () =>
              Navigator.of(completionContext).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => KioskHomeRouter(liveSession: session),
                ),
                (r) => r.isFirst,
              ),
        ),
      ),
    );
  }

  void _armExpiry() {
    _expiryTimer?.cancel();
    if (_qr == null) return;
    _expiryTimer = Timer(_qr!.expiresAt.difference(DateTime.now().toUtc()), () {
      if (!mounted || _paired) return;
      _generation++;
      _poll?.cancel();
      setState(() {
        _qr = null;
        _fetching = false;
        _error = 'QR 유효 시간이 지났습니다. 이전으로 돌아가 다시 시도해 주세요.';
      });
    });
  }

  void _schedule() {
    _poll?.cancel();
    _poll = Timer(const Duration(seconds: 3), _checkSession);
  }

  Future<void> _checkSession() async {
    if (!mounted || !_active || _paired || _fetching || _qr == null) return;
    if (!DateTime.now().toUtc().isBefore(_qr!.expiresAt)) {
      setState(() {
        _qr = null;
        _error = 'QR 유효 시간이 지났습니다. 이전으로 돌아가 다시 시도해 주세요.';
      });
      return;
    }
    _fetching = true;
    final generation = _generation;
    final result = await _backend!.querySession();
    if (!mounted || generation != _generation) return;
    setState(() {
      _fetching = false;
      switch (result) {
        case ServiceSuccess<KioskSession>():
          if (result.value.machineId != _backend!.machineId) {
            _error = '기기 세션이 일치하지 않습니다.';
            return;
          }
          _error = null;

        case ServiceFailure<KioskSession>():
          _error = result.error.message;
      }
      if (!DateTime.now().toUtc().isBefore(_qr!.expiresAt) && !_paired) {
        _qr = null;
        _error = 'QR 유효 시간이 지났습니다.';
      }
    });
    if (result is ServiceSuccess<KioskSession> && result.value.paired) {
      _finishPairing(result.value);
      return;
    }
    if (!_paired && _qr != null) _schedule();
  }

  Widget _liveQr() => Container(
    color: Colors.white,
    padding: const EdgeInsets.all(12),
    child: _qr != null && !_paired
        ? SvgPicture.string(_qr!.svg, semanticsLabel: '기기 연동 QR')
        : Center(
            child: Text(
              _paired
                  ? '기기 연동이 확인되었습니다.\n본인인증 및 승인 약 구매 연결은 준비 중입니다.'
                  : _error ?? '기기 QR을 발급하는 중입니다…',
              textAlign: TextAlign.center,
              style: _style(20),
            ),
          ),
  );

  // Debug-only navigation preview; never creates a verified session.
  Widget _completionPreview(BuildContext context, Widget child) {
    if (_backend != null) return _liveQr();
    if (!kDebugMode) return child;
    return Tooltip(
      message: '테스트용: 본인인증 완료 화면 미리보기 (실제 인증 아님)',
      child: GestureDetector(
        key: const ValueKey('pairing-preview-complete'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (completionContext) => KioskAuthCompleteScreen(
              onPreviewContinue: () => Navigator.of(completionContext).push(
                MaterialPageRoute<void>(
                  builder: (_) => const KioskHomeRouter(
                    initialPreviewState: HomePreviewState.approvedMedicines,
                  ),
                ),
              ),
            ),
          ),
        ),
        child: child,
      ),
    );
  }

  static const _background = Color(0xFFFFFDE7);
  static const _plate = Color(0xFFFFF8E1);
  static const _border = Color(0xFFFFF3C4);
  static const _yellow = Color(0xFFFFD54F);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF475569);
  static const _gold = Color(0xFF8B6914);

  static TextStyle _style(
    double size, {
    Color color = _ink,
    FontWeight weight = FontWeight.w500,
  }) => TextStyle(
    fontFamily: 'MenuInter',
    fontFamilyFallback: const ['MenuKorean'],
    fontSize: kioskFontSize(size),
    fontWeight: weight,
    color: color,
    height: 1.2,
  );

  static Widget _text(
    String text,
    double size, {
    Color color = _ink,
    FontWeight weight = FontWeight.w500,
  }) => Text(
    text,
    style: _style(size, color: color, weight: weight),
    maxLines: 1,
    softWrap: false,
  );

  static Widget _slot(
    double x,
    double y,
    double width,
    double height,
    Widget child, {
    Alignment alignment = Alignment.centerLeft,
  }) => Positioned(
    left: x,
    top: y,
    width: width,
    height: height,
    child: FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    body: SafeArea(
      child: KioskViewport(
        child: KioskCanvas(
          children: [
            const Positioned.fill(child: ColoredBox(color: _background)),
            Positioned(
              left: 0,
              top: 0,
              width: 1080,
              height: 204,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: _border)),
                ),
              ),
            ),
            Positioned(
              left: 58,
              top: 58,
              width: 91,
              height: 30,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _yellow,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            _slot(
              68,
              62,
              71,
              22,
              _text(
                '모두의 약',
                18,
                color: const Color(0xFF593D0D),
                weight: FontWeight.w800,
              ),
            ),
            _slot(161, 55, 52, 34, _text('모약', 28, weight: FontWeight.w800)),
            _slot(
              58,
              105,
              238,
              48,
              _text('기기 고유 연동', 40, weight: FontWeight.w800),
            ),
            _slot(
              313,
              114,
              532,
              29,
              _text('|  이 자판기와 본인의 스마트폰 앱을 직접 연결합니다', 24, color: _muted),
            ),
            Positioned(
              left: 910,
              top: 70,
              width: 133,
              height: 51,
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: _border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: const ValueKey('pairing-language'),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('언어 변경은 추후 연결 예정입니다.')),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _text(
                            '한국어',
                            22,
                            color: _muted,
                            weight: FontWeight.w600,
                          ),
                          const SizedBox(width: 12),
                          SvgPicture.asset(
                            'assets/menu/chevron.svg',
                            width: 16,
                            height: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _slot(
              140,
              582,
              800,
              48,
              _text('앱에서 기기 QR을 스캔해주세요', 40, weight: FontWeight.w900),
              alignment: Alignment.center,
            ),
            _slot(
              160,
              643,
              760,
              32,
              _text(
                "스마트폰 앱 내의 '기기 연동' 메뉴를 눌러 아래 QR을 스캔하세요.",
                26,
                color: _muted,
              ),
              alignment: Alignment.center,
            ),
            Positioned(
              left: 316,
              top: 718,
              width: 448,
              height: 460,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _yellow, width: 4),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x148B6914),
                      offset: Offset(0, 16),
                      blurRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 380,
              top: 756,
              width: 320,
              height: 320,
              child: _completionPreview(
                context,
                Semantics(
                  label: _backend == null
                      ? '임시 QR 모양, 실제 스캔 및 연동 불가'
                      : '서버 기기 연동 QR 영역',
                  child: ColoredBox(
                    color: const Color(0xFF7D8793),
                    child: Center(
                      child: Container(
                        width: 226,
                        height: 226,
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const ExcludeSemantics(
                              child: Icon(
                                Icons.qr_code_2,
                                size: 174,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              '임시 QR · 실제 연동 불가',
                              style: _style(14, color: _muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 354,
              top: 1100,
              width: 372,
              height: 40,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _plate,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _text(
                      _backend == null
                          ? '자판기 고유인증 키: MD-2409-ROME'
                          : '기기 ID: ${_backend!.machineId.isEmpty ? '미설정' : _backend!.machineId}',
                      20,
                      color: _gold,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 356,
              top: 1228,
              width: 368,
              height: 76,
              child: Semantics(
                label: _backend == null
                    ? '스마트폰 연동 대기 표시, 디자인 예시이며 실제 연결하지 않음'
                    : '서버 기기 연동 상태',
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _plate,
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              value: 0.75,
                              strokeWidth: 4,
                              color: _yellow,
                            ),
                          ),
                          const SizedBox(width: 24),
                          _text(
                            _backend == null
                                ? '스마트폰 연동 대기 중...'
                                : _paired
                                ? '기기 연동 확인됨'
                                : _error != null
                                ? '기기 연동을 확인해 주세요'
                                : '스마트폰 연동 대기 중...',
                            24,
                            color: _gold,
                            weight: FontWeight.w700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 180,
              top: 1354,
              width: 720,
              height: 66,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _text(
                      '스마트폰 연동 시, 구매 이력과 처방전 연동 등이 완벽히 동기화되어',
                      26,
                      color: const Color(0xFF94A3B8),
                    ),
                    _text(
                      '안전한 약품 복용 지도가 가능해집니다.',
                      26,
                      color: const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 1758,
              width: 1080,
              height: 162,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: _border)),
                ),
              ),
            ),
            Positioned(
              left: 64,
              top: 1798,
              width: 224,
              height: 82,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      offset: Offset(0, 4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Material(
                  color: _plate,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: _border, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const ValueKey('pairing-back'),
                    onTap: () => Navigator.of(context).pop(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/products/back.svg',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 16),
                        _text('이전으로', 28, weight: FontWeight.w700),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
