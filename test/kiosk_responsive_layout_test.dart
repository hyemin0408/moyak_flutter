import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak_flutter/main.dart';
import 'package:moyak_flutter/demo/demo_cart.dart';
import 'package:moyak_flutter/demo/demo_approved_cart.dart';
import 'package:moyak_flutter/screens/kiosk_menu_screen.dart';
import 'package:moyak_flutter/screens/kiosk_linked_home_screen.dart';
import 'package:moyak_flutter/screens/kiosk_no_approved_home_screen.dart';
import 'package:moyak_flutter/screens/kiosk_product_list_screen.dart';
import 'package:moyak_flutter/screens/kiosk_cart_screen.dart';
import 'package:moyak_flutter/screens/kiosk_payment_screen.dart';
import 'package:moyak_flutter/screens/kiosk_qr_download_screen.dart';
import 'package:moyak_flutter/screens/kiosk_device_pairing_screen.dart';
import 'package:moyak_flutter/screens/kiosk_auth_complete_screen.dart';
import 'package:moyak_flutter/screens/kiosk_usage_guide_screen.dart';
import 'package:moyak_flutter/screens/kiosk_dispensing_screen.dart';
import 'package:moyak_flutter/screens/kiosk_dispensing_complete_screen.dart';
import 'package:moyak_flutter/widgets/kiosk_viewport.dart';

void main() {
  testWidgets(
    'tall viewport anchors header/footer and preserves centered artwork',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KioskViewport(
              child: KioskCanvas(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    width: 1080,
                    height: 204,
                    child: SizedBox(key: ValueKey('header')),
                  ),
                  Positioned(
                    top: 1758,
                    left: 0,
                    width: 1080,
                    height: 162,
                    child: SizedBox(key: ValueKey('footer')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.getRect(find.byKey(const ValueKey('header'))).top, 0);
      expect(tester.getRect(find.byKey(const ValueKey('footer'))).bottom, 2400);
      expect(tester.getRect(find.byKey(const ValueKey('footer'))).height, 162);
    },
  );

  testWidgets(
    'all customer pages fit kiosk, tall phone, small phone and landscape',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        final icons = FontLoader('MaterialIcons');
        icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
        for (final font in ['Inter', 'NotoSansKR']) {
          final loader = FontLoader(
            font == 'Inter' ? 'MenuInter' : 'MenuKorean',
          );
          loader.addFont(rootBundle.load('assets/fonts/$font.ttf'));
          await loader.load();
        }
      });
      final cart = DemoCart();
      final approved = createDemoApprovedCart();
      addTearDown(cart.dispose);
      addTearDown(approved.dispose);
      final screens = <String, Widget Function()>{
        'start': () => const KioskStartScreen(),
        'home': () => const KioskMenuScreen(),
        'linked_home': () => const KioskLinkedHomeScreen(),
        'no_approved_home': () => const KioskNoApprovedHomeScreen(),
        'products': () => KioskProductListScreen(cart: cart),
        'cart': () => KioskCartScreen(cart: cart),
        'approved_cart': () =>
            KioskCartScreen(cart: approved, showMember: true),
        'payment': () => KioskPaymentScreen(cart: cart, showMember: true),
        'download': () => const KioskQrDownloadScreen(),
        'pairing': () => const KioskDevicePairingScreen(),
        'auth_complete': () => const KioskAuthCompleteScreen(),
        'usage': () => const KioskUsageGuideScreen(),
        'dispensing': () => KioskDispensingScreen.preview(
          onFirstScreen: () {},
          showMember: true,
        ),
        'dispensing_complete': () => KioskDispensingCompleteScreen.preview(
          onFirstScreen: () {},
          showMember: true,
        ),
      };
      for (final size in [
        const Size(1080, 1920),
        const Size(1080, 2400),
        const Size(393, 852),
        const Size(1920, 1080),
      ]) {
        tester.view.physicalSize = size;
        for (final entry in screens.entries) {
          final boundaryKey = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              home: RepaintBoundary(key: boundaryKey, child: entry.value()),
            ),
          );
          await tester.runAsync(() async {
            for (final element in find.byType(Image).evaluate()) {
              await precacheImage((element.widget as Image).image, element);
            }
          });
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key} at $size',
          );
          if (size.width == 1080) {
            await tester.runAsync(() async {
              final boundary =
                  boundaryKey.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await Directory('build/layout-review').create(recursive: true);
              await File(
                'build/layout-review/${entry.key}-${size.height.toInt()}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
        }
      }
    },
  );
}
