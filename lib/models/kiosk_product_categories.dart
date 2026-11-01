/// Kiosk browsing groups only, not a regulatory or medical classification.
/// IDs 4 and 5 retain compatibility with existing UI/cart data.
List<int> kioskProductCategories({
  required String itemSeq,
  required String name,
  required String serverCategory,
  String badge = '',
}) {
  const groups = <String, int>{
    '196500043': 5, // Standard bandage.
    '202101234': 4, // Medifoam H Beauty.
    '202209876': 5, // KF94 mask.
    '199900001': 5, // Mouthwash.
    '200300002': 4, // Alcohol swabs.
    '200500003': 6, // Sanitary pads.
    '901000002': 5, // Waterproof bandage.
    '901000003': 5, // Children's bandage.
    '901000004': 4, // Medifoam dressing.
    '901000021': 5, // Moisturizer.
    '901000022': 5, // Lip care.
    '901000031': 5, // Lens solution.
    '901000032': 5, // Disposable lens solution.
    '901000033': 5, // Eye patch.
    '901000042': 6, // Large pads.
    '901000043': 6, // Overnight pads.
    '901000044': 6, // Pantyliners.
    '901000052': 5, // KF80 mask.
    '901000053': 5, // Disposable mask.
    '901000062': 5, // Mouthwash.
  };
  final known = groups[itemSeq.trim()];
  if (known != null) return [known];
  // New women's products should not silently stay in the generic group.
  if (serverCategory == '여성용품' ||
      badge == '여성용품' ||
      RegExp(r'생리대|팬티라이너|오버나이트').hasMatch(name)) {
    return [6];
  }
  return [serverCategory == '상처/연고' ? 4 : 5];
}
