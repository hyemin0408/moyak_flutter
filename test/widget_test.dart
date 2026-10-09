import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak_flutter/main.dart';
import 'package:moyak_flutter/screens/kiosk_menu_screen.dart';

void main() {
  testWidgets('Start screen scales and invokes its separate callback', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    var starts = 0;
    final previewKey = GlobalKey();

    for (final size in [const Size(1080, 1920), const Size(1920, 1080)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: previewKey,
            child: KioskStartScreen(onStart: () => starts++),
          ),
        ),
      );
      await tester.runAsync(() async {
        for (final element in find.byType(Image).evaluate()) {
          await precacheImage((element.widget as Image).image, element);
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(InkWell), findsOneWidget);
      final character = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/moyak_character.png',
      );
      final bounds = tester.getRect(character);
      final bodyCenter = bounds.left + bounds.width * 822.5 / 1536;
      expect(bodyCenter, closeTo(size.width / 2, 1));

      if (size.width == 1080) {
        await tester.runAsync(() async {
          final boundary =
              previewKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build').create(recursive: true);
          await File('build/moyak_start_preview.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
    }
    expect(starts, 2);
  });

  testWidgets('Start opens menu and back returns to start', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.byType(KioskMenuScreen), findsOneWidget);
    expect(find.text('의약외품 즉시 구매'), findsOneWidget);
    Navigator.of(tester.element(find.byType(KioskMenuScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(KioskStartScreen), findsOneWidget);
  });
}
