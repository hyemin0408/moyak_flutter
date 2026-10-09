import 'package:flutter_test/flutter_test.dart';
import 'package:moyak_flutter/models/backend_models.dart';
import 'package:moyak_flutter/services/backend_service_container.dart';

void main() {
  test('No backend capability or demo fallback is enabled by default', () {
    const services = BackendServices();
    expect(services.device, isNull);
    expect(services.identity, isNull);
    expect(services.member, isNull);
    expect(services.catalog, isNull);
    expect(services.purchase, isNull);
  });

  test(
    'Cart snapshot owns immutable lines independently of caller changes',
    () {
      final source = [const CartLine(productId: 'example', quantity: 1)];
      final snapshot = CartSnapshot(
        id: 'test-cart',
        lines: source,
        totalWon: 100,
      );
      source.clear();
      expect(snapshot.lines.single.quantity, 1);
      expect(() => snapshot.lines.clear(), throwsUnsupportedError);
    },
  );
}
