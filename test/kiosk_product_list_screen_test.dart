import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak_flutter/main.dart';
import 'package:moyak_flutter/screens/kiosk_menu_screen.dart';
import 'package:moyak_flutter/screens/kiosk_product_list_screen.dart';
import 'package:moyak_flutter/screens/kiosk_qr_download_screen.dart';
import 'package:moyak_flutter/screens/kiosk_usage_guide_screen.dart';
import 'package:moyak_flutter/screens/kiosk_cart_screen.dart';
import 'package:moyak_flutter/screens/kiosk_payment_screen.dart';

void main() {
  testWidgets('Example product search, categories, selections and scaling', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1080, 1920);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.runAsync(() async {
      for (final font in ['Inter', 'NotoSansKR']) {
        final loader = FontLoader(font == 'Inter' ? 'MenuInter' : 'MenuKorean');
        loader.addFont(rootBundle.load('assets/fonts/$font.ttf'));
        await loader.load();
      }
    });
    final previewKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: previewKey,
          child: const KioskProductListScreen(),
        ),
      ),
    );
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is InkWell &&
            widget.key.toString().contains('product-card-'),
      ),
      findsNWidgets(6),
    );
    expect(find.text('7,000원'), findsOneWidget);
    await tester.runAsync(() async {
      final oldShadows = debugDisableShadows;
      debugDisableShadows = false;
      try {
        // Repaint before capture with the real shadow settings.
        (previewKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .markNeedsPaint();
      } finally {
        debugDisableShadows = oldShadows;
      }
    });
    await tester.pump();
    await tester.runAsync(() async {
      final boundary =
          previewKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build').create(recursive: true);
      await File('build/moyak_product_list_preview.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.enterText(find.byKey(const ValueKey('product-search')), '마스크');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('product-card-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('product-card-0')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('product-category-4')));
    await tester.pumpAndSettle();
    expect(find.text('검색 결과가 없습니다.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('product-card-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('product-card-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('product-card-4')), findsOneWidget);
    expect(find.byKey(const ValueKey('product-card-2')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('product-category-1')));
    await tester.pumpAndSettle();
    expect(find.text('검색 결과가 없습니다.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('product-category-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-product-0')));
    await tester.pumpAndSettle();
    expect(find.text('10,500원'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('product-card-0')));
    await tester.pumpAndSettle();
    expect(find.text('예시 제품 선택: 대일밴드 뉴 표준형 20매'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('complete-selection')));
    await tester.pumpAndSettle();
    expect(find.byType(KioskCartScreen), findsOneWidget);
    expect(find.text('10,500원'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cart-checkout')));
    await tester.pumpAndSettle();
    expect(find.byType(KioskPaymentScreen), findsOneWidget);
    expect(find.text('10,500원'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('payment-cancel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cart-add-products')));
    await tester.pumpAndSettle();
    expect(find.byType(KioskProductListScreen), findsOneWidget);
    for (final size in [const Size(540, 960), const Size(1920, 1080)]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final back = tester.getRect(
        find.byKey(const ValueKey('previous-screen')),
      );
      expect(back.left, greaterThanOrEqualTo(0));
      expect(back.bottom, lessThanOrEqualTo(size.height));
    }
  });

  testWidgets(
    'Start to home to products and back preserves other home actions',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      expect(find.byType(KioskMenuScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('menu-route-0')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskProductListScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('previous-screen')));
      await tester.pumpAndSettle();
      expect(find.byType(KioskMenuScreen), findsOneWidget);
      for (final index in [1, 2]) {
        await tester.tap(find.byKey(ValueKey('menu-route-$index')));
        await tester.pumpAndSettle();
        expect(find.byType(KioskProductListScreen), findsNothing);
        if (index == 1) {
          expect(find.byType(KioskQrDownloadScreen), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('qr-back')));
          await tester.pumpAndSettle();
          expect(find.byType(KioskMenuScreen), findsOneWidget);
        } else {
          expect(find.byType(KioskUsageGuideScreen), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('usage-back')));
          await tester.pumpAndSettle();
          expect(find.byType(KioskMenuScreen), findsOneWidget);
        }
      }
    },
  );
}
