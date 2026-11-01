import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moyak_flutter/models/product_image_catalog.dart';
import 'package:moyak_flutter/models/moyak_api_models.dart';
import 'package:moyak_flutter/services/kiosk_backend.dart';
import 'package:moyak_flutter/services/moyak_api_client.dart';
import 'package:moyak_flutter/screens/kiosk_product_list_screen.dart';
import 'package:moyak_flutter/screens/kiosk_cart_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('waterproof band display correction does not rename other products', () {
    expect(
      productDisplayName(itemSeq: '901000032', name: '일회용 렌즈 세정액 20ml x 50A'),
      '일회용 렌즈 세정액 10ml x 25개',
    );
    expect(
      productDisplayName(itemSeq: '901000033', name: '의료용 안대 5매'),
      '의료용 안대 1매',
    );
    expect(
      productDisplayName(itemSeq: '901000033', name: '다른 서버 상품명'),
      '다른 서버 상품명',
    );
    expect(
      productDisplayName(itemSeq: '901000032', name: '일회용 렌즈 세정액 15ml x5'),
      '일회용 렌즈 세정액 10ml x 25개',
    );
    expect(
      productDisplayName(itemSeq: '901000032', name: '서버에서 변경한 새 상품명'),
      '서버에서 변경한 새 상품명',
    );
    expect(
      productDisplayName(itemSeq: '901000002', name: '대일밴드 방수형 10매'),
      '대일밴드 아쿠아뉴 방수형 밴드 8매',
    );
    expect(
      productDisplayName(itemSeq: '901000003', name: '대일밴드 어린이 캐릭터 15매'),
      '대일밴드 어린이 캐릭터 15매',
    );
    expect(
      productDisplayName(itemSeq: '901000002', name: '서버에서 변경한 새 상품명'),
      '서버에서 변경한 새 상품명',
    );
  });
  test('user supplied photos map by product code and exact name', () {
    const supplied = {
      '202209876': ('KF94 보건용 마스크', 'KF94 보건용 마스크.png'),
      '200300002': ('알콜스왑', '알콜스왑.png'),
      '200500003': ('좋은느낌 생리대', '좋은느낌 생리대.jpg'),
      '901000002': ('대일밴드 아쿠아뉴 방수형 밴드 8매', '아큐아뉴밴드.png'),
      '901000003': ('대일밴드 어린이 캐릭터 15매', 'children_band_white.png'),
      '901000004': ('메디폼 하이드로콜로이드 밴드 10매', '메디폼 하이드로콜로이드 밴드 10매.png'),
      '901000012': ('소독용 에탄올 솜 200매', '소독용 에탄올 솜 200매.png'),
      '901000021': ('바세린 오리지널 50g', '바세린 오리지널 50g.png'),
      '901000022': ('바세린 립테라피 7g', '바세린 립테라피 7g.png'),
      '901000031': ('콘택트렌즈 다목적 용액 360ml', 'lens_solution_white.png'),
      '901000032': ('일회용 렌즈 세정액 10ml x 25개', 'daily_disposable_lens_white.png'),
      '901000033': ('의료용 안대 1매', '의료용 안대 1매.png'),
      '901000042': ('좋은느낌 대형 14매', '좋은느낌 대형 14매.png'),
      '901000043': ('좋은느낌 오버나이트 10매', '좋은느낌 오버나이트 10매.png'),
      '901000044': ('순수한면 팬티라이너 40매', 'pantyliner_white.png'),
      '901000052': ('KF80 보건용 마스크 소형', 'KF80 보건용 마스크 소형.png'),
      '901000053': ('일회용 덴탈 마스크 50매', 'dental_mask_white.png'),
      '901000062': ('가그린 레귤러 100ml', '가그린 레귤러 100ml (2).png'),
    };
    for (final entry in supplied.entries) {
      expect(
        verifiedProductPhotoAsset(itemSeq: entry.key, name: ''),
        entry.value.$2,
      );
      expect(
        verifiedProductPhotoAsset(itemSeq: '', name: entry.value.$1),
        entry.value.$2,
      );
    }
    expect(
      verifiedProductPhotoAsset(itemSeq: '202101234', name: '메디폼 H뷰티'),
      'medifoam_h_beauty.jpg',
    );
    expect(
      verifiedProductPhotoAsset(itemSeq: '196500043', name: ''),
      'band.png',
    );
    expect(
      verifiedProductPhotoAsset(itemSeq: '199900001', name: ''),
      'mouthwash.png',
    );
    expect(
      verifiedProductPhotoAsset(itemSeq: '901000002', name: '대일밴드 방수형 10매'),
      '아큐아뉴밴드.png',
    );
  });
  test('all 36 mapped photos are included and decode successfully', () async {
    expect(productImageAssets.length, 36);
    for (final asset in productImageAssets.values.toSet()) {
      final bytes = await rootBundle.load('assets/products/$asset');
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThan(0), reason: asset);
      if (asset.endsWith('_white.png')) {
        final pixels = (await frame.image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        for (final offset in [
          0,
          (frame.image.width - 1) * 4,
          (frame.image.height - 1) * frame.image.width * 4,
          (frame.image.height * frame.image.width - 1) * 4,
        ]) {
          for (var channel = 0; channel < 4; channel++) {
            expect(
              pixels.getUint8(offset + channel),
              greaterThanOrEqualTo(248),
              reason: '$asset should have an opaque white background',
            );
          }
        }
      }
      frame.image.dispose();
      codec.dispose();
    }
  });

  test('item codes survive name formatting; related formulations never borrow photos', () {
    expect(
      productImageAsset(itemSeq: '202106092', name: '다른 표기의 서버 상품명'),
      '202106092.jpg',
    );
    expect(productImageAsset(itemSeq: '', name: '베아제 정'), '198700405.jpg');
    expect(productImageAsset(itemSeq: '202302993', name: '이지엔6이브정'), isEmpty);
    expect(
      productImageAsset(itemSeq: 'unknown', name: '타이레놀정650밀리그람'),
      isEmpty,
    );
    expect(productImageAsset(itemSeq: 'unknown', name: '후시딘연고'), isEmpty);
    expect(productImageAsset(itemSeq: '202401314', name: '화이투벤콜드시럽'), isEmpty);
  });

  test('OTC inventory has 21 products; missing photos never borrow approval medicine photos', () {
    final rows = jsonDecode(
      File('test/fixtures/otc_photo_inventory.json').readAsStringSync(),
    ) as List;
    expect(rows.length, 21);
    expect(rows.where((r) => r['has_photo'] == true).length, 21);
    for (final row in rows) {
      final image = productImageAsset(
        itemSeq: row['item_seq'] as String,
        name: row['item_name'] as String,
      );
      expect(
        image.isNotEmpty,
        row['has_photo'],
        reason: row['item_name'] as String,
      );
    }
  });

  testWidgets('unmapped OTC products use the uniform icon in list and cart', (
    tester,
  ) async {
    final api = MoyakApiClient(
      client: MockClient(
        (request) async => http.Response.bytes(
          utf8.encode(
            jsonEncode([
              {
                'id': 'mock-unmapped-product',
                'item_seq': 'mock-unmapped-code',
                'item_name': '사진 미등록 테스트 상품',
                'company': '테스트 제조사',
                'category': '상처/연고',
                'badge': '습윤 드레싱',
                'price': 6500,
                'stock': 11,
              },
            ]),
          ),
          200,
        ),
      ),
    );
    addTearDown(api.close);
    final backend = KioskBackend(
      api: api,
      machineId: 'mock',
      environment: 'mock',
      allowMutations: true,
    );
    final cart = LiveKioskCart(backend);
    addTearDown(cart.dispose);
    await tester.pumpWidget(
      MaterialApp(home: KioskProductListScreen(cart: cart)),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.medication_outlined), findsOneWidget);
    expect(find.text('사진 준비 중'), findsNothing);
    expect(cart.products.single.image, isEmpty);
    cart.add(0);
    await tester.pumpWidget(MaterialApp(home: KioskCartScreen(cart: cart)));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.medication_outlined), findsOneWidget);
    expect(find.text('사진 준비 중'), findsNothing);
    expect(cart.totalWon, 6500);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'live list shows verified photos while cart and server data stay unchanged',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = MoyakApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/vending/machines/test-machine/products');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode([
                {
                  'id': 'server-product-id',
                  'item_seq': '201708580',
                  'item_name': '겔포스엘현탁액',
                  'company': '보령',
                  'category': '소화/위장약',
                  'badge': null,
                  'price': 5500,
                  'stock': 7,
                },
              ]),
            ),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final backend = KioskBackend(
        api: api,
        machineId: 'test-machine',
        environment: 'mock',
        allowMutations: true,
      );
      final cart = LiveKioskCart(backend);
      addTearDown(cart.dispose);
      await tester.pumpWidget(
        MaterialApp(home: KioskProductListScreen(cart: cart)),
      );
      await tester.pumpAndSettle();
      final product = cart.products.single;
      expect(product.id, 'server-product-id');
      expect(product.price, 5500);
      expect(product.stock, 7);
      expect(product.image, '201708580.jpg');
      final imageFinder = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName ==
                'assets/products/201708580.jpg',
      );
      expect(imageFinder, findsOneWidget);
      expect(find.byIcon(Icons.medication_outlined), findsNothing);
      cart.add(0);
      await tester.pumpWidget(MaterialApp(home: KioskCartScreen(cart: cart)));
      await tester.pumpAndSettle();
      expect(imageFinder, findsNothing);
      expect(find.byIcon(Icons.medication_outlined), findsOneWidget);
      expect(cart.totalWon, 5500);
      expect(cart.productQuantities, {'server-product-id': 1});
      expect(tester.takeException(), isNull);
      final approved = LiveApprovedKioskCart(backend, 'mock-user', [
        KioskApprovedPurchase.fromJson({
          'id': 'approval-id',
          'user_id': 'mock-user',
          'drug_item_seq': '201708580',
          'drug_item_name': '겔포스엘현탁액',
          'status': 'pending',
          'price': 5500,
          'quantity': 1,
          'expires_at': '2099-01-01T00:00:00Z',
        }),
      ]);
      expect(approved.products.single.image, product.image);
      approved.dispose();
    },
  );
}
