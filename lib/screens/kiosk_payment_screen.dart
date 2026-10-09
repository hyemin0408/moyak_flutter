import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../demo/demo_cart.dart';
import '../demo/demo_products.dart';

/// UI-only payment review; selecting a method never charges or authenticates.
class KioskPaymentScreen extends StatefulWidget {
  const KioskPaymentScreen({super.key, required this.cart});
  final DemoCart cart;

  @override
  State<KioskPaymentScreen> createState() => _KioskPaymentScreenState();
}

enum _PaymentMethod { card, mobile }

class _KioskPaymentScreenState extends State<KioskPaymentScreen> {
  static const _background = Color(0xFFFFFDE7);
  static const _plate = Color(0xFFFFF8E1);
  static const _border = Color(0xFFFFF3C4);
  static const _yellow = Color(0xFFFFD54F);
  static const _gold = Color(0xFF8B6914);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF475569);
  _PaymentMethod _method = _PaymentMethod.card;

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

  Widget _slot(
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

  BoxDecoration _panel({Color color = _plate, double radius = 24}) =>
      BoxDecoration(
        color: color,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      );

  void _message(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          MediaQuery.sizeOf(context).height * 0.2,
        ),
        content: Text(text),
      ),
    );

  Widget _button(
    String key,
    String text,
    VoidCallback action, {
    Color color = _yellow,
    Color textColor = _gold,
  }) => DecoratedBox(
    decoration: _panel(color: color, radius: 16),
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
            child: _text(text, 32, color: textColor, weight: FontWeight.w800),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    body: SafeArea(
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 1080,
            height: 1920,
            child: ListenableBuilder(
              listenable: widget.cart,
              builder: (_, _) {
                final lines = widget.cart.quantities.entries.toList();
                return Stack(
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
                      left: 64,
                      top: 53,
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
                      74,
                      57,
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
                      167,
                      51,
                      52,
                      34,
                      _text('모약', 28, weight: FontWeight.w800),
                    ),
                    _slot(
                      64,
                      99,
                      155,
                      48,
                      _text('결제 진행', 40, weight: FontWeight.w800),
                    ),
                    _slot(
                      236,
                      107,
                      480,
                      29,
                      _text('|  주문 정보를 확인하신 후 결제를 완료해주세요', 24, color: _muted),
                    ),
                    Positioned(
                      left: 905,
                      top: 77,
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
                    Positioned(
                      left: 891,
                      top: 224,
                      width: 170,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _plate,
                          border: Border.all(color: _yellow),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  color: _gold,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                _text(
                                  '지*민 님',
                                  26,
                                  color: _gold,
                                  weight: FontWeight.w700,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 50,
                      top: 334,
                      width: 972,
                      height: 554,
                      child: DecoratedBox(decoration: _panel()),
                    ),
                    _slot(
                      90,
                      372,
                      650,
                      48,
                      _text('1. 구매 약품 상세 내역', 34, weight: FontWeight.w900),
                    ),
                    _slot(
                      98,
                      452,
                      630,
                      31,
                      _text('약품명', 24, color: _muted, weight: FontWeight.w700),
                    ),
                    _slot(
                      772,
                      452,
                      70,
                      31,
                      _text('수량', 24, color: _muted, weight: FontWeight.w700),
                      alignment: Alignment.centerRight,
                    ),
                    _slot(
                      865,
                      452,
                      118,
                      31,
                      _text('금액', 24, color: _muted, weight: FontWeight.w700),
                      alignment: Alignment.centerRight,
                    ),
                    const Positioned(
                      left: 98,
                      top: 487,
                      width: 896,
                      height: 1,
                      child: ColoredBox(color: Color(0xFFE2E8F0)),
                    ),
                    Positioned(
                      left: 98,
                      top: 495,
                      width: 896,
                      height: 235,
                      child: lines.isEmpty
                          ? Center(
                              child: _text('장바구니가 비어 있습니다.', 26, color: _muted),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: lines.length,
                              itemBuilder: (_, index) {
                                final line = lines[index];
                                final product = demoProducts[line.key];
                                return SizedBox(
                                  key: ValueKey('payment-product-${line.key}'),
                                  height: 62,
                                  child: DecoratedBox(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: _text(
                                              product.name,
                                              28,
                                              weight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 94,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: _text(
                                              '${line.value}개',
                                              24,
                                              color: _muted,
                                              weight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        SizedBox(
                                          width: 150,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: _text(
                                              _money(
                                                product.price * line.value,
                                              ),
                                              28,
                                              weight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Positioned(
                      left: 92,
                      top: 770,
                      width: 896,
                      height: 78,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            _slot(
                              16,
                              22,
                              300,
                              34,
                              _text('최종 결제 금액', 28, weight: FontWeight.w800),
                            ),
                            _slot(
                              500,
                              12,
                              372,
                              54,
                              _text(
                                _money(widget.cart.totalWon),
                                44,
                                color: const Color(0xFF047857),
                                weight: FontWeight.w900,
                              ),
                              alignment: Alignment.centerRight,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 50,
                      top: 950,
                      width: 972,
                      height: 554,
                      child: DecoratedBox(decoration: _panel()),
                    ),
                    _slot(
                      90,
                      988,
                      650,
                      48,
                      _text('2. 결제 수단 선택', 34, weight: FontWeight.w900),
                    ),
                    _methodCard(_PaymentMethod.card, 1062, 158),
                    _methodCard(_PaymentMethod.mobile, 1256, 108),
                    Positioned(
                      left: 92,
                      top: 1378,
                      width: 432,
                      height: 98,
                      child: _button(
                        'payment-cancel',
                        '결제 취소',
                        () => Navigator.of(context).pop(),
                        color: _plate,
                        textColor: _muted,
                      ),
                    ),
                    Positioned(
                      left: 558,
                      top: 1378,
                      width: 432,
                      height: 98,
                      child: _button(
                        'payment-complete',
                        '기기에서 결제 완료하기',
                        () => _message(
                          lines.isEmpty
                              ? '장바구니가 비어 있습니다.'
                              : '테스트용 결제 화면입니다. 실제 결제·영수증 발급·약품 배출은 진행되지 않습니다.',
                        ),
                      ),
                    ),
                    Positioned(
                      left: 887,
                      top: 1700,
                      width: 170,
                      height: 44,
                      child: TextButton(
                        key: const ValueKey('payment-logout'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        onPressed: () =>
                            _message('실제 인증이 연결되지 않아 회원 로그아웃은 수행하지 않습니다.'),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '회원 로그아웃',
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              fontFamily: 'MenuInter',
                              fontFamilyFallback: const ['MenuKorean'],
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF4444),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
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
                      top: 1798,
                      width: 224,
                      height: 82,
                      child: _button(
                        'payment-back',
                        '← 이전으로',
                        () => Navigator.of(context).pop(),
                        color: _plate,
                        textColor: _ink,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );

  Widget _methodCard(_PaymentMethod method, double top, double height) {
    final selected = _method == method;
    final isCard = method == _PaymentMethod.card;
    return Positioned(
      left: 90,
      top: top,
      width: 896,
      height: height,
      child: Material(
        color: _plate,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? _yellow : _border,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey(
            isCard ? 'payment-method-card' : 'payment-method-mobile',
          ),
          onTap: () => setState(() => _method = method),
          child: Semantics(
            selected: selected,
            button: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected ? _yellow : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isCard ? Icons.credit_card : Icons.phone_android,
                      size: 38,
                      color: selected ? Colors.white : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: isCard ? 170 : 430,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _text(
                                isCard ? '신용/체크카드' : '삼성페이 / 모바일 페이',
                                28,
                                color: selected
                                    ? _gold
                                    : const Color(0xFF737373),
                                weight: FontWeight.w800,
                              ),
                              if (isCard)
                                _text(
                                  '결제',
                                  28,
                                  color: _gold,
                                  weight: FontWeight.w800,
                                ),
                            ],
                          ),
                        ),
                        if (isCard) ...[
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _text('투입구에 카드를 끝까지', 22, color: _gold),
                                _text('넣어주세요', 22, color: _gold),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (selected)
                    const Padding(
                      padding: EdgeInsets.only(left: 24),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: _gold,
                        size: 32,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
