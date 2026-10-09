import '../models/backend_models.dart';
import 'service_result.dart';

/// Proposed app-side boundaries, not API endpoints. No transport is connected.
/// Concrete adapters and wire DTOs wait for a real backend specification.
abstract interface class KioskDeviceService {
  Future<ServiceResult<KioskDevice>> identifyDevice();
  Future<ServiceResult<DevicePairing>> beginPairing(String deviceId);
  Future<ServiceResult<DevicePairing>> checkPairing(String pairingId);
}

abstract interface class IdentityService {
  Future<ServiceResult<IdentityVerification>> checkVerification(
    String pairingId,
  );
}

abstract interface class MemberService {
  Future<ServiceResult<MemberSummary>> getCurrentMember();
}

abstract interface class CatalogService {
  Future<ServiceResult<List<CatalogProduct>>> getProducts(CatalogQuery query);
  Future<ServiceResult<List<ProductInventory>>> getInventory(String deviceId);
}

abstract interface class PurchaseService {
  Future<ServiceResult<CartSnapshot>> getCart();
  Future<ServiceResult<CartSnapshot>> updateCartLine(CartLine line);
  Future<ServiceResult<PurchaseSummary>> submitPurchase(
    PurchaseRequest request,
  );
}
