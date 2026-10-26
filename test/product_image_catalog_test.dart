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
  test('all 21 mapped photos are included and decode successfully', () async {
    expect(productImageAssets.length, 21);
    for (final asset in productImageAssets.values.toSet()) {
      final bytes = await rootBundle.load('assets/products/$asset');
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThan(0), reason: asset);
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

  test('actual OTC seed has 21 products; missing 15 never borrow approval medicine photos', () {
    final rows = jsonDecode(
      File('test/fixtures/otc_photo_inventory.json').readAsStringSync(),
    ) as List;
    expect(rows.length, 21);
    expect(rows.where((r) => r['has_photo'] == true).length, 6);
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
                'id': 'otc-band',
                'item_seq': '901000004',
                'item_name': '메디폼 하이드로콜로이드 밴드 10매',
                'company': '먼디파마',
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
    'live list and cart hide available photos without changing server data',
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
      expect(imageFinder, findsNothing);
      expect(find.byIcon(Icons.medication_outlined), findsOneWidget);
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
