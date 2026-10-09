import 'package:flutter/foundation.dart';

import 'demo_products.dart';

/// In-memory UI examples only. Never represents backend stock or purchases.
class DemoCart extends ChangeNotifier {
  DemoCart({Map<int, int> quantities = const {4: 1, 1: 1}}) {
    for (final entry in quantities.entries) {
      if (entry.key < 0 ||
          entry.key >= demoProducts.length ||
          entry.value <= 0) {
        throw ArgumentError('Invalid demo cart line');
      }
      _quantities[entry.key] = entry.value;
    }
  }

  final Map<int, int> _quantities = {};
  Map<int, int> get quantities => Map.unmodifiable(_quantities);
  int get totalQuantity =>
      _quantities.values.fold(0, (sum, value) => sum + value);
  int get totalWon => _quantities.entries.fold(
    0,
    (sum, entry) => sum + demoProducts[entry.key].price * entry.value,
  );

  void add(int index) {
    if (index < 0 || index >= demoProducts.length) {
      throw RangeError.index(index, demoProducts);
    }
    _quantities.update(index, (quantity) => quantity + 1, ifAbsent: () => 1);
    notifyListeners();
  }

  void remove(int index) {
    if (_quantities.remove(index) != null) notifyListeners();
  }

  void clear() {
    _quantities.clear();
    notifyListeners();
  }
}
