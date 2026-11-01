/// Local product photos, keyed by backend/MFDS item_seq, never array order.
/// Includes user-supplied display photos; see source notes for verification scope.
/// Sources and products still awaiting photos: docs/product_image_sources.md.
const productImageAssets = <String, String>{
  '196500043': 'band.png',
  '202101234': 'medifoam_h_beauty.jpg',
  '202209876': 'KF94 보건용 마스크.png',
  '199900001': 'mouthwash.png',
  '200300002': '알콜스왑.png',
  '200500003': '좋은느낌 생리대.jpg',
  '901000002': '아큐아뉴밴드.png',
  '901000003': 'children_band_white.png',
  '901000004': '메디폼 하이드로콜로이드 밴드 10매.png',
  '901000012': '소독용 에탄올 솜 200매.png',
  '901000021': '바세린 오리지널 50g.png',
  '901000022': '바세린 립테라피 7g.png',
  '901000031': 'lens_solution_white.png',
  '901000032': 'daily_disposable_lens_white.png',
  '901000033': '의료용 안대 1매.png',
  '901000042': '좋은느낌 대형 14매.png',
  '901000043': '좋은느낌 오버나이트 10매.png',
  '901000044': 'pantyliner_white.png',
  '901000052': 'KF80 보건용 마스크 소형.png',
  '901000053': 'dental_mask_white.png',
  '901000062': '가그린 레귤러 100ml (2).png',
  '196800036': '196800036.jpg',
  '197700120': '197700120.jpg',
  '198700405': '198700405.jpg',
  '199400202': '199400202.jpg',
  '199900926': '199900926.jpg',
  '200101057': '200101057.png',
  '200300547': '200300547.jpg',
  '200400116': '200400116.jpg',
  '200610765': '200610765.jpg',
  '200903973': '200903973.jpg',
  '200906478': '200906478.jpg',
  '201708580': '201708580.jpg',
  '201908295': '201908295.jpg',
  '202106092': '202106092.jpg',
  '202200658': '202200658.jpg',
};

const _exactProductNames = <String, String>{
  '대일밴드뉴표준형20매': 'band.png',
  '메디폼H뷰티': 'medifoam_h_beauty.jpg',
  'KF94보건용마스크': 'KF94 보건용 마스크.png',
  '리스테린구강청결제': 'mouthwash.png',
  '알콜스왑': '알콜스왑.png',
  '좋은느낌생리대': '좋은느낌 생리대.jpg',
  '대일밴드방수형10매': '아큐아뉴밴드.png',
  '대일밴드아쿠아뉴방수형밴드8매': '아큐아뉴밴드.png',
  '대일밴드어린이캐릭터15매': 'children_band_white.png',
  '메디폼하이드로콜로이드밴드10매': '메디폼 하이드로콜로이드 밴드 10매.png',
  '소독용에탄올솜200매': '소독용 에탄올 솜 200매.png',
  '바세린오리지널50g': '바세린 오리지널 50g.png',
  '바세린립테라피7g': '바세린 립테라피 7g.png',
  '콘택트렌즈다목적용액360ml': 'lens_solution_white.png',
  '일회용렌즈세정액15mlx5': 'daily_disposable_lens_white.png',
  '일회용렌즈세정액20mlx50A': 'daily_disposable_lens_white.png',
  '올데이-모이스처1팩일회용렌즈세정액10mlx25개': 'daily_disposable_lens_white.png',
  '일회용렌즈세정액10mlx25개': 'daily_disposable_lens_white.png',
  '의료용안대5매': '의료용 안대 1매.png',
  '의료용안대1매': '의료용 안대 1매.png',
  '좋은느낌대형14매': '좋은느낌 대형 14매.png',
  '좋은느낌오버나이트10매': '좋은느낌 오버나이트 10매.png',
  '순수한면팬티라이너40매': 'pantyliner_white.png',
  'KF80보건용마스크소형': 'KF80 보건용 마스크 소형.png',
  '일회용덴탈마스크50매': 'dental_mask_white.png',
  '가그린레귤러100ml': '가그린 레귤러 100ml (2).png',
  '판콜에이내복액': '196800036.jpg',
  '부루펜정200밀리그램(이부프로펜)': '197700120.jpg',
  '베아제정': '198700405.jpg',
  '판피린티정': '199400202.jpg',
  '훼스탈골드정': '199900926.jpg',
  '용각산쿨과립': '200101057.png',
  '후시딘히드로크림': '200300547.jpg',
  '모드콜시럽': '200400116.jpg',
  '지르텍정(세티리진염산염)': '200610765.jpg',
  '마데카솔케어연고': '200903973.jpg',
  '둘코락스에스장용정': '200906478.jpg',
  '겔포스엘현탁액': '201708580.jpg',
  '게보린소프트연질캡슐': '201908295.jpg',
  '타이레놀정500밀리그람(아세트아미노펜)': '202106092.jpg',
  '우먼스타이레놀정': '202200658.jpg',
};

String productImageAsset({required String itemSeq, required String name}) {
  final byCode = productImageAssets[itemSeq.trim()];
  if (byCode != null) return byCode;
  // Keep the existing six demo assets working without fuzzy drug-name matching.
  // Different dosage/forms must not borrow a similar brand's photo.
  return _exactProductNames[name.replaceAll(RegExp(r'\s+'), '')] ?? '';
}

/// User-corrected display label; order requests still use the server product ID.
/// This does not update the server catalog, price, stock or package metadata.
String productDisplayName({required String itemSeq, required String name}) {
  if (itemSeq.trim() == '901000032' &&
      const {
        '일회용렌즈세정액15mlx5',
        '일회용렌즈세정액20mlx50A',
        '올데이-모이스처1팩일회용렌즈세정액10mlx25개',
      }.contains(name.replaceAll(RegExp(r'\s+'), ''))) {
    return '일회용 렌즈 세정액 10ml x 25개';
  }
  if (itemSeq.trim() == '901000033' &&
      name.replaceAll(RegExp(r'\s+'), '') == '의료용안대5매') {
    return '의료용 안대 1매';
  }
  if (itemSeq.trim() == '901000002' &&
      name.replaceAll(RegExp(r'\s+'), '') == '대일밴드방수형10매') {
    return '대일밴드 아쿠아뉴 방수형 밴드 8매';
  }
  return name;
}

bool isFullProductPhoto(String filename) =>
    RegExp(r'^\d{9}\.(jpg|png)$').hasMatch(filename);

/// Some legacy demo photos show a different brand, variant or manufacturer.
/// Keep the historical mapping for data compatibility, but do not display them.
String verifiedProductPhotoAsset({
  required String itemSeq,
  required String name,
}) {
  final asset = productImageAsset(itemSeq: itemSeq, name: name);
  const mismatchedLegacyPhotos = {
    'medifoam.png', // Active Beauty, not H Beauty.
    'mask.png', // MIMA, not Clean & Science.
    'swab.png', // Different manufacturer from the catalog.
    'pad.png', // Different manufacturer from the catalog.
  };
  return mismatchedLegacyPhotos.contains(asset) ? '' : asset;
}
