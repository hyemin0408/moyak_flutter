/// App-side values, not backend JSON schemas. API adapters will map wire DTOs
/// into these values once the actual specification is available.
class KioskDevice {
  const KioskDevice({required this.id});
  final String id;
}

enum PairingStatus { pending, connected, expired, rejected }

class DevicePairing {
  const DevicePairing({required this.id, required this.status});
  final String id;
  final PairingStatus status;
}

enum VerificationStatus { pending, verified, rejected, expired }

class IdentityVerification {
  const IdentityVerification({required this.id, required this.status});
  final String id;
  final VerificationStatus status;
}

class MemberSummary {
  const MemberSummary({required this.id, required this.displayName});
  final String id;
  final String displayName;
}

class CatalogQuery {
  const CatalogQuery({this.searchText = '', this.categoryId});
  final String searchText;
  final String? categoryId;
}

class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.name,
    required this.priceWon,
    this.categoryId,
    this.imageUri,
  });
  final String id;
  final String name;

  /// Integer KRW amount. UI display labels belong outside the service.
  final int priceWon;
  final String? categoryId;
  final Uri? imageUri;
}

class ProductInventory {
  const ProductInventory({
    required this.productId,
    required this.availableQuantity,
  });
  final String productId;
  final int availableQuantity;
}

class CartLine {
  const CartLine({required this.productId, required this.quantity});
  final String productId;
  final int quantity;
}

class CartSnapshot {
  CartSnapshot({
    required this.id,
    required Iterable<CartLine> lines,
    required this.totalWon,
  }) : lines = List.unmodifiable(lines);
  final String id;
  final List<CartLine> lines;

  /// Must come from the backend, not the UI's example price calculation.
  final int totalWon;
}

class PurchaseRequest {
  const PurchaseRequest({required this.cartId});
  final String cartId;
}

enum PurchaseStatus { pending, completed, rejected }

class PurchaseSummary {
  const PurchaseSummary({required this.id, required this.status});
  final String id;
  final PurchaseStatus status;
}
