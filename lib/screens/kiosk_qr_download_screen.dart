import '../widgets/kiosk_viewport.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'kiosk_device_pairing_screen.dart';

/// Metadata-based layout for Figma kiosk-qr-download (86:206).
/// Colors, typography and decoration reuse existing screens provisionally;
/// screenshot/design context were unavailable because of the MCP call limit.
class KioskQrDownloadScreen extends StatelessWidget {
  const KioskQrDownloadScreen({super.key});

  static const _background = Color(0xFFFFFDE7);
  static const _plate = Color(0xFFFFF8E1);
  static const _border = Color(0xFFFFF3C4);
  static const _yellow = Color(0xFFFFD54F);
  static const _brown = Color(0xFF593D0D);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF475569);

  static TextStyle _style(
    double size, {
    Color color = _ink,
    FontWeight weight = FontWeight.w500,
  }) => TextStyle(
    fontFamily: 'MenuInter',
    fontFamilyFallback: const ['MenuKorean'],
    fontSize: kioskFontSize(size),
    color: color,
    fontWeight: weight,
    height: 1.2,
  );

  static Widget _label(
    String text,
    double size, {
    Color color = _ink,
    FontWeight weight = FontWeight.w500,
  }) => Text(
    text,
    maxLines: 1,
    softWrap: false,
    style: _style(size, color: color, weight: weight),
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

  static Widget _panel({
    Color color = Colors.white,
    double radius = 16,
    required Widget child,
  }) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: _border),
      borderRadius: BorderRadius.circular(radius),
    ),
    child: child,
  );

  static Widget _button(
    String key,
    VoidCallback action,
    Widget child, {
    Color color = _yellow,
  }) => Material(
    color: color,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: _border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey(key),
      onTap: action,
      child: Center(child: child),
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
              left: 46,
              top: 57,
              width: 91,
              height: 30,
              child: _panel(color: _yellow, radius: 6, child: const SizedBox()),
            ),
            _slot(
              56,
              61,
              71,
              22,
              _label('모두의 약', 18, color: _brown, weight: FontWeight.w800),
            ),
            _slot(149, 55, 52, 34, _label('모약', 28, weight: FontWeight.w800)),
            _slot(
              46,
              98,
              321,
              48,
              _label('앱 연동 및 다운로드', 40, weight: FontWeight.w800),
            ),
            _slot(
              383,
              107.5,
              325,
              29,
              _label('|  본인인증을 위한 QR 코드 안내', 24, color: _muted),
            ),
            Positioned(
              left: 911,
              top: 76,
              width: 133,
              height: 51,
              child: _panel(radius: 12, child: const SizedBox()),
            ),
            _slot(
              935,
              88,
              61,
              27,
              _label('한국어', 22, color: _muted, weight: FontWeight.w600),
            ),
            Positioned(
              left: 1004,
              top: 93.5,
              width: 16,
              height: 16,
              child: SvgPicture.asset('assets/menu/chevron.svg'),
            ),
            _slot(
              433,
              458,
              214,
              48,
              _label('QR 다운로드', 40, color: _brown, weight: FontWeight.w800),
            ),
            _slot(
              169,
              522,
              741,
              31,
              _label(
                '아래 QR코드를 스마트폰 카메라로 스캔하여 전용 앱을 설치해주세요.',
                26,
                color: _muted,
              ),
            ),
            Positioned(
              left: 360,
              top: 626,
              width: 360,
              height: 413,
              child: _panel(radius: 24, child: const SizedBox()),
            ),
            Positioned(
              left: 400,
              top: 666,
              width: 280,
              height: 280,
              child: Semantics(
                label: '임시 QR 코드 영역, 현재 스캔 불가',
                child: _panel(
                  color: _plate,
                  radius: 8,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'QR 코드 준비 중',
                          style: _style(
                            26,
                            color: _brown,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('현재 스캔 불가', style: _style(22, color: _muted)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _slot(
              410.5,
              970,
              259,
              29,
              _label('스마트폰 전용 앱 다운로드', 24, color: _muted),
            ),
            _step(43, 0, 'QR 스캔 & 설치', "카메라로 스캔하여 마켓에서 '모약' 앱을 설치하세요."),
            _step(380, 1, '본인인증 완료', '앱 설치 후, 회원가입과 1회성 간편 본인인증을 마쳐주세요.'),
            _step(714, 2, '자판기 연동', '인증이 끝나면 다음 화면의 자판기 QR 코드를 스캔하세요.'),
            Positioned(
              left: 249,
              top: 1375,
              width: 582,
              height: 90,
              child: _button(
                'qr-pair-next',
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const KioskDevicePairingScreen(),
                    ),
                  );
                },
                _label(
                  '설치를 완료했습니다 (자판기 연동하기)',
                  28,
                  color: _brown,
                  weight: FontWeight.w800,
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
              child: _button(
                'qr-back',
                () => Navigator.of(context).pop(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/products/back.svg',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 16),
                    _label('이전으로', 28, weight: FontWeight.w700),
                  ],
                ),
                color: _plate,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _step(double left, int index, String title, String description) =>
      Positioned(
        left: left,
        top: 1087,
        width: 316,
        height: 260,
        child: _panel(
          color: _plate,
          child: Stack(
            children: [
              Positioned(
                left: 8,
                top: 34,
                width: 48,
                height: 48,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: _yellow,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _label(
                      '${index + 1}',
                      26,
                      color: _brown,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              _slot(
                32,
                96,
                284,
                31,
                _label(title, 26, weight: FontWeight.w700),
              ),
              Positioned(
                left: 32,
                top: 141,
                width: 284,
                height: 108,
                child: Text(description, style: _style(24, color: _muted)),
              ),
            ],
          ),
        ),
      );
}
