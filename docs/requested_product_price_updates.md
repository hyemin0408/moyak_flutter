# 요청된 서버 상품 가격 변경 (2026-11-01)

사진은 Flutter에 반영했다. 가격은 서버의 상품 조회/주문 금액이 일치해야 하므로
프론트에 하드코딩하지 않았고 DB/서버 변경 요청을 실행하지 않았다.

| 프론트 목록 번호 | products.item_seq | 요청 단가 |
|---|---|---|
| 11 | 901000032 | 12,800원 |
| 12 | 901000033 | 1,500원 |

현재 키오스크 상품/주문 라우터는 조회·주문·취소·결제·배출만 제공하고 가격 수정용
관리 API는 없다. 주문 생성은 서버 `products.price`로 단가/합계를 계산한다.

- [백엔드 상품/주문 라우터](https://github.com/JONGBOK1/moyak-backend/blob/master/src/api/routes/shop.py)
- [백엔드 주문 처리](https://github.com/JONGBOK1/moyak-backend/blob/master/src/consult/shop.py)
- [상품 시드](https://github.com/JONGBOK1/moyak-backend/blob/master/scripts/seed_kiosk_products.py)

담당자는 실제 주문용 DB의 `products` 테이블에서 승인된 대상 기기 code와 위
item_seq 두 항목을 함께 확인한 뒤 `price`만 변경해야 한다. 다른 기기까지 적용할지는
별도 확인이 필요하다. ID/stock/기존 주문 항목 단가/합계는 변경하지 않는다.
`seed_kiosk_products.py --apply`는 다른 상품 가격과 재고까지 수정하므로 이 목적에 실행하지 않는다.
서버 값이 바뀌면 기존 상품 API 로딩만으로 새 가격이 표시되고 합계에 반영된다.

## 담당자 검토용 SQL (실행하지 않음)

`:machine_code`는 승인된 실제 대상 기기 code를 바인딩하는 자리다. 프론트에서 임의로
채우지 않았다. 아래는 트랜잭션 안에서 변경 결과를 보고 되돌리는 검토용 예시다.
담당자는 조회 결과가 정확히 두 상품인지, 새 판매 단위와 단가가 맞는지 확인한 뒤
승인된 환경에서만 실제 반영해야 한다. 기존 주문 금액은 수정하지 않는다.

```sql
BEGIN;
SELECT id, machine_id, item_seq, item_name, price, stock
FROM products
WHERE machine_id = :machine_code
  AND item_seq IN ('901000032', '901000033')
FOR UPDATE;

UPDATE products
SET price = CASE item_seq
  WHEN '901000032' THEN 12800
  WHEN '901000033' THEN 1500
END
WHERE machine_id = :machine_code
  AND item_seq IN ('901000032', '901000033')
RETURNING id, machine_id, item_seq, item_name, price, stock;
ROLLBACK;
```

사진과 현재 데이터의 포장 규격 차이도 확인해야 한다.
11번 새 사진/파일은 올데이-모이스처 10ml x25개(현재 표시명 20ml x50A),
12번 새 사진은 안대 1매(현재 표시명 5매)다.
이번 요청은 사진·가격 교체이며 상품명 변경을 별도로 지시하지 않아 기존 표시명을 유지했다.
정확한 실제 판매 상품·단가 기준·포장 단위를 백엔드에서 함께 확인해야 한다.
