import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../demo/demo_cart.dart';
import '../demo/demo_products.dart';
import 'kiosk_product_list_screen.dart';
import 'kiosk_payment_screen.dart';

class KioskCartScreen extends StatefulWidget {
  const KioskCartScreen({super.key, required this.cart, this.onAddProducts});
  final DemoCart cart;
  final VoidCallback? onAddProducts;

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
    _restartIdleTimer();
    setState(() {});
  }

  Future<void> _openPayment() async {
    if (widget.cart.quantities.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('장바구니가 비어 있습니다.')));
      return;
    }
    _idleTimer?.cancel();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KioskPaymentScreen(cart: widget.cart),
      ),
    );
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
    VoidCallback action, {
    Color color = _yellow,
  }) => DecoratedBox(
    decoration: _card(color: color, radius: 16),
    child: Material(
      color: color,
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
    return Scaffold(
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
                    _slot(
                      64,
                      244,
                      222,
                      44,
                      _text('담은 약품 리스트', 32, weight: FontWeight.w800),
                    ),
                    Positioned(
                      left: 300,
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
                    Positioned(
                      left: 64,
                      top: 315,
                      width: 952,
                      height: 1060,
                      child: lines.isEmpty
                          ? Center(
                              child: _text('장바구니가 비어 있습니다.', 32, color: _gold),
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
                              _text('최종 결제 금액', 28, weight: FontWeight.w800),
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
                                    _money(widget.cart.totalWon),
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
                              builder: (_) =>
                                  KioskProductListScreen(cart: widget.cart),
                            ),
                          );
                          if (mounted) _restartIdleTimer();
                        },
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      left: 552,
                      top: 1638,
                      width: 464,
                      height: 80,
                      child: _button(
                        'cart-checkout',
                        '선택완료 및 결제하기',
                        _openPayment,
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
                      child: _button('cart-home', '← 첫 화면으로', () {
                        widget.cart.clear();
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      }, color: _plate),
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
    );
  }

  Widget _product(int index, int quantity) {
    final product = demoProducts[index];
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
                child: Image.asset(
                  'assets/products/${product.image}',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              left: 148,
              top: 44,
              child: DecoratedBox(
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
                child: Center(
                  child: _text(
                    '$quantity',
                    28,
                    color: const Color(0xFF593D0D),
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            _slot(
              728,
              54,
              150,
              40,
              _text(
                _money(product.price),
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
}
