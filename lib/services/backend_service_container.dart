import 'backend_services.dart';

/// Explicit injection point for future live adapters. No demo fallback.
/// Unconfigured capabilities stay null; callers must not treat them as success.
class BackendServices {
  const BackendServices({
    this.device,
    this.identity,
    this.member,
    this.catalog,
    this.purchase,
  });
  final KioskDeviceService? device;
  final IdentityService? identity;
  final MemberService? member;
  final CatalogService? catalog;
  final PurchaseService? purchase;
}
