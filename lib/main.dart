import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'screens/kiosk_menu_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MOYAK',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
    home: const KioskStartScreen(),
  );
}

class KioskStartScreen extends StatelessWidget {
  const KioskStartScreen({super.key, this.onStart});

  final VoidCallback? onStart;
  static const backgroundColor = Color(0xFFFFFDE7);
  static const textColor = Color(0xFF593D0D);

  void _handleStart(BuildContext context) {
    if (onStart != null) {
      onStart!();
      return;
    }
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const KioskMenuScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // The source is 1536x1024. The visible character body spans x=449..1196;
    // the greeting on its left is separate from the body's visual center.
    const characterWidth = 1069.0;
    const characterCenterX = (449 + 1196) / 2;
    const characterLeft = 540 - characterCenterX * characterWidth / 1536;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 1080,
              height: 1920,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: 156,
                    top: 250,
                    width: 746,
                    height: 242,
                    child: SvgPicture.asset(
                      'assets/moyak_logo.svg',
                      semanticsLabel: 'MOYAK',
                    ),
                  ),
                  Positioned(
                    left: 409,
                    top: 529,
                    width: 277,
                    height: 85,
                    child: Image.asset(
                      'assets/moyak_subtitle.png',
                      semanticLabel: '모두의 약',
                    ),
                  ),
                  Positioned(
                    left: characterLeft,
                    top: 712,
                    width: characterWidth,
                    height: 712,
                    child: Image.asset(
                      'assets/moyak_character.png',
                      fit: BoxFit.cover,
                      semanticLabel: '안녕! 모약이야! MOYAK 캐릭터',
                    ),
                  ),
                  Positioned(
                    left: 257,
                    top: 1521,
                    width: 565,
                    height: 115,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD54F),
                        borderRadius: BorderRadius.circular(45),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            offset: Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 247,
                    top: 1515,
                    width: 585,
                    height: 135,
                    child: ExcludeSemantics(
                      child: SvgPicture.asset('assets/start_button.svg'),
                    ),
                  ),
                  Positioned(
                    left: 257,
                    top: 1521,
                    width: 565,
                    height: 115,
                    child: Semantics(
                      button: true,
                      label: '터치해주세요',
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(45),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _handleStart(context),
                          splashColor: textColor.withValues(alpha: 0.12),
                          child: Center(
                            child: ExcludeSemantics(
                              child: Text(
                                '터치해주세요',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
                            ),
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
}
