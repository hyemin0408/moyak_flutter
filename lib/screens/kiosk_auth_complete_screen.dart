import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Visual prototype from the supplied reference for 86:295.
/// This screen does not authenticate a user or activate a transaction limit.
class KioskAuthCompleteScreen extends StatelessWidget {
  const KioskAuthCompleteScreen({
    super.key,
    this.onPreviewContinue,
    this.deviceLinkOnly = false,
    this.memberName = '지*민',
  });
  final bool deviceLinkOnly;
  final String memberName;

  /// Explicit preview navigation only; does not signal verified authentication.
  final VoidCallback? onPreviewContinue;

  static const _background = Color(0xFFFFFDE7);
  static const _plate = Color(0xFFFFF8E1);
  static const _border = Color(0xFFFFF3C4);
  static const _yellow = Color(0xFFFFD54F);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF475569);
  static const _orange = Color(0xFFFF9800);

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
    double left,
    double top,
    double width,
    double height,
    Widget child, {
    Alignment alignment = Alignment.centerLeft,
  }) => Positioned(
    left: left,
    top: top,
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
                  left: 68,
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
                  78,
                  63,
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
                  171,
                  57,
                  52,
                  34,
                  _text('모약', 28, weight: FontWeight.w800),
                ),
                _slot(
                  68,
                  101,
                  230,
                  48,
                  _text(
                    deviceLinkOnly ? '기기 연동 완료' : '본인인증 완료',
                    40,
                    weight: FontWeight.w800,
                  ),
                ),
                _slot(
                  314,
                  109,
                  390,
                  29,
                  _text(
                    deviceLinkOnly
                        ? '|  앱과 기기 연결을 확인했습니다'
                        : '|  본인인증이 안전하게 완료되었습니다',
                    24,
                    color: _muted,
                  ),
                ),
                Positioned(
                  left: 906,
                  top: 76,
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
                  left: 450,
                  top: 594,
                  width: 180,
                  height: 180,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _plate,
                      border: Border.all(color: _yellow, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x148B6914),
                          offset: Offset(0, 16),
                          blurRadius: 50,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: CustomPaint(painter: _CompletionCheckPainter()),
                      ),
                    ),
                  ),
                ),
                _slot(
                  160,
                  838,
                  760,
                  64,
                  onPreviewContinue == null
                      ? _text('$memberName님 환영합니다', 48, weight: FontWeight.w900)
                      : Tooltip(
                          message: '테스트용: 연동 사용자 홈 미리보기',
                          child: InkWell(
                            key: const ValueKey('auth-preview-continue'),
                            onTap: onPreviewContinue,
                            child: _text(
                              '$memberName님 환영합니다',
                              48,
                              weight: FontWeight.w900,
                            ),
                          ),
                        ),
                  alignment: Alignment.center,
                ),
                _slot(
                  160,
                  914,
                  760,
                  40,
                  _text(
                    deviceLinkOnly
                        ? '화면을 터치하여 계속하세요. 결제·본인인증 완료를 의미하지 않습니다.'
                        : '본인 연동 및 안전 거래 한도가 활성화되었습니다.',
                    28,
                    color: _muted,
                  ),
                  alignment: Alignment.center,
                ),
                Positioned(
                  left: 140,
                  top: 1016,
                  width: 800,
                  height: 142,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _plate,
                      border: Border.all(color: _border),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          offset: Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  left: 172,
                  top: 1050,
                  width: 26,
                  height: 26,
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: _orange,
                    size: 26,
                  ),
                ),
                _slot(
                  212,
                  1048,
                  550,
                  34,
                  _text(
                    '안내 및 보안 주의 사항',
                    28,
                    color: _orange,
                    weight: FontWeight.w700,
                  ),
                ),
                _slot(
                  174,
                  1100,
                  732,
                  32,
                  _text(
                    '- 약품 결제가 완료되면 회원 정보가 안전을 위해 자동 로그아웃됩니다.',
                    24,
                    color: _muted,
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
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _CompletionCheckPainter extends CustomPainter {
  const _CompletionCheckPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B6914)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.save();
    canvas.scale(size.width / 80, size.height / 80);
    canvas.drawArc(
      const Rect.fromLTWH(6, 6, 68, 68),
      -0.2,
      math.pi * 1.72,
      false,
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(30, 36)
        ..lineTo(40, 46)
        ..lineTo(74, 12),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CompletionCheckPainter oldDelegate) => false;
}
