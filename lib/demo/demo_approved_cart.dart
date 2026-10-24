import 'demo_cart.dart';
import 'demo_products.dart';

/// Screenshot-only examples. No live approval, stock, identity, or sale data.
/// Original product images are unavailable; the UI must use labeled placeholders.
const demoApprovedProducts = [
  DemoProduct('타이레놀정 500mg (8정)', '진통/해열', 3500, '3,500원', '', [], 0, 0),
  DemoProduct('그날엔 큐', '두통/생리통', 3000, '3,000원', '', [], 0, 0),
];

DemoCart createDemoApprovedCart() => DemoCart(
  products: demoApprovedProducts,
  quantities: const {0: 1, 1: 2},
  approvedLimits: const {0: 1, 1: 2},
);
