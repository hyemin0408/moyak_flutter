import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../demo/demo_cart.dart';
import 'kiosk_product_list_screen.dart';
import 'kiosk_payment_screen.dart';
import '../services/kiosk_backend.dart';
import '../models/moyak_api_models.dart';
import '../services/service_result.dart';

class KioskCartScreen extends StatefulWidget {
  const KioskCartScreen({
    super.key,
    required this.cart,
    this.onAddProducts,
    this.onLogout,
    this.showMember = false,
  });
  final DemoCart cart;
  final VoidCallback? onAddProducts;
  final VoidCallback? onLogout;

  /// Example member visibility is independent of medicine approval restrictions.
  final bool showMember;

  @override
  State<KioskCartScreen> createState() => _KioskCartScreenState();
}

class _KioskCartScreenState extends State<KioskCartScreen> {
  static const _background = Color(0xFFFFFDE7);
  static const _plate = Color(0xFFFFF8E1);
  static const _yellow = Color(0xFFFFD54F);
  static const _border = Color(0xFFFFF3C4);
  static const _gold = Color(0xFF8B6914);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF475569);
  Timer? _idleTimer;
  bool _paymentOpen = false;
  KioskBackend? get _liveBackend => switch (widget.cart) {
    LiveKioskCart cart => cart.backend,
    LiveApprovedKioskCart cart => cart.backend,
    _ => null,
  };

  @override
  void initState() {
    super.initState();
    widget.cart.addListener(_cartChanged);
    _restartIdleTimer();
  }

  void _restartIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(minutes: 10), widget.cart.clear);
  }

  void _cartChanged() {
    if (!_paymentOpen) _restartIdleTimer();
    setState(() {});
  }

  Future<void> _firstScreen() async {
    final backend = _liveBackend;
    if (backend != null && backend.session != null) {
      final result = await backend.rotateQr();
      if (!mounted) return;
      if (result is ServiceFailure<KioskQr>) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.error.message)));
        return;
      }
      backend.session = null;
    }
    widget.cart.clear();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openPayment() async {
    final live = widget.cart is LiveKioskCart
        ? widget.cart as LiveKioskCart
        : null;
    if (live?.busy == true || _paymentOpen) return;
    if (widget.cart.quantities.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('장바구니가 비어 있습니다.')));
      return;
    }
    _idleTimer?.cancel();
    _paymentOpen = true;
    if (widget.cart case LiveApprovedKioskCart approved) {
      final error = await approved.validateSelection();
      if (!mounted) return;
      if (error != null) {
        _paymentOpen = false;
        _restartIdleTimer();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
        return;
      }
    }
    if (live != null) {
      final ok = await live.createOrder();
      if (!mounted) return;
      if (!ok) {
        _paymentOpen = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(live.error ?? '주문을 생성하지 못했습니다.')),
        );
        _restartIdleTimer();
        return;
      }
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KioskPaymentScreen(
          cart: widget.cart,
          onLogout: widget.onLogout,
          showMember: widget.showMember,
        ),
      ),
    );
    if (live != null && live.order == null && !live.uncertain && mounted) {
      await live.load();
    }
    _paymentOpen = false;
    if (mounted) _restartIdleTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    widget.cart.removeListener(_cartChanged);
    super.dispose();
  }

  String _money(int value) =>
      '${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}원';

  Widget _text(
    String value,
    double size, {
    Color color = _ink,
    FontWeight weight = FontWeight.w500,
  }) => Text(
    value,
    maxLines: 1,
    softWrap: false,
    style: TextStyle(
      fontFamily: 'MenuInter',
      fontFamilyFallback: const ['MenuKorean'],
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.2,
    ),
  );

  Widget _slot(double x, double y, double width, double height, Widget child) =>
      Positioned(
        left: x,
        top: y,
        width: width,
        height: height,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: child,
        ),
      );

  BoxDecoration _card({Color color = Colors.white, double radius = 20}) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            offset: Offset(0, 6),
            blurRadius: 10,
          ),
        ],
      );

  Widget _button(
    String key,
    String text,
    VoidCallback? action, {
    Color color = _yellow,
  }) => DecoratedBox(
    decoration: _card(color: color, radius: 16),
    child: Material(
      color: action == null ? Colors.grey.shade200 : color,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey(key),
        onTap: action,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: _text(text, 28, color: _gold, weight: FontWeight.w800),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final lines = widget.cart.quantities.entries.toList();
    final live = widget.cart is LiveKioskCart
        ? widget.cart as LiveKioskCart
        : null;
    return PopScope(
      canPop:
          live == null || (!live.busy && live.order == null && !live.uncertain),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && live != null && !live.busy) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(live.error ?? '미확인 주문이 있습니다. 직원에게 문의해 주세요.'),
            ),
          );
        }
      },
      child: AbsorbPointer(
        absorbing: live?.busy ?? false,
        child: Scaffold(
          backgroundColor: _background,
          body: SafeArea(
            child: Listener(
              onPointerDown: (_) => _restartIdleTimer(),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 1080,
                    height: 1920,
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: ColoredBox(color: _background),
                        ),
                        const Positioned(
                          left: 0,
                          top: 0,
                          width: 1080,
                          height: 204,
                          child: ColoredBox(color: Colors.white),
                        ),
                        Positioned(
                          left: 60,
                          top: 52,
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
                          70,
                          56,
                          71,
                          22,
                          _text(
                            '모두의 약',
                            18,
                            color: const Color(0xFF593D0D),
                            weight: FontWeight.w800,
                          ),
                        ),
                        _slot(
                          163,
                          50,
                          52,
                          34,
                          _text('모약', 28, weight: FontWeight.w800),
                        ),
                        _slot(
                          60,
                          94,
                          150,
                          48,
                          _text('장바구니', 40, weight: FontWeight.w800),
                        ),
                        _slot(
                          225,
                          103,
                          390,
                          29,
                          _text('|  담으신 약품 내역을 확인해 주세요', 24, color: _muted),
                        ),
                        Positioned(
                          left: 917,
                          top: 79,
                          width: 133,
                          height: 51,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: _border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
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
                        _slot(
                          64,
                          244,
                          222,
                          44,
                          _text(
                            widget.cart.isApprovalRestricted
                                ? '승인된 약 확인'
                                : '담은 약품 리스트',
                            32,
                            weight: FontWeight.w800,
                          ),
                        ),
                        Positioned(
                          left: widget.cart.isApprovalRestricted ? 488 : 300,
                          top: 247,
                          width: 146,
                          height: 34,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _gold,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _text(
                                  '${lines.length}종류 (총 ${widget.cart.totalQuantity}개)',
                                  20,
                                  color: Colors.white,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (widget.cart.isApprovalRestricted) ...[
                          _slot(
                            266,
                            253,
                            210,
                            28,
                            _text('개발용 승인 약품 예시', 20, color: _muted),
                          ),
                          _slot(
                            334,
                            680,
                            450,
                            40,
                            _text('승인받은 수량만 구매할 수 있어요', 28, color: _muted),
                          ),
                        ],
                        if (widget.showMember)
                          Positioned(
                            left: 895,
                            top: 236,
                            width: 170,
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: _plate,
                                border: Border.all(color: _yellow),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.person_outline,
                                        color: _gold,
                                        size: 26,
                                      ),
                                      const SizedBox(width: 8),
                                      _text(
                                        _liveBackend?.memberLabel ?? '지*민 님',
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
                        if (widget.showMember)
                          Positioned(
                            left: 927,
                            top: widget.cart.isApprovalRestricted ? 1700 : 1724,
                            width: 130,
                            height: widget.cart.isApprovalRestricted ? 44 : 30,
                            child: TextButton(
                              key: const ValueKey('cart-logout'),
                              onPressed: () {
                                widget.cart.clear();
                                if (widget.onLogout != null) {
                                  widget.onLogout!();
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '테스트용 장바구니를 비웠습니다. 실제 인증 세션 종료는 연결되지 않았습니다.',
                                    ),
                                  ),
                                );
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              },
                              child: const FittedBox(
                                child: Text(
                                  '회원 로그아웃',
                                  style: TextStyle(
                                    color: Color(0xFFFF4444),
                                    fontSize: 22,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        Positioned(
                          left: 64,
                          top: 315,
                          width: 952,
                          height: widget.cart.isApprovalRestricted ? 340 : 1060,
                          child: lines.isEmpty
                              ? Center(
                                  child: _text(
                                    '장바구니가 비어 있습니다.',
                                    32,
                                    color: _gold,
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  itemCount: lines.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (_, index) => _product(
                                    lines[index].key,
                                    lines[index].value,
                                  ),
                                ),
                        ),
                        Positioned(
                          left: 64,
                          top: 1465,
                          width: 952,
                          height: 120,
                          child: DecoratedBox(
                            decoration: _card(),
                            child: Stack(
                              children: [
                                _slot(
                                  32,
                                  42,
                                  400,
                                  40,
                                  _text(
                                    '최종 결제 금액',
                                    28,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                                Positioned(
                                  left: 500,
                                  right: 32,
                                  top: 32,
                                  height: 58,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: _text(
                                        widget.cart is LiveApprovedKioskCart &&
                                                (widget.cart
                                                        as LiveApprovedKioskCart)
                                                    .hasUnknownPrice
                                            ? '가격 확인 필요'
                                            : _money(widget.cart.totalWon),
                                        44,
                                        color: _gold,
                                        weight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!widget.cart.isApprovalRestricted)
                          Positioned(
                            left: 64,
                            top: 1638,
                            width: 465,
                            height: 80,
                            child: _button(
                              'cart-add-products',
                              '← 의약외품 추가하기',
                              () async {
                                if (widget.onAddProducts != null) {
                                  widget.onAddProducts!();
                                  return;
                                }
                                _idleTimer?.cancel();
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => KioskProductListScreen(
                                      cart: widget.cart,
                                      showMember: widget.showMember,
                                      onLogout: widget.onLogout,
                                    ),
                                  ),
                                );
                                if (mounted) _restartIdleTimer();
                              },
                              color: Colors.white,
                            ),
                          ),
                        Positioned(
                          left: widget.cart.isApprovalRestricted ? 310 : 552,
                          top: 1638,
                          width: 464,
                          height: 80,
                          child: _button(
                            'cart-checkout',
                            live?.busy == true ? '주문 처리 중…' : '선택완료 및 결제하기',
                            lines.isEmpty ? null : _openPayment,
                          ),
                        ),
                        const Positioned(
                          left: 0,
                          top: 1758,
                          width: 1080,
                          height: 162,
                          child: ColoredBox(color: Colors.white),
                        ),
                        Positioned(
                          left: 64,
                          top: 1805,
                          width: 218,
                          height: 70,
                          child: _button(
                            'cart-home',
                            '← 첫 화면으로',
                            _firstScreen,
                            color: _plate,
                          ),
                        ),
                        _slot(
                          302,
                          1819,
                          714,
                          36,
                          _text(
                            '* 장바구니에 담긴 약품은 미선택 및 미결제 시 10분 후 자동 삭제되어 안전 정리됩니다.',
                            20,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _product(int index, int quantity) {
    final product = widget.cart.products[index];
    return SizedBox(
      height: 148,
      child: DecoratedBox(
        key: ValueKey('cart-product-$index'),
        decoration: _card(radius: 16),
        child: Stack(
          children: [
            Positioned(
              left: 24,
              top: 24,
              width: 100,
              height: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.image.isEmpty
                    ? ColoredBox(
                        color: _plate,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.medication_outlined,
                                color: _gold,
                                size: 36,
                              ),
                              _text('이미지 준비 중', 12, color: _muted),
                            ],
                          ),
                        ),
                      )
                    : Image.asset(
                        'assets/products/${product.image}',
                        fit: BoxFit.contain,
                      ),
              ),
            ),
            Positioned(
              left: 148,
              top: 44,
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _plate,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      child: _text(
                        product.badge,
                        16,
                        color: _gold,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (widget.cart.isApprovalRestricted) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _text(
                        '승인 완료 · 예시',
                        14,
                        color: const Color(0xFF10B981),
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _slot(
              148,
              76,
              342,
              34,
              _text(product.name, 28, weight: FontWeight.w800),
            ),
            Positioned(
              left: 504,
              top: 48,
              width: 144,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _plate,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!widget.cart.isApprovalRestricted)
                      _quantityButton(index, quantity, -1),
                    Expanded(
                      child: Center(
                        child: _text(
                          '$quantity',
                          28,
                          color: const Color(0xFF593D0D),
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!widget.cart.isApprovalRestricted)
                      _quantityButton(index, quantity, 1),
                  ],
                ),
              ),
            ),
            _slot(
              728,
              54,
              150,
              40,
              _text(
                widget.cart is LiveApprovedKioskCart &&
                        (widget.cart as LiveApprovedKioskCart)
                                .approvals[index]
                                .price ==
                            null
                    ? '가격 확인 필요'
                    : _money(product.price),
                32,
                color: _gold,
                weight: FontWeight.w800,
              ),
            ),
            Positioned(
              left: 884,
              top: 52,
              width: 44,
              height: 44,
              child: Material(
                color: _plate,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: ValueKey('cart-remove-$index'),
                  onTap: () => widget.cart.remove(index),
                  child: Semantics(
                    button: true,
                    label: '${product.name} 삭제',
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: Color(0xFFFF4444),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantityButton(int index, int quantity, int delta) {
    final next = quantity + delta;
    final limit =
        widget.cart.approvedLimits?[index] ?? widget.cart.products[index].stock;
    final live = widget.cart is LiveKioskCart
        ? widget.cart as LiveKioskCart
        : null;
    final enabled =
        next >= 1 &&
        (limit == null || next <= limit) &&
        (live == null || (!live.busy && !live.uncertain && live.order == null));
    return SizedBox(
      width: 36,
      height: 52,
      child: IconButton(
        key: ValueKey('cart-${delta < 0 ? 'decrease' : 'increase'}-$index'),
        tooltip: delta < 0 ? '수량 줄이기' : '수량 늘리기',
        padding: EdgeInsets.zero,
        onPressed: enabled ? () => widget.cart.setQuantity(index, next) : null,
        icon: Icon(
          delta < 0 ? Icons.remove : Icons.add,
          size: 22,
          color: enabled ? _gold : Colors.grey,
        ),
      ),
    );
  }
}
