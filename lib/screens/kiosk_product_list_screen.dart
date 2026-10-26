import '../widgets/kiosk_viewport.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../demo/demo_products.dart';
import '../demo/demo_cart.dart';
import 'kiosk_cart_screen.dart';
import 'kiosk_payment_screen.dart';
import '../services/kiosk_backend.dart';

class KioskProductListScreen extends StatefulWidget {
  const KioskProductListScreen({
    super.key,
    this.cart,
    this.showMember = false,
    this.onLogout,
  });
  final DemoCart? cart;
  final bool showMember;
  final VoidCallback? onLogout;

  @override
  State<KioskProductListScreen> createState() => _KioskProductListScreenState();
}

class _KioskProductListScreenState extends State<KioskProductListScreen> {
  static const _background = Color(0xFFFFFDE7);
  static const _plate = Color(0xFFFFF8E1);
  static const _border = Color(0xFFFFF3C4);
  static const _yellow = Color(0xFFFFD54F);
  static const _brown = Color(0xFF593D0D);
  static const _gold = Color(0xFF8B6914);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF475569);
  static const _tabs = [
    '전체',
    '진통/해열제',
    '소화/위장약',
    '감기약/기침약',
    '상처/연고',
    '안대/밴드/기타',
  ];
  List<DemoProduct> get _products => _cart.products;
  final _search = TextEditingController();
  // Reproduce Figma's example selection (swab + Medifoam = 7,000 won).
  late final DemoCart _cart;
  Map<int, int> get _selected => _cart.quantities;
  int _category = 0;

  @override
  void initState() {
    super.initState();
  }

  bool _initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final backend = KioskBackendScope.maybeOf(context);
    _cart =
        widget.cart ?? (backend == null ? DemoCart() : LiveKioskCart(backend));
    _cart.addListener(_refreshCart);
    if (_cart is LiveKioskCart) {
      Future.microtask(_loadAndRecover);
    }
  }

  void _refreshCart() => setState(() {});

  bool _recovering = false;
  Future<void> _loadAndRecover() async {
    if (!mounted || _cart is! LiveKioskCart || _recovering) return;
    final live = _cart;
    await live.load();
    if (!mounted ||
        live.order == null ||
        live.uncertain ||
        live.backend.orderError != null) {
      return;
    }
    _recovering = true;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KioskPaymentScreen(
          cart: live,
          showMember: widget.showMember,
          onLogout: widget.onLogout,
        ),
      ),
    );
    _recovering = false;
    if (mounted && live.order == null && !live.uncertain) await live.load();
  }

  void _openCart() {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (cartContext) => KioskCartScreen(
          cart: _cart,
          showMember: widget.showMember,
          onLogout: widget.onLogout == null
              ? null
              : () {
                  _cart.clear();
                  widget.onLogout!();
                },
          onAddProducts: () => Navigator.of(cartContext).pop(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cart.removeListener(_refreshCart);
    if (widget.cart == null) _cart.dispose();
    _search.dispose();
    super.dispose();
  }

  TextStyle _style(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = _ink,
  }) => TextStyle(
    fontFamily: 'MenuInter',
    fontFamilyFallback: const ['MenuKorean'],
    fontSize: kioskFontSize(size),
    fontWeight: weight,
    color: color,
    height: 1.2,
  );

  Widget _text(
    String text,
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = _ink,
  }) => Text(
    text,
    style: _style(size, weight: weight, color: color),
    maxLines: 1,
    softWrap: false,
  );

  Widget _slot(double x, double y, double width, double height, Widget child) =>
      Positioned(
        left: x,
        top: y,
        width: width,
        height: height,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: child,
        ),
      );

  BoxDecoration _decoration({
    Color color = _plate,
    double radius = 16,
    double opacity = 0.05,
    double blur = 50,
    double dy = 10,
  }) => BoxDecoration(
    color: color,
    border: Border.all(color: _border),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: opacity),
        offset: Offset(0, dy),
        blurRadius: blur,
      ),
    ],
  );

  void _message(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  String _normalize(String value) =>
      value.replaceAll(RegExp(r'\s+'), '').toLowerCase();

  String _money(int value) =>
      '${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}원';

  @override
  Widget build(BuildContext context) {
    final visible = List<int>.generate(_products.length, (index) => index)
        .where((index) {
          final product = _products[index];
          return (_category == 0 || product.categories.contains(_category)) &&
              _normalize('${product.name}${product.badge}')
                  .contains(_normalize(_search.text));
        })
        .toList();
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: KioskViewport(
          child: KioskCanvas(
            children: [
              const Positioned.fill(child: ColoredBox(color: _background)),
              Positioned(
                left: 0,
                top: 0,
                width: 1080,
                height: 204,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: _border)),
                  ),
                ),
              ),
              Positioned(
                left: 55,
                top: 57,
                width: 91,
                height: 30,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _yellow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              _slot(
                65,
                61,
                71,
                22,
                _text('모두의 약', 18, weight: FontWeight.w800, color: _brown),
              ),
              _slot(158, 55, 52, 34, _text('모약', 28, weight: FontWeight.w800)),
              _slot(
                55,
                95,
                230,
                48,
                _text('의약외품 목록', 40, weight: FontWeight.w800),
              ),
              _slot(
                338,
                104.5,
                365,
                29,
                _text(
                  '|  처방전 없이 즉시 구매 가능한 약품',
                  24,
                  weight: FontWeight.w400,
                  color: _muted,
                ),
              ),
              Positioned(
                left: 917,
                top: 79,
                width: 133,
                height: 51,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              _slot(
                941,
                91,
                61,
                27,
                _text('한국어', 22, weight: FontWeight.w600, color: _muted),
              ),
              Positioned(
                left: 1010,
                top: 96.5,
                width: 16,
                height: 16,
                child: SvgPicture.asset('assets/menu/chevron.svg'),
              ),
              Positioned(
                left: 64,
                top: 346,
                width: 952,
                height: 80,
                child: DecoratedBox(
                  decoration: _decoration(
                    color: Colors.white,
                    opacity: 0.1,
                    blur: 4,
                    dy: 4,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 24),
                      SvgPicture.asset(
                        'assets/products/search.svg',
                        width: 32,
                        height: 32,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: TextField(
                          key: const ValueKey('product-search'),
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          style: _style(26),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '필요한 제품을 검색해 보세요 (예: 밴드, 거즈, 마스크)',
                            hintStyle: _style(
                              26,
                              weight: FontWeight.w400,
                              color: const Color(0xFF94A3B8),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 64,
                top: 482,
                width: 952,
                height: 67,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var index = 0; index < _tabs.length; index++) ...[
                        if (index > 0) const SizedBox(width: 16),
                        SizedBox(
                          width: [
                            97.0,
                            166.0,
                            166.0,
                            187.0,
                            146.0,
                            195.0,
                          ][index],
                          height: 67,
                          child: Material(
                            color: _category == index ? _yellow : _plate,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _category == index ? _yellow : _border,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: ValueKey('product-category-$index'),
                              onTap: () => setState(() => _category = index),
                              child: Semantics(
                                selected: _category == index,
                                button: true,
                                child: Center(
                                  child: _text(
                                    _tabs[index],
                                    22,
                                    weight: FontWeight.w700,
                                    color: _muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 64,
                top: 581,
                width: 952,
                height: 836,
                child:
                    _cart is LiveKioskCart &&
                        ((_cart).busy || (_cart).error != null)
                    ? Center(
                        child: Text(
                          (_cart).busy ? '상품 정보를 불러오는 중입니다…' : (_cart).error!,
                          style: _style(26),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : visible.isEmpty
                    ? Center(child: _text('검색 결과가 없습니다.', 26, color: _muted))
                    : GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 24,
                              crossAxisSpacing: 24,
                              mainAxisExtent: 500,
                            ),
                        itemCount: visible.length,
                        itemBuilder: (_, slot) => _card(visible[slot]),
                      ),
              ),
              _summary(),
              Positioned(
                left: 0,
                top: 1758,
                width: 1080,
                height: 162,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: _border)),
                  ),
                ),
              ),
              Positioned(
                left: 64,
                top: 1798,
                width: 224,
                height: 82,
                child: _button(
                  'previous-screen',
                  () => Navigator.of(context).pop(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/products/back.svg',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 16),
                      _text('이전으로', 28, weight: FontWeight.w700),
                    ],
                  ),
                  color: _plate,
                  radius: 16,
                  border: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(
    String key,
    VoidCallback onTap,
    Widget child, {
    Color color = _yellow,
    double radius = 8,
    bool border = false,
  }) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          offset: Offset(0, 4),
          blurRadius: 8,
        ),
      ],
    ),
    child: Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(
          color: border ? _border : Colors.transparent,
          width: border ? 2 : 0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey(key),
        onTap: onTap,
        child: Center(child: child),
      ),
    ),
  );

  Widget _card(int index) {
    final product = _products[index];
    const image = Icon(Icons.medication_outlined, size: 88, color: _gold);
    return DecoratedBox(
      decoration: _decoration(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('product-card-$index'),
          onTap: () => _message(
            _cart is LiveKioskCart
                ? '${product.name}\n${product.company} · 품목코드 ${product.itemSeq}\n단가 ${product.priceLabel} · 재고 ${product.stock}개\n효능·용법 등 상세 정보 API는 아직 제공되지 않습니다.'
                : '예시 제품 선택: ${product.name}',
          ),
          child: Stack(
            children: [
              Positioned(
                left: 45,
                top: 12,
                width: 211,
                height: 204,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: image,
                ),
              ),
              _slot(
                36,
                228,
                230,
                28,
                _text(product.badge, 16, weight: FontWeight.w700, color: _gold),
              ),
              Positioned(
                left: 24,
                top: 270,
                width: 253.333,
                height: 116,
                child: Text(
                  product.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: _style(30, weight: FontWeight.w800),
                ),
              ),
              _slot(
                24,
                410,
                150,
                42,
                _text(
                  product.priceLabel,
                  34,
                  weight: FontWeight.w800,
                  color: _gold,
                ),
              ),
              Positioned(
                left: 184,
                top: 398,
                width: 104,
                height: 78,
                child: _button(
                  'add-product-$index',
                  () {
                    try {
                      _cart.add(index);
                    } on ArgumentError {
                      _message('현재 재고 수량을 초과할 수 없습니다.');
                      return;
                    }
                    _message(
                      '${_cart is LiveKioskCart ? '제품' : '예시 제품'} 담기: ${product.name}',
                    );
                  },
                  _text(
                    product.stock == 0 ? '품절' : '담기',
                    26,
                    weight: FontWeight.w700,
                    color: _brown,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary() {
    final count = _selected.values.fold(
      0,
      (total, quantity) => total + quantity,
    );
    final total = _selected.entries.fold(
      0,
      (sum, entry) => sum + _products[entry.key].price * entry.value,
    );
    final name = count == 0
        ? '선택한 약품 없음'
        : '${_products[_selected.keys.first].name}${count > 1 ? '외 ${count - 1}건' : ''}';
    return Positioned(
      left: 64,
      top: 1504,
      width: 952,
      height: 143,
      child: DecoratedBox(
        decoration: _decoration(radius: 24, opacity: 0.15, blur: 20, dy: 4),
        child: Stack(
          children: [
            Positioned(
              left: 32,
              top: 39.5,
              width: 64,
              height: 64,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _yellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: SvgPicture.asset('assets/products/bag.svg'),
                ),
              ),
            ),
            _slot(
              120,
              38,
              269,
              29,
              _text(
                '선택한 약품',
                24,
                weight: FontWeight.w600,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            _slot(
              120,
              71,
              280,
              34,
              _text(name, 28, weight: FontWeight.w800, color: _brown),
            ),
            _slot(
              479,
              35.5,
              80,
              24,
              _text(
                '합계 금액',
                20,
                weight: FontWeight.w400,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            _slot(
              422,
              63.5,
              137,
              44,
              _text(_money(total), 36, weight: FontWeight.w800, color: _gold),
            ),
            Positioned(
              left: 599,
              top: 32,
              width: 321,
              height: 79,
              child: _button(
                'complete-selection',
                _openCart,
                _text(
                  '선택 완료 (결제하기)',
                  26,
                  weight: FontWeight.w800,
                  color: _brown,
                ),
                radius: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
