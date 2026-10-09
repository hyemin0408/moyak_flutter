import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'kiosk_auth_complete_screen.dart';
import 'kiosk_linked_home_screen.dart';

/// UI prototype based on the supplied 1080x1920 reference for node 86:257.
/// The displayed key and QR placeholder never initiate a real pairing session.
class KioskDevicePairingScreen extends StatelessWidget {
  const KioskDevicePairingScreen({super.key});

  // Debug-only navigation preview; never creates a verified session.
  Widget _completionPreview(BuildContext context, Widget child) {
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
                  builder: (_) => const KioskLinkedHomeScreen(),
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
    fontSize: size,
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
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 1080,
            height: 1920,
            child: Stack(
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
                _slot(
                  161,
                  55,
                  52,
                  34,
                  _text('모약', 28, weight: FontWeight.w800),
                ),
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
                      label: '임시 QR 모양, 실제 스캔 및 연동 불가',
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
                          '자판기 고유인증 키: MD-2409-ROME',
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
                    label: '스마트폰 연동 대기 표시, 디자인 예시이며 실제 연결하지 않음',
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
                                '스마트폰 연동 대기 중...',
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
      ),
    ),
  );
}
