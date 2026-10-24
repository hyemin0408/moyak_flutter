import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak_flutter/main.dart';
import 'package:moyak_flutter/screens/kiosk_linked_home_screen.dart';
import 'package:moyak_flutter/screens/kiosk_menu_screen.dart';
import 'package:moyak_flutter/screens/kiosk_no_approved_home_screen.dart';
import 'package:moyak_flutter/screens/kiosk_usage_guide_screen.dart';

void main() {
  testWidgets('One normal app selects all example homes and resets on logout', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.byType(KioskMenuScreen), findsOneWidget);

    Future<void> select(String state) async {
      await tester.longPress(find.text('시작하기'));
      await tester.pumpAndSettle();
      expect(find.text('개발용 홈 상태 선택 · 실제 인증 아님'), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('home-preview-$state')));
      await tester.pumpAndSettle();
    }

    await select('approvedMedicines');
    expect(find.byType(KioskLinkedHomeScreen), findsOneWidget);
    await select('noApprovedMedicines');
    expect(find.byType(KioskNoApprovedHomeScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('no-approved-consultation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('no-approved-existing-guide')));
    await tester.pumpAndSettle();
    expect(find.byType(KioskUsageGuideScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('usage-back')));
    await tester.pumpAndSettle();
    expect(find.byType(KioskNoApprovedHomeScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('no-approved-logout')));
    await tester.pumpAndSettle();
    expect(find.byType(KioskMenuScreen), findsOneWidget);
    await select('approvedMedicines');
    await tester.tap(find.byKey(const ValueKey('linked-logout')));
    await tester.pumpAndSettle();
    expect(find.byType(KioskMenuScreen), findsOneWidget);
    await select('signedOut');
    expect(find.byType(KioskMenuScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(KioskMenuScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(KioskStartScreen), findsOneWidget);
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.byType(KioskMenuScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
