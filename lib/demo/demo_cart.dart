import 'package:flutter/foundation.dart';

import 'demo_products.dart';

/// In-memory UI examples only. Never represents backend stock or purchases.
class DemoCart extends ChangeNotifier {
  DemoCart({
    Map<int, int> quantities = const {4: 1, 1: 1},
    List<DemoProduct> products = demoProducts,
    Map<int, int>? approvedLimits,
  }) : _products = List.unmodifiable(products),
       approvedLimits = approvedLimits == null
           ? null
           : Map.unmodifiable(approvedLimits) {
    if (this.approvedLimits?.entries.any(
          (entry) =>
              entry.key < 0 || entry.key >= products.length || entry.value <= 0,
        ) ??
        false) {
      throw ArgumentError('Invalid example approval');
    }
    for (final entry in quantities.entries) {
      if (entry.key < 0 ||
          entry.key >= products.length ||
          entry.value <= 0 ||
          (this.approvedLimits != null &&
              entry.value > (this.approvedLimits![entry.key] ?? 0))) {
        throw ArgumentError('Invalid demo cart line');
      }
      _quantities[_id(entry.key)] = entry.value;
    }
  }

  final Map<String, int> _quantities = {};
  List<DemoProduct> _products;
  List<DemoProduct> get products => _products;
  String _id(int index) => products[index].id ?? 'demo-$index';
  Map<String, int> get productQuantities => Map.unmodifiable(_quantities);
  void replaceProducts(List<DemoProduct> values) {
    final ids = values.map((p) => p.id).toList();
    if (ids.any((id) => id == null || id.isEmpty) ||
        ids.toSet().length != ids.length) {
      throw ArgumentError('Invalid server product identities');
    }
    _products = List.unmodifiable(values);
    _quantities.removeWhere((id, _) => !ids.contains(id));
    for (final p in products) {
      final q = _quantities[p.id];
      if (q != null && p.stock != null && q > p.stock!) {
        if (p.stock == 0) {
          _quantities.remove(p.id);
        } else {
          _quantities[p.id!] = p.stock!;
        }
      }
    }
    notifyListeners();
  }

  /// Example-only authorizations, never proof of real pharmacist approval.
  final Map<int, int>? approvedLimits;
  bool get isApprovalRestricted => approvedLimits != null;
  // Compatibility view for existing card layouts; identity/storage uses IDs.
  Map<int, int> get quantities => Map.unmodifiable({
    for (var i = 0; i < products.length; i++)
      if (_quantities.containsKey(_id(i))) i: _quantities[_id(i)]!,
  });
  int get totalQuantity =>
      _quantities.values.fold(0, (sum, value) => sum + value);
  int get totalWon => _quantities.entries.fold(
    0,
    (sum, entry) =>
        sum +
        products
                .firstWhere(
                  (p) => (p.id ?? 'demo-${products.indexOf(p)}') == entry.key,
                )
                .price *
            entry.value,
  );

  void add(int index) {
    setQuantity(index, (_quantities[_id(index)] ?? 0) + 1);
  }

  void setQuantity(int index, int quantity) {
    if (index < 0 || index >= products.length) {
      throw RangeError.index(index, products);
    }
    if (quantity < 1 ||
        (products[index].stock != null && quantity > products[index].stock!) ||
        (approvedLimits != null && quantity > (approvedLimits![index] ?? 0))) {
      throw ArgumentError('Quantity exceeds example approval or is invalid');
    }
    if (_quantities[_id(index)] == quantity) return;
    _quantities[_id(index)] = quantity;
    notifyListeners();
  }

  void remove(int index) {
    if (_quantities.remove(_id(index)) != null) notifyListeners();
  }

  void clear() {
    _quantities.clear();
    notifyListeners();
  }
}
