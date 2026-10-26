import '../widgets/kiosk_viewport.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'kiosk_menu_screen.dart';
import 'kiosk_usage_guide_screen.dart';

/// UI example for a linked user without approved medicines.
/// Displaying this screen never establishes authentication or approval status.
class KioskNoApprovedHomeScreen extends StatelessWidget {
  const KioskNoApprovedHomeScreen({
    super.key,
    this.onUsageGuide,
    this.onLogout,
    this.memberName = '지*민 님',
  });

  /// Optional guide navigation hook. Does not launch consultation or a phone app.
  final VoidCallback? onUsageGuide;
  final VoidCallback? onLogout;
  final String memberName;

  void _showAppGuide(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: _background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('MOYAK 앱 이용 안내', style: TextStyle(color: _brown)),
      content: const Text(
        '약사 상담은 휴대폰 MOYAK 앱에서 진행할 수 있어요.\n\n'
        '휴대폰에서 MOYAK 앱을 열어 상담 기능을 이용해 주세요.\n\n'
        '현재 키오스크의 앱 실행·딥링크·QR 연결 기능은 준비 중입니다. '
        '이 버튼은 앱이나 영상 상담을 실행하지 않습니다.',
        style: TextStyle(color: _muted, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('닫기', style: TextStyle(color: _brown)),
        ),
        TextButton(
          key: const ValueKey('no-approved-existing-guide'),
          onPressed: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const KioskUsageGuideScreen(),
              ),
            );
          },
          child: const Text('기존 사용 방법 보기', style: TextStyle(color: _brown)),
        ),
      ],
    ),
  );
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
            Positioned(
              left: 895,
              top: 226,
              width: 170,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
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
                          color: _brown,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        _text(memberName, 26, FontWeight.w700, color: _brown),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 116,
              top: 430,
              width: 850,
              height: 188,
              child: Material(
                color: _yellow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: _brown, width: 4),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: const ValueKey('no-approved-banner'),
                  onTap: () => _previewMessage(
                    context,
                    '현재 승인된 약이 없는 상태를 보여주는 예시 화면입니다. 실제 승인 조회는 연결되지 않았습니다.',
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 60,
                        top: 34,
                        width: 96,
                        height: 124,
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.topLeft,
                            minWidth: 192,
                            maxWidth: 192,
                            minHeight: 128,
                            maxHeight: 128,
                            child: Transform.translate(
                              offset: const Offset(-56, -5),
                              child: Image.asset(
                                'assets/moyak_character.png',
                                width: 192,
                                height: 128,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _slot(
                        184,
                        44,
                        488,
                        54,
                        _text(
                          '아직 승인된 약이 없어요',
                          44,
                          FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      _slot(
                        212,
                        108,
                        470,
                        36,
                        _text(
                          '현재 수령할 수 있는 승인된 약이 없습니다.',
                          28,
                          FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      Positioned(
                        left: 712,
                        top: 54,
                        width: 84,
                        height: 84,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: _brown,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _slot(
              207,
              674,
              664,
              36,
              _text(
                '365일 24시간 스마트 비상 의약품 자판기 서비스 모두의 약입니다.',
                24,
                FontWeight.w500,
                color: _muted,
              ),
            ),
            Positioned(
              left: 927,
              top: 1700,
              width: 130,
              height: 44,
              child: TextButton(
                key: const ValueKey('no-approved-logout'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                onPressed: () {
                  if (onLogout != null) {
                    onLogout!();
                    return;
                  }
                  _previewMessage(
                    context,
                    '테스트용 로그아웃: 일반 홈으로 이동합니다. 실제 인증 세션 종료는 연결되지 않았습니다.',
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) => const KioskMenuScreen(),
                    ),
                    (route) => route.isFirst,
                  );
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
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
            _consultationCard(context),
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

  void _previewMessage(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(
              24,
              0,
              24,
              MediaQuery.sizeOf(context).height * 0.15,
            ),
            content: Text(message),
          ),
        );
  Widget _consultationCard(BuildContext context) => Positioned(
    left: 64,
    top: 860,
    width: 952,
    height: 520,
    child: Container(
      padding: const EdgeInsets.all(48),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _text('약사 상담 안내', 38, FontWeight.w900, color: _brown),
          const SizedBox(height: 28),
          Text(
            '약사 상담은 휴대폰 MOYAK 앱에서 진행할 수 있어요.',
            style: const TextStyle(
              fontFamily: 'MenuInter',
              fontFamilyFallback: ['MenuKorean'],
              fontSize: 30,
              color: _muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 82,
            child: Material(
              color: _yellow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const ValueKey('no-approved-consultation'),
                onTap: onUsageGuide ?? () => _showAppGuide(context),
                child: Center(
                  child: _text(
                    '앱 이용 방법 확인하기',
                    28,
                    FontWeight.w800,
                    color: _brown,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _text(
            '앱 연결 기능이 준비되면 실제 상담 화면으로 연결할 수 있어요.',
            24,
            FontWeight.w500,
            color: _muted,
          ),
        ],
      ),
    ),
  );
}
