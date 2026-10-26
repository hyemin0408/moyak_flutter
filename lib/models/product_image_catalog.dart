/// Verified local photos, keyed by the backend/MFDS item_seq, never array order.
/// Sources and products still awaiting photos: docs/product_image_sources.md.
const productImageAssets = <String, String>{
  '196500043': 'band.png',
  '202101234': 'medifoam.png',
  '202209876': 'mask.png',
  '199900001': 'mouthwash.png',
  '200300002': 'swab.png',
  '200500003': 'pad.png',
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
  '메디폼H뷰티': 'medifoam.png',
  'KF94보건용마스크': 'mask.png',
  '리스테린구강청결제': 'mouthwash.png',
  '알콜스왑': 'swab.png',
  '좋은느낌생리대': 'pad.png',
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

bool isFullProductPhoto(String filename) =>
    RegExp(r'^\d{9}\.(jpg|png)$').hasMatch(filename);
