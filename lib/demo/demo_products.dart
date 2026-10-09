/// Design-only examples from Figma 86:81. These are not live sale or stock data.
class DemoProduct {
  const DemoProduct(
    this.name,
    this.badge,
    this.price,
    this.priceLabel,
    this.image,
    this.categories,
    this.imageX,
    this.imageY,
  );
  final String name, badge, priceLabel, image;
  final int price;
  final List<int> categories;
  final double imageX, imageY;
}

const demoProducts = [
  DemoProduct(
    '대일밴드 뉴 표준형 20매',
    '상처 보호',
    3500,
    '3,500원',
    'band.png',
    [4, 5],
    45,
    12,
  ),
  DemoProduct(
    '메디폼 H뷰티',
    '상처 보호',
    4000,
    '4,000원',
    'medifoam.png',
    [4],
    44.667,
    12,
  ),
  DemoProduct(
    'KF94 보건용 마스크',
    '마스크',
    3800,
    '3,800원',
    'mask.png',
    [5],
    44.333,
    12,
  ),
  DemoProduct(
    '리스테린 구강청결제',
    '구강 위생',
    6000,
    '6,000원',
    'mouthwash.png',
    [5],
    50,
    0,
  ),
  DemoProduct('알콜스왑', '소독용품', 3000, '3,000원', 'swab.png', [4, 5], 44.667, 0),
  DemoProduct('좋은느낌 생리대', '여성용품', 4000, '4.000원', 'pad.png', [5], 33.333, 0),
];
