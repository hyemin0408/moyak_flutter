import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak_flutter/main.dart';
import 'package:moyak_flutter/screens/kiosk_auth_complete_screen.dart';
import 'package:moyak_flutter/screens/kiosk_device_pairing_screen.dart';
import 'package:moyak_flutter/screens/kiosk_linked_home_screen.dart';
import 'package:moyak_flutter/screens/kiosk_menu_screen.dart';
import 'package:moyak_flutter/screens/kiosk_qr_download_screen.dart';

void main() {
  testWidgets(
    'Preview logout returns to general home and clears linked routes',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      for (final key in [
        'menu-route-1',
        'qr-pair-next',
        'pairing-preview-complete',
        'auth-preview-continue',
        'linked-logout',
      ]) {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
      }
      expect(find.byType(KioskMenuScreen), findsOneWidget);
      expect(
        find.byType(KioskLinkedHomeScreen, skipOffstage: false),
        findsNothing,
      );
      expect(
        find.byType(KioskAuthCompleteScreen, skipOffstage: false),
        findsNothing,
      );
      expect(
        find.byType(KioskDevicePairingScreen, skipOffstage: false),
        findsNothing,
      );
      Navigator.of(tester.element(find.byType(KioskMenuScreen))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(KioskStartScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Normal app keeps general home and explicitly previews linked home',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      expect(find.byType(KioskMenuScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('menu-route-1')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskQrDownloadScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('qr-pair-next')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskDevicePairingScreen), findsOneWidget);
      await tester.pump(const Duration(minutes: 1));
      expect(find.byType(KioskAuthCompleteScreen), findsNothing);
      expect(find.byType(KioskLinkedHomeScreen), findsNothing);
      await tester.tap(find.byKey(const ValueKey('pairing-preview-complete')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskAuthCompleteScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('auth-preview-continue')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskLinkedHomeScreen), findsOneWidget);

      for (final screen in [
        KioskAuthCompleteScreen,
        KioskDevicePairingScreen,
        KioskQrDownloadScreen,
        KioskMenuScreen,
      ]) {
        Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
        await tester.pumpAndSettle();
        expect(find.byType(screen), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('menu-route-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('menu-route-2')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
