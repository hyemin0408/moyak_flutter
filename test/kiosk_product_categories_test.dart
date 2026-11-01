import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moyak_flutter/models/kiosk_product_categories.dart';
import 'package:moyak_flutter/services/kiosk_backend.dart';
import 'package:moyak_flutter/services/moyak_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final rows = (jsonDecode(
    File('test/fixtures/otc_photo_inventory.json').readAsStringSync(),
  ) as List).cast<Map<String, dynamic>>();

  test(
    'all 20 visible catalog products have exactly one appropriate group',
    () {
      const expected = {
        4: {'202101234', '200300002', '901000004'},
        5: {
          '196500043',
          '202209876',
          '199900001',
          '901000002',
          '901000003',
          '901000021',
          '901000022',
          '901000031',
          '901000032',
          '901000033',
          '901000052',
          '901000053',
          '901000062',
        },
        6: {'200500003', '901000042', '901000043', '901000044'},
      };
      final actual = <int, Set<String>>{4: {}, 5: {}, 6: {}};
      for (final row in rows.where((r) => r['item_seq'] != '901000012')) {
        final code = row['item_seq'] as String;
        // Outdated server grouping must not put mouthwash or pads into wounds.
        final categories = kioskProductCategories(
          itemSeq: code,
          name: row['item_name'] as String,
          serverCategory: '상처/연고',
        );
        expect(categories.length, 1);
        actual[categories.single]!.add(code);
      }
      expect(actual, expected);
    },
  );

  test('future women products and unknown products stay reachable', () {
    expect(
      kioskProductCategories(
        itemSeq: 'new',
        name: '새 팬티라이너',
        serverCategory: '안대/밴드/기타',
      ),
      [6],
    );
    expect(
      kioskProductCategories(
        itemSeq: 'new',
        name: '새 상품',
        serverCategory: '여성용품',
      ),
      [6],
    );
    expect(
      kioskProductCategories(
        itemSeq: 'new',
        name: '새 상품',
        serverCategory: '알 수 없는 분류',
      ),
      [5],
    );
  });

  test(
    'live catalog applies categories and short name without changing sale data',
    () async {
      final api = MoyakApiClient(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/vending/machines/mock/products');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode([
                for (var i = 0; i < rows.length; i++)
                  {
                    ...rows[i],
                    'id': 'server-${rows[i]['item_seq']}',
                    'category': '상처/연고',
                    'badge': null,
                    'price': 1000 + i,
                    'stock': 10 + i,
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
        machineId: 'mock',
        environment: 'mock-only',
        allowMutations: true,
      );
      final cart = LiveKioskCart(backend);
      addTearDown(cart.dispose);
      expect(await cart.load(), isTrue);
      expect(cart.products.length, 20);
      expect(cart.products.where((p) => p.categories.contains(4)).length, 3);
      expect(cart.products.where((p) => p.categories.contains(5)).length, 13);
      expect(cart.products.where((p) => p.categories.contains(6)).length, 4);
      expect(
        cart.products.singleWhere((p) => p.itemSeq == '901000032').name,
        '일회용 렌즈 세정액 10ml x 25개',
      );
      final index = cart.products.indexWhere((p) => p.itemSeq == '200500003');
      expect(cart.products[index].price, 1005);
      expect(cart.products[index].stock, 15);
      cart.add(index);
      expect(cart.productQuantities, {'server-200500003': 1});
      expect(cart.totalWon, 1005);
    },
  );
}
