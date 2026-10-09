import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class KioskUsageGuideScreen extends StatelessWidget {
  const KioskUsageGuideScreen({super.key});

  static const _background = Color(0xFFFFFDE7);
  static const _plate = Color(0xFFFFF8E1);
  static const _border = Color(0xFFFFF3C4);
  static const _yellow = Color(0xFFFFD54F);
  static const _brown = Color(0xFF593D0D);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF475569);
  static const _steps = [
    ('구매 방법을 선택해 주세요', '의약외품 즉시 구매 또는 본인인증 필요 약품 구매를 선택합니다.'),
    ('원하는 약품을 찾아주세요', '검색하거나 카테고리를 선택해 원하는 약품을 확인합니다.'),
    ('약품을 장바구니에 담아주세요', '구매할 약품과 수량을 확인한 후 장바구니에 담습니다.'),
    ('결제 방법을 선택해 주세요', '장바구니에서 구매할 약품을 확인하고 원하는 결제 방법을 선택합니다.'),
    ('약품을 수령해 주세요', '결제가 완료되면 화면의 안내에 따라 자판기에서 약품을 수령합니다.'),
  ];

  static Widget _text(
    String text,
    double size, {
    Color color = _ink,
    FontWeight weight = FontWeight.w500,
  }) => Text(
    text,
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
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 1080,
            height: 1920,
            child: Stack(
              children: [
                const Positioned.fill(child: ColoredBox(color: _background)),
                const Positioned(
                  left: 0,
                  top: 0,
                  width: 1080,
                  height: 204,
                  child: ColoredBox(color: Colors.white),
                ),
                Positioned(
                  left: 64,
                  top: 59,
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
                  63,
                  71,
                  22,
                  _text('모두의 약', 18, color: _brown, weight: FontWeight.w800),
                ),
                _slot(
                  167,
                  57,
                  52,
                  34,
                  _text('모약', 28, weight: FontWeight.w800),
                ),
                _slot(
                  64,
                  101,
                  402,
                  48,
                  _text('앱 다운로드 및 사용 방법', 40, weight: FontWeight.w800),
                ),
                _slot(
                  484,
                  111,
                  376,
                  29,
                  _text('|  원하시는 구매 방법을 선택해 주세요', 24, color: _muted),
                ),
                Positioned(
                  left: 922,
                  top: 81,
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
                  140,
                  282,
                  800,
                  72,
                  _text('사용 방법', 56, color: _brown, weight: FontWeight.w900),
                  alignment: Alignment.center,
                ),
                _slot(
                  140,
                  374,
                  800,
                  36,
                  _text('모약 키오스크에서 간편하게 약품을 구매해 보세요.', 26, color: _muted),
                  alignment: Alignment.center,
                ),
                for (var index = 0; index < _steps.length; index++)
                  _step(index),
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
                        key: const ValueKey('usage-back'),
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
      ),
    ),
  );

  Widget _step(int index) => Positioned(
    left: 64,
    top: [485.0, 693.0, 901.0, 1116.0, 1336.0][index],
    width: 952,
    height: 176,
    child: DecoratedBox(
      key: ValueKey('usage-step-${index + 1}'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x148B6914),
            offset: Offset(0, 10),
            blurRadius: 50,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 40,
            top: 56,
            width: 64,
            height: 64,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: _yellow,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    offset: Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: _text('${index + 1}', 24, color: Colors.black),
              ),
            ),
          ),
          _slot(
            144,
            46,
            768,
            39,
            _text(_steps[index].$1, 32, weight: FontWeight.w900),
          ),
          _slot(144, 98, 768, 32, _text(_steps[index].$2, 21, color: _muted)),
        ],
      ),
    ),
  );
}
