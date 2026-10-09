import 'package:flutter/material.dart';

import 'screens/kiosk_auth_complete_screen.dart';
import 'screens/kiosk_linked_home_screen.dart';

/// Separate UI-only entry point. Never simulates a real authentication event.
/// Run with: flutter run -t lib/preview_auth_complete.dart
void main() => runApp(const AuthCompletePreviewApp());

class AuthCompletePreviewApp extends StatelessWidget {
  const AuthCompletePreviewApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MOYAK 본인인증 완료 화면 미리보기',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
    home: Builder(
      builder: (context) => KioskAuthCompleteScreen(
        onPreviewContinue: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const KioskLinkedHomeScreen(),
          ),
        ),
      ),
    ),
  );
}
