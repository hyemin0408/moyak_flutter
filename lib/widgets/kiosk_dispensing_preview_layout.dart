import 'kiosk_viewport.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Shared frame for developer-only dispensing previews, never device results.
class KioskDispensingPreviewLayout extends StatelessWidget {
  const KioskDispensingPreviewLayout({
    super.key,
    required this.children,
    this.showMember = false,
    this.onLogout,
  });

  final List<Widget> children;
  final bool showMember;
  final VoidCallback? onLogout;
  static const background = Color(0xFFFFFDE7);
  static const yellow = Color(0xFFFFD54F);
  static const brown = Color(0xFF593D0D);
  static const muted = Color(0xFF475569);
  static const plate = Color(0xFFFFF8E1);

  static Widget text(
    String value,
    double size, {
    Color color = brown,
    FontWeight weight = FontWeight.w600,
  }) => Text(
    value,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontFamily: 'MenuInter',
      fontFamilyFallback: const ['MenuKorean'],
      fontSize: kioskFontSize(size),
      fontWeight: weight,
      color: color,
      height: 1.35,
    ),
  );

  static Widget slot(
    double x,
    double y,
    double width,
    double height,
    Widget child,
  ) => Positioned(
    left: x,
    top: y,
    width: width,
    height: height,
    child: FittedBox(fit: BoxFit.scaleDown, child: child),
  );

  static BoxDecoration panel({Color color = plate}) => BoxDecoration(
    color: color,
    border: Border.all(color: yellow),
    borderRadius: BorderRadius.circular(24),
    boxShadow: const [
      BoxShadow(color: Color(0x148B6914), offset: Offset(0, 8), blurRadius: 28),
    ],
  );

  static Widget button(String key, String label, VoidCallback action) =>
      Material(
        color: yellow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey(key),
          onTap: action,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: text(label, 28, weight: FontWeight.w800),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // No production success screen can be reached through a preview constructor.
    if (!kDebugMode) {
      return const Scaffold(body: Center(child: Text('개발용 미리보기는 사용할 수 없습니다.')));
    }
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: KioskViewport(
          child: KioskCanvas(
            children: [
              const Positioned.fill(child: ColoredBox(color: background)),
              const Positioned(
                left: 0,
                top: 0,
                width: 1080,
                height: 204,
                child: ColoredBox(color: Colors.white),
              ),
              Positioned(
                left: 64,
                top: 56,
                width: 91,
                height: 30,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: yellow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              slot(70, 57, 80, 28, text('모두의 약', 18, weight: FontWeight.w800)),
              slot(
                163,
                51,
                60,
                38,
                text(
                  '모약',
                  28,
                  color: const Color(0xFF0F172A),
                  weight: FontWeight.w800,
                ),
              ),
              slot(
                64,
                100,
                292,
                52,
                text(
                  '약품 배출 및 완료',
                  40,
                  color: const Color(0xFF0F172A),
                  weight: FontWeight.w800,
                ),
              ),
              slot(
                370,
                109,
                440,
                34,
                text('|  약품 수령 안내 화면 미리보기', 24, color: muted),
              ),
              Positioned(
                left: 922,
                top: 62,
                width: 132,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFFFF3C4)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      text('한국어', 22, color: muted),
                      const SizedBox(width: 10),
                      SvgPicture.asset(
                        'assets/menu/chevron.svg',
                        width: 16,
                        height: 16,
                      ),
                    ],
                  ),
                ),
              ),
              slot(
                180,
                298,
                720,
                40,
                text(
                  '개발용 미리보기 · 실제 결제 및 약 배출 없음',
                  24,
                  color: const Color(0xFFFF4444),
                  weight: FontWeight.w800,
                ),
              ),
              if (showMember)
                Positioned(
                  left: 875,
                  top: 225,
                  width: 190,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      color: plate,
                      border: Border.all(color: yellow),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: brown,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        text('지*민 님', 24),
                      ],
                    ),
                  ),
                ),
              ...children,
              if (showMember && onLogout != null)
                Positioned(
                  left: 895,
                  top: 1700,
                  width: 170,
                  height: 48,
                  child: TextButton(
                    key: const ValueKey('dispensing-logout'),
                    onPressed: onLogout,
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
              const Positioned(
                left: 0,
                top: 1758,
                width: 1080,
                height: 162,
                child: ColoredBox(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
