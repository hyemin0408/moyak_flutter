import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak_flutter/screens/kiosk_menu_screen.dart';

void main() {
  testWidgets('Menu scales, renders its assets, and invokes each selection', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.runAsync(() async {
      for (final font in ['Inter', 'NotoSansKR']) {
        final loader = FontLoader(font == 'Inter' ? 'MenuInter' : 'MenuKorean');
        loader.addFont(rootBundle.load('assets/fonts/$font.ttf'));
        await loader.load();
      }
    });
    final selected = <int>[];
    final previewKey = GlobalKey();
    for (final size in [
      const Size(1080, 1920),
      const Size(540, 960),
      const Size(1920, 1080),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: previewKey,
            child: KioskMenuScreen(onSelect: selected.add),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('시작하기'), findsOneWidget);
      expect(find.text('앱 다운로드 및 사용 방법'), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (var index = 0; index < 3; index++) {
        await tester.tap(find.byKey(ValueKey('menu-route-$index')));
        await tester.pumpAndSettle();
      }
      if (size.width == 1080) {
        await tester.runAsync(() async {
          final boundary =
              previewKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build').create(recursive: true);
          await File('build/moyak_menu_preview.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
    expect(selected, [0, 1, 2, 0, 1, 2, 0, 1, 2]);
  });
}
