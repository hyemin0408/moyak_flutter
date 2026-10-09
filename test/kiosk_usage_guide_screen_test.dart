import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak_flutter/screens/kiosk_usage_guide_screen.dart';

void main() {
  testWidgets(
    'All five usage steps and back button fit portrait and landscape',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      const titles = [
        '구매 방법을 선택해 주세요',
        '원하는 약품을 찾아주세요',
        '약품을 장바구니에 담아주세요',
        '결제 방법을 선택해 주세요',
        '약품을 수령해 주세요',
      ];
      for (final size in [
        const Size(1080, 1920),
        const Size(540, 960),
        const Size(1920, 1080),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          const MaterialApp(home: KioskUsageGuideScreen()),
        );
        await tester.pumpAndSettle();
        expect(find.text('앱 다운로드 및 사용 방법'), findsOneWidget);
        double previousBottom = 0;
        for (var index = 0; index < 5; index++) {
          expect(find.text(titles[index]), findsOneWidget);
          final bounds = tester.getRect(
            find.byKey(ValueKey('usage-step-${index + 1}')),
          );
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(size.width));
          expect(bounds.top, greaterThan(previousBottom));
          expect(bounds.bottom, lessThan(size.height));
          previousBottom = bounds.bottom;
        }
        final back = tester.getRect(find.byKey(const ValueKey('usage-back')));
        expect(back.top, greaterThan(previousBottom));
        expect(back.bottom, lessThanOrEqualTo(size.height));
        expect(find.byType(InkWell), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
