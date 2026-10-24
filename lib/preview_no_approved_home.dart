import 'package:flutter/material.dart';

import 'main.dart';
import 'screens/kiosk_no_approved_home_screen.dart';

/// UI-only example; does not establish authentication or query approvals.
/// flutter run -t lib/preview_no_approved_home.dart
void main() => runApp(const NoApprovedHomePreviewApp());

class NoApprovedHomePreviewApp extends StatelessWidget {
  const NoApprovedHomePreviewApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MOYAK 승인 약품 없음 화면 미리보기',
    debugShowCheckedModeBanner: false,
    home: const KioskStartScreen(),
    // Keep the start screen beneath the preview for the existing logout flow.
    initialRoute: '/preview',
    routes: {'/preview': (_) => const KioskNoApprovedHomeScreen()},
  );
}
