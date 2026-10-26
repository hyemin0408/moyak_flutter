import '../widgets/kiosk_viewport.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'kiosk_product_list_screen.dart';
import 'kiosk_qr_download_screen.dart';
import 'kiosk_usage_guide_screen.dart';

/// Figma kiosk-main-home (91:30), on a proportionally scaled 1080x1920 canvas.
class KioskMenuScreen extends StatelessWidget {
  const KioskMenuScreen({super.key, this.onSelect});

  final ValueChanged<int>? onSelect;
  static const _background = Color(0xFFFFFDE7);
  static const _brown = Color(0xFF593D0D);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF475569);
  static const _yellow = Color(0xFFFFD54F);

  static Widget _text(
    String text,
    double size,
    FontWeight weight, {
    Color color = _ink,
    double height = 1.2,
  }) => Text(
    text,
    maxLines: 1,
    softWrap: false,
    style: TextStyle(
      fontFamily: 'MenuInter',
      fontFamilyFallback: const ['MenuKorean'],
      fontSize: kioskFontSize(size),
      fontWeight: weight,
      color: color,
      height: height,
    ),
  );

  static Widget _slot(
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
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    body: SafeArea(
      child: KioskViewport(
        child: KioskCanvas(
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
              _text('모두의 약', 18, FontWeight.w800, color: _brown),
            ),
            _slot(167, 57, 52, 34, _text('모약', 28, FontWeight.w800)),
            _slot(64, 99, 148, 48, _text('시작하기', 40, FontWeight.w800)),
            _slot(
              228,
              108.5,
              378,
              29,
              _text(
                '|  원하시는 구매 방법을 선택해 주세요',
                24,
                FontWeight.w500,
                color: _muted,
              ),
            ),
            _slot(
              953,
              89,
              61,
              27,
              _text('한국어', 22, FontWeight.w600, color: _muted),
            ),
            Positioned(
              left: 1026,
              top: 89,
              width: 16,
              height: 16,
              child: SvgPicture.asset('assets/menu/chevron.svg'),
            ),
            _slot(
              188,
              430,
              704,
              68,
              _text('언제나 안심하는 비상약 자판기', 56, FontWeight.w900, color: _brown),
            ),
            _slot(
              207,
              532,
              664,
              29,
              _text(
                '365일 24시간 스마트 비상 의약품 자판기 서비스 모두의 약입니다.',
                24,
                FontWeight.w500,
                color: _muted,
              ),
            ),
            _card(
              context,
              0,
              660,
              '의약외품 즉시 구매',
              '밴드, 거즈, 마스크 등 의약외품을 본인인증 없이 간편하게 구매할 수 있습니다.',
              'pill_bottle.svg',
              titleWidth: 300,
              badge: '인증 불필요',
              badgeWidth: 102,
              badgeColor: const Color(0xFF10B981),
            ),
            _card(
              context,
              1,
              930,
              '본인인증 필요 약품 구매',
              '모바일 앱 연동 및 간편 본인인증이 필요한 성인 의약품 및 제한 약품 구매',
              'shield_user.svg',
              titleWidth: 390,
              badge: '본인인증',
              badgeWidth: 83,
              badgeColor: const Color(0xFFEF4444),
            ),
            _card(
              context,
              2,
              1200,
              '앱 다운로드 및 사용 방법',
              '모약 앱을 다운로드하고 다양한 서비스를 이용해 보세요.',
              'app_icon.svg',
              titleWidth: 540,
            ),
            Positioned(
              left: 0,
              top: 1758,
              width: 1080,
              height: 162,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFFFF3C4))),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _card(
    BuildContext context,
    int index,
    double top,
    String title,
    String description,
    String icon, {
    required double titleWidth,
    String? badge,
    double badgeWidth = 0,
    Color badgeColor = _ink,
  }) => Positioned(
    left: 64,
    top: top,
    width: 952,
    height: 224,
    child: DecoratedBox(
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
            top: 64,
            width: 96,
            height: 96,
            child: icon == 'app_icon.svg'
                ? SvgPicture.asset('assets/menu/$icon')
                : DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SvgPicture.asset('assets/menu/$icon'),
                    ),
                  ),
          ),
          _slot(168, 40, titleWidth, 46, _text(title, 36, FontWeight.w900)),
          if (badge != null)
            Positioned(
              left: 168 + titleWidth + 16,
              top: 52.5,
              width: badgeWidth,
              height: 27,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: _text(badge, 16, FontWeight.w700, color: badgeColor),
                ),
              ),
            ),
          Positioned(
            left: 168,
            top: 102,
            width: 640,
            height: 88,
            child: Text(
              description.replaceFirst(' 다양한', '\n다양한'),
              semanticsLabel: description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'MenuInter',
                fontFamilyFallback: ['MenuKorean'],
                fontSize: 28,
                height: 1.45,
                color: _muted,
              ),
            ),
          ),
          Positioned(
            left: 824,
            top: 68,
            width: 88,
            height: 88,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    offset: Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Material(
                color: _yellow,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: ValueKey('menu-route-$index'),
                  customBorder: const CircleBorder(),
                  onTap: () {
                    if (onSelect != null) {
                      onSelect!(index);
                      return;
                    }
                    if (index == 0) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const KioskProductListScreen(),
                        ),
                      );
                      return;
                    }
                    if (index == 1) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const KioskQrDownloadScreen(),
                        ),
                      );
                      return;
                    }
                    if (index == 2) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const KioskUsageGuideScreen(),
                        ),
                      );
                    }
                  },
                  child: Semantics(
                    button: true,
                    label: title,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SvgPicture.asset('assets/menu/arrow.svg'),
                    ),
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
