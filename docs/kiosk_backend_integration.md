# 기존 키오스크 화면의 백엔드 연결

## 위치 이름으로 설치 기기 선택 (2026-10-26)

현재 정상 실행은 Android에 저장된 설치 기기 설정을 먼저 읽습니다.
저장값이 없으면 최초 1회 설치 담당자가 `/api/v1/map/machines`의 위치 이름·주소·코드를
확인하고 선택해야 시작 화면으로 진행합니다. 위치 목록 조회는 읽기 전용입니다.
지도 UUID가 아닌 `code`를 기존 상품·주문·QR API에 전달합니다.

`MOYAK_MACHINE_ID` 빌드 값으로 자동 선택하던 방식은 최초 위치 선택으로 대체됐습니다.
아래 문서의 과거 실행 명령에 해당 값이 있어도 현재 정상 실행은 저장된 선택값을 사용합니다.
서버 주소별로 설정을 분리 저장하며, 설정 읽기/저장 실패 시 구매 흐름으로 진행하지 않습니다.
다음 실행에서는 저장된 위치를 사용하므로 다시 목록을 조회할 필요가 없습니다.
시작 화면 오른쪽 아래 `기기 설정` → 설치 담당자 확인 → 위치 선택으로 재지정할 수 있습니다.
뒤로 가기는 변경 없이 기존 시작 화면으로 돌아갑니다. 저장 후에는 이전 Navigator 및 API
클라이언트를 교체하여 이전 기기의 화면/장바구니/연동 상태가 섞이지 않도록 합니다.
고객 구매 도중 변경하는 메뉴는 제공하지 않습니다. 장바구니, 처리 중 요청, 연동 회원,
진행 중/미확인 주문, 현재/대상 기기의 주문 복구 기록이 있거나 기록을 읽지 못하면 변경을 막습니다.
이 검사는 로컬 기록 기준이며 서버의 미확인 주문 부재나 다른 키오스크의 세션 부재를 보증하지 않습니다.
설치 담당자 확인 문구는 접근 인증 기능이 아닙니다. 실제 운영자 권한 인증은 추후 연결해야 합니다.
주문 복구 기록을 지우기 위한 앱 데이터 초기화는 권장하지 않습니다.

지도 목록은 위치 등록만 확인합니다. 주문 DB의 등록·판매 가능 여부와 실제 테스트 사용
승인은 별도 확인해야 합니다. 기기 선택으로 주문/세션/QR API를 호출하지 않습니다.
기존 `MOYAK_TEST_ENVIRONMENT`와 `MOYAK_ALLOW_SERVER_MUTATIONS` 차단 조건은 그대로 유지됩니다.
테스트 환경 이름만으로 사용 승인을 보증하지 않으며, 다른 기기를 시험하려고 임의로 선택하지 않습니다.

변경된 APK 빌드 예시(서버 변경 허용 여부는 운영자 승인 범위에 맞춰 지정):

```powershell
flutter build apk --debug --dart-define=MOYAK_API_BASE_URL=https://moyak-backend.onrender.com --dart-define=MOYAK_TEST_ENVIRONMENT=team-demo --dart-define=MOYAK_ALLOW_SERVER_MUTATIONS=true
```

## 적용 범위

정상 실행 `lib/main.dart`는 `KioskApplication` → 기존 `MyApp`으로 시작합니다.
Navigator 위의 `KioskBackendScope`에서 API와 기기 설정을 공유합니다.
별도 계정·상담·챗봇 화면이나 테스트 버튼은 추가하지 않았습니다.

- 기존 상품 목록: `GET /vending/machines/{machine_id}/products`.
- 검색/카테고리: 서버에서 받은 판매 상품을 기존 검색창/탭으로 필터링.
- 카드 터치: 실제 상품 응답의 제조사·품목코드·단가·재고를 기존 안내 방식으로 표시.
  효능/용법 상세 API는 없어 해당 정보는 만들지 않습니다.
- 장바구니: 내부 저장은 서버 상품 ID → 수량. 기존 배치용 순번 접근은 호환 뷰입니다.
  서버 연결 경로는 예시 상품 자동 선택 없이 빈 장바구니로 시작합니다.
- 기존 결제 이동 버튼: `POST /vending/machines/{machine_id}/orders` 후 기존 결제 화면.
  서버의 주문 항목/수량/단가/총액을 표시합니다.
- 결제 진입·앱 복귀·취소 직전: `GET /vending/orders/{order_id}`로 상태 재확인.
  취소·만료가 서버에서 확인되면 기록을 해제하고, 미결제 주문만 취소 요청합니다.
- 결제 취소·이전·Android 뒤로 가기: `POST /vending/orders/{order_id}/cancel` 확인 후 장바구니.
- 기기 QR: 먼저 기존 세션을 확인하고 미연동이며 사용 가능한 QR이 없을 때만
  `POST /vending/machines/{machine_id}/rotate-qr`의 SVG 표시,
  `GET /vending/machines/{machine_id}/session`을 순차 조회.
- QR 세션에서 paired=true가 확인된 경우 기존 완료 레이아웃과 사용자 홈 재사용.
  완료 문구는 '기기 연동 완료'이며 외부 본인인증·결제 성공을 주장하지 않습니다.
- 서버가 반환한 회원 표시명 사용. 홈 로그아웃/회원의 첫 화면 복귀는 QR 회전으로 기기 세션 해제 확인.

## 실행 설정과 서버 변경 제한

아직 승인된 테스트 서버·기기 ID를 제공받지 않았으므로 기본값은 기기 ID 없음,
서버 변경 불허입니다. 임의 기기 ID/주문/QR 토큰을 생성하지 않습니다.
현재 환경에서는 기존 화면 내에 설정 안내가 표시됩니다.

승인된 테스트 환경이 확인된 뒤에만 아래 값을 지정합니다(공개 설정, 비밀 키 아님).

```powershell
flutter run -t lib/main.dart `
  --dart-define=MOYAK_API_BASE_URL=https://moyak-backend.onrender.com `
  --dart-define=MOYAK_ALLOW_SERVER_MUTATIONS=false
```

환경명과 bool은 승인 절차를 대신하지 않으며 담당자가 확인한 환경에서만 설정합니다.
위 명령은 승인 전 화면 확인용입니다. 기기 ID와 환경명은 비워 두며 서버 요청은 차단됩니다.
승인 후에만 담당자가 확인한 URL·기기 code·환경명을 각각 MOYAK_API_BASE_URL,
MOYAK_MACHINE_ID, MOYAK_TEST_ENVIRONMENT로 전달하고 변경 허용 여부를 별도로 결정해야 합니다.
기본 서버 주소는 기존에 확인된 Render 서버입니다. 실서버 사용 승인은 별도로 필요합니다.
상품 GET도 데모 카탈로그 생성·미결제 주문 만료 처리를 할 수 있어 동일하게 차단합니다.
모델의 가격·재고는 응답 그대로 사용하지만 백엔드의 자동 생성 데모 데이터를 실재고로 보증하지 않습니다.

## 주문 안정성

- 주문 생성 전 서버 상품 ID·수량 사용, 앱 공통 잠금으로 장바구니 간 중복 제출 차단,
  진행 중 수량 편집 차단. HTTP 클라이언트에도 설정 검사를 적용하여 직접 호출 우회를 차단합니다.
- 주문 생성은 재고를 예약/차감합니다. 취소 성공 전 결제 화면을 벗어나지 않습니다.
- 주문 생성 결과가 네트워크/타임아웃/잘못된 응답으로 불확실하면 자동 POST 재시도 금지.
  Android에서는 POST 전 처리 불확실 기록을 동기 저장하여 앱 재시작 후에도 유지합니다.
  기록에는 주문 ID와 불확실 여부만 저장하며 서버 주소·환경명·기기 ID별로 분리합니다.
  토큰·회원명·상품·결제 정보는 저장하지 않습니다. 저장 실패 시 주문을 보내지 않습니다.
- 주문 ID를 받은 경우 상품 목록 진입 시 서버에서 주문을 재조회하고 기존 결제 화면으로 복구합니다.
  조회 실패·404·기기 불일치는 취소로 추정하지 않으며 새 주문을 차단합니다.
  Android 외 플랫폼은 영구 저장 어댑터가 없어 주문을 안전하게 차단합니다.
- 현재 백엔드에는 클라이언트 요청 키 기반 중복 방지/미확인 주문 복구 계약이 없습니다.
  POST 응답을 잃어 주문 ID가 없는 경우에는 자동 복구할 수 없습니다.
  이 경우 앱 재시작 후에도 재주문을 차단하며, 담당자의 서버 확인과 백엔드 복구 계약이 필요합니다.
- 취소/조회 과정의 만료는 백엔드가 판단합니다. 앱 타이머만으로 서버 취소 성공을 만들지 않습니다.
- QR 회전은 이전 기기 연동 사용자를 초기화합니다. 자동 반복 회전하지 않습니다.
  만료 시 QR을 숨기며, 백그라운드/화면 종료 시 조회를 멈춥니다.
  앱 복귀 시 세션 확인 실패는 QR 초기화로 이어지지 않습니다. 유효한 기존 QR은 재사용합니다.
- 회원 홈은 앱 복귀·하위 화면 복귀 시 세션과 승인 정보를 다시 조회합니다.
  확인 실패 시 과거 회원 정보를 숨기며, 이전 조회가 QR 초기화 이후 도착해도 반영하지 않습니다.

## 명확히 미구현인 기능

- 구매별 QR 발급: 백엔드에 없음. 기기 QR에 주문 ID를 임의로 넣지 않음.
- 외부 본인인증: paired와 구분. `/vending/scan`의 user_id 신원 검증은 백엔드 보완 필요.
- 승인 약 목록: 연동된 회원의 `GET /vending/purchases?user_id=...`를 기존 승인 홈/카트에 표시합니다.
  회원 ID·승인 ID를 검증하고 pending/미만료만 사용합니다. 일반 상품 주문 ID와 섞지 않습니다.
  최신 응답의 quantity를 그대로 고정 표시하며 price는 해당 수량 전체 총액입니다.
  구버전 응답에서 quantity가 없으면 기존 계약대로 1개입니다. 수량 변경 컨트롤은 표시하지 않습니다.
  가격 null은 무료로 확정하지 않고 가격 확인 필요로 표시합니다.
  결제 화면 진입/완료 버튼에서 회원·승인·가격을 재조회하지만 모의 결제/배출 API는 호출하지 않습니다.
  실제 결제/약 배출은 미구현 안내로 남깁니다. 예시 카트는 실제 회원 경로에서 사용하지 않습니다.
- 실제 PG/카드 장치 결제 및 실제 약 배출/센서 완료: 미구현.
  `/pay`, `/dispense` 모의 API는 호출하지 않으며 실제 주문의 완료 버튼은 미연결 안내만 표시.
- 앱 설치용 QR은 기기 QR과 별개. 기존 다운로드 안내의 임시 상태 유지.

## 검증

`test/kiosk_backend_integration_test.dart`는 MockClient만 사용합니다.
ID 재정렬, 품절, 중복 ID, 주문 payload/총액, 중복 요청/미확인 결과 차단,
취소, 오류/빈 목록/미설정, QR 세션 이동/만료를 검증합니다.
`test/kiosk_recovery_test.dart`는 재시작 시 주문 복구, ID 미수신 차단, 서버 만료,
중복 요청, 저장 실패, 취소 응답 유실, QR 복귀, 승인 상태 갱신 및 오래된 응답 차단을
모의 HTTP와 저장소로 검증합니다. Android 저장소는 메서드 채널 모의 테스트와 APK 빌드로 확인합니다.
기존 디자인/이동 테스트는 `MyApp` 단독 또는 명시적 예시 카트를 사용합니다.
정상 실행은 `KioskApplication`을 거치므로 설정 누락 시 예시 상품으로 대체되지 않습니다.

```powershell
flutter analyze
flutter test
```

이번 복구·복귀 보완 작업에서는 실제 서버 요청을 전혀 보내지 않았습니다.
실기기 재시작 시 영구 저장과 실제 서버 응답 검증은 승인된 환경에서 추가로 필요합니다.

## 2026-10-21 최종 코드 보완

GitHub master를 읽기 전용으로 확인한 결과 `4712cb844e6a8879b6fa95c76042bfa3ec01f752`입니다.
로컬 검토본도 동일한 커밋이며, 배포 서버가 이 커밋으로 실행 중인지는 별도 확인이 필요합니다.
배포 서버의 `/docs`, `/openapi.json`, `/health`를 포함해 이번 작업에서는 Render에 요청하지 않았습니다.
서버 시작 시 SQLite 시드 및 주문 만료 작업이 실행되므로 안전한 환경 확인을 우선합니다.

- `kiosk_backend.dart`: 비동기 저장 전 주문 입력을 복사해 요청 도중 변경을 방지합니다.
  QR 회전 중에는 세션 읽기 및 중복 회전을 차단하고 완료 시 이전 조회를 무효화합니다.
- `kiosk_home_router.dart`: 회원 홈 첫 진입에도 최신 세션을 조회합니다.
  `pending` 승인만 승인 약 홈으로 분류하며 다른 상태를 수령 가능한 승인으로 해석하지 않습니다.
- `kiosk_payment_screen.dart`: 상태 조회 중 앱이 복귀하면 이전 조회 종료 후 한 번 더 조회합니다.
  오래된 조회 결과만으로 주문 상태가 유지되지 않도록 합니다.
- 화면 배치·색상·에셋·메뉴·결제/배출 미리보기 진입 방식은 변경하지 않았습니다.

## 기기 ID 확인·등록 절차 (실행하지 않은 담당자용 안내)

`MOYAK_MACHINE_ID`는 기기 UUID가 아니라 `vending_machines.code`입니다.
`src/consult/models.py`의 VendingMachine.id는 DB의 code 컬럼에 매핑됩니다.

- `src/consult/map_seed.py`: VM-001을 시연용 동양미래대학교점으로 정의합니다.
  `src/api/main.py` 시작 시 `seed_demo_machines()`가 호출되며 SQLite에서만 시드됩니다.
- `src/consult/shop.py`: SQLite는 상품 GET에서 기기와 데모 상품을 자동 생성할 수 있습니다.
  공유 DB에서는 미등록 기기를 거부하고 상품을 자동 생성하지 않습니다.
- `src/consult/service.py`: QR 회전도 SQLite에서는 기기를 생성할 수 있지만 공유 DB에서는 거부합니다.
- `scripts/supabase_demo_machines.sql`: VM-001이 이미 있다는 전제의 UPDATE와 재고 SQL입니다.
  VM-001 신규 INSERT나 배포 등록 완료의 증거가 아닙니다. 공유 DB에 그대로 실행하지 마세요.
- 테스트는 격리 DB/시연 데이터의 동작을 증명할 뿐 배포 DB의 상태나 사용 승인을 증명하지 않습니다.

먼저 백엔드 담당자가 배포 `DATABASE_URL`이 SQLite인지 공유 Postgres인지, 지도 전용
`MAP_DATABASE_URL`과 동일 DB인지, 테스트 전용 DB 및 사용 허가가 있는지 확인해야 합니다.
Flutter에 DB 주소·비밀번호·관리자 키를 전달하지 않습니다.

등록 확인은 담당자가 해당 DB의 읽기 전용 콘솔에서 다음과 같이 할 수 있습니다.
(아래 SQL은 이 작업에서 실행하지 않았으며 운영 DB 접속 안내가 아닙니다.)

```sql
SELECT code, name, is_active FROM vending_machines WHERE code = 'VM-001';
SELECT id, item_seq, item_name, price, stock
FROM products WHERE machine_id = 'VM-001';
```

지도 API `GET /api/v1/map/machines`는 source와 items의 id/code를 비교할 수 있지만,
지도 DB에서 보이는 기기가 키오스크 주문 DB에도 있다는 보장은 없습니다.
Supabase 상세 경로의 machine_id는 내부 UUID로 조회되는 부분이 있으므로 code를 무조건 넣지 않습니다.
키오스크 session GET도 승인 만료/연결 정리를 할 수 있어 승인 전 등록 확인용으로 호출하지 않습니다.

현재 공개 API에는 전용 기기 등록 관리자 엔드포인트가 없습니다. 새 기기가 필요하다면:

1. 담당자가 테스트 전용 DB와 승인된 고유 code를 결정합니다(Flutter에서 생성하지 않음).
2. 기존 DB 제약을 확인한 뒤 백엔드 전용 관리자 CLI 또는 인증된 관리자 등록 API를 추가합니다.
   code 중복 거부, 필수 name 검증, 트랜잭션, 권한 검사, 변경 이력을 포함해야 합니다.
   공유 DB의 UUID id는 DB 생성 규칙을 사용하고 code를 UUID로 대체하지 않습니다.
3. 키오스크용 `products.machine_id`에는 code를 연결하고 실제 승인된 상품 ID·단가·테스트 재고를 등록합니다.
   지도용 machine_inventory의 UUID 재고만 넣어서는 상품 API와 연결되지 않습니다.
4. 담당자가 등록 및 DB 분리를 검증하고 URL/code/사용 가능 요청/정리 방법을 전달합니다.
   그 후에만 Flutter 설정과 실서버 테스트를 진행합니다.

위 관리자 등록 기능은 제안이며 이 Flutter 저장소에서 구현된 API라고 주장하지 않습니다.

## API 계약 및 남은 서버 검증

| 기능 | 현재 Flutter 연결 | 계약/한계 | 이번 실서버 검증 |
| --- | --- | --- | --- |
| 상품 목록 | 기존 목록·검색·탭·카드 | GET /vending/machines/{code}/products → id/item_seq/item_name/company/category/badge/price/stock 배열 | 미실행 |
| 상세 표시 | 목록 응답의 제조사·품목코드·가격·재고 재사용 | 별도 상품 상세/효능/용법 API 없음 | 미실행 |
| 주문 생성 | 기존 장바구니 → 결제 | POST /vending/machines/{code}/orders, items: [{product_id,quantity}] | 미실행 |
| 주문 조회/취소 | 기존 결제·복구 | GET /vending/orders/{id}, POST /vending/orders/{id}/cancel | 미실행 |
| 주문 응답 | 서버 금액·항목 표시 | id/machine_id/status/total_amount/created_at/paid_at/dispensed_at/items(item_name,unit_price,quantity); 응답 항목에 product_id 없음 | Mock 검증 |
| 기기 QR | 기존 QR 화면 | POST /vending/machines/{code}/rotate-qr → machine_id/qr_token/qr_token_expires_at/qr_svg | 미실행 |
| 세션 | QR·회원 홈 | GET /vending/machines/{code}/session → paired/user_id/user_display_name/purchase | 미실행 |
| 모바일 스캔 | 휴대폰 앱 담당, 키오스크가 대리 호출하지 않음 | POST /vending/scan, machine_id/qr_token/user_id → has_pending_purchase/purchase | 미실행 |

추가 백엔드 계약: ID 미수신 주문의 idempotency 키/복구 조회, 승인 약 수량 확장·상품 매핑,
기기·사용자 인증/권한 강제, 실제 결제 장치의 성공 검증, 구매별 QR, 물리 배출/실패 상태가 필요합니다.
현재 `/pay`, `/dispense`의 DB 상태 변경을 실제 결제/배출 성공으로 해석하지 않습니다.

## 승인 전 사용자가 실행할 명령 (PowerShell)

```powershell
cd C:\Users\jhm54\moyak_flutter
flutter analyze
flutter test
flutter build apk --debug --dart-define=MOYAK_ALLOW_SERVER_MUTATIONS=false
flutter devices
flutter run -t lib/main.dart --dart-define=MOYAK_ALLOW_SERVER_MUTATIONS=false
```

기기가 여러 개면 마지막 명령에 `-d`와 flutter devices에 나온 기기 ID를 붙입니다.
APK: `build/app/outputs/flutter-apk/app-debug.apk`. 기기 ID/환경 미설정 안내는 정상 차단 동작입니다.
MOYAK_LIVE_API_TEST는 켜지 않습니다. 이 명령들은 키오스크 서버 변경 요청을 허용하지 않습니다.

최종 실행 결과(2026-10-21): flutter analyze 문제 없음, flutter test 66개 통과·실서버 테스트
1개 건너뜀, Android 디버그 APK 빌드 성공(변경 허용 false 명시).
기존 SVG filter 미지원 로그는 남지만 테스트 실패나 분석 오류는 아닙니다.
실제 배포 API, 실제 기기 강제 종료 복구, 실제 모바일 스캔의 종단 간 검증은 수행하지 않았습니다.
판정: 지원되는 상품·주문·기기 QR의 코드 연결 완료, 실제 서버 검증 대기.

## 승인 약 실데이터 연결 보완 (2026-10-24)

- `KioskSession.userId`, `KioskApprovedPurchase` 및 `/vending/purchases` 클라이언트를 추가했습니다.
- 회원 홈은 세션뿐 아니라 승인 목록도 재조회하여, QR 스캔 당시 승인 건이 없더라도
  이후 발급된 pending 승인을 기존 홈/배너에 반영할 수 있습니다.
- 승인 목록→기존 승인 장바구니→기존 결제 확인 레이아웃을 재사용합니다.
  `/vending/purchases/pay`, `/vending/dispense`는 모의 API이므로 호출하지 않습니다.
- 승인 만료/가격 변경/다른 회원/중복 ID/가격 미정/수량 고정/미리보기 배출 차단을
  `test/kiosk_live_approval_test.dart`에서 MockClient로 검증합니다.

사용자가 전체 연결을 요청하여 VM-001 상품 GET을 시도했으나, 자동 승인 검토가
공유 DB의 시드 생성/주문 만료 처리 및 테스트 환경 승인 미확인을 이유로 실행을 거절했습니다.
해당 요청은 전송되지 않았으며 우회 실행하지 않았습니다.
주문 생성·취소·QR 회전 및 모의 결제/배출을 실제 서버에 보내지 않았습니다.
기본 서버 변경 차단 설정은 유지합니다. 이 보완으로 실서버 상품이 이미 조회되거나
현재 APK의 빈 목록이 해결되었다고 주장하지 않습니다.
승인된 테스트 URL/기기 code 및 상품 조회의 부수 변경 허용 확인 또는
백엔드의 순수 읽기 전용 상품 조회 API 배포가 필요합니다.

보완 후 검증: `flutter analyze` 문제 없음, `flutter test` 73개 통과·실서버 테스트 1개 건너뜀.
승인 조회 중 선택 변경도 결제 진입을 차단합니다. 실제 서버 요청이 차단된 상태이므로
현재 APK를 실제 데이터 연결이 완료된 최종 배포본으로 표시하지 않습니다.

## team-demo 설정 및 최신 계약 확인 (2026-10-24)

GitHub master는 `4ee1d783d6e726d97a79567b8c6a83bd05b51f3d`로 변경되었습니다.
이전 `4712cb8`과 상품/주문 라우트 및 shop 서비스는 동일하며, 의약외품 상품 응답은 여전히
id/item_seq/item_name/company/category/badge/price/stock 배열입니다.
지도 machine_inventory와 주문 products를 동일 데이터로 가정하지 않습니다.

승인 응답에는 quantity가 추가되고 price는 해당 수량 전체의 총액으로 명시되었습니다.
Flutter는 서버 수량을 고정 표시하고 총액을 수량으로 다시 곱하거나 나누지 않습니다.
수량 변경 시 재검증을 요구하며, 기존 화면 배치와 이동은 유지합니다.

`MOYAK_MACHINE_ID`가 공백이 아니고, `MOYAK_TEST_ENVIRONMENT`가 공백이 아니며,
`MOYAK_ALLOW_SERVER_MUTATIONS=true`일 때 클라이언트가 /vending/ 요청을 허용합니다.
환경명 team-demo는 라벨이며 실제 기기 등록·운영자 승인·테스트 DB 분리를 검증하지 않습니다.
VM-001은 아직 테스트 사용 허가가 확인되지 않았으므로 변경 요청과 true 설정 APK는 보류합니다.

현재 HTTP 응답 헤더/본문을 포함한 요청 대기 제한은 75초이며 무제한으로 늘리지 않았습니다.
73초 응답 성공과 75초 초과 타임아웃 및 자동 재시도 없음을
`test/kiosk_team_demo_settings_test.dart`에서 가상 시간/MockClient로 검증합니다.
실제 서버 응답이 항상 73초라는 보장은 없고 2초 여유는 좁습니다.
서버가 제한을 넘으면 기존 오류 안내로 종료하며, 미확인 주문 POST를 자동 재전송하지 않습니다.
기존 상품 로딩 문구, 빈 목록 안내, 오류 안내를 유지했습니다.

최신 코드의 `GET /vending/machines/{code}/medicines`는 DB 조회만 수행하는 별도 경로입니다.
이것은 약사 처방용 machine_inventory 조회이며 의약외품 products의 ID를 제공하지 않습니다.
이 경로에서 기기가 확인되더라도 주문/재고 변경 테스트 사용 승인으로 간주하지 않습니다.

운영자가 VM-001 사용 및 시드/만료 정리를 포함한 상품 GET·주문/취소·QR 갱신 중
허용 범위를 확인한 뒤에만 다음 명령을 사용합니다(아직 실행하지 않음).
URL은 Markdown 링크 문법 없이 전달해야 합니다.

```powershell
flutter build apk --debug `
  --dart-define=MOYAK_API_BASE_URL=https://moyak-backend.onrender.com `
  --dart-define=MOYAK_MACHINE_ID=VM-001 `
  --dart-define=MOYAK_TEST_ENVIRONMENT=team-demo `
  --dart-define=MOYAK_ALLOW_SERVER_MUTATIONS=true
```

### 실제 서버 조회 결과 (2026-10-24)

`GET /vending/machines/VM-001/medicines`를 75초 제한으로 1회 실행했습니다.
응답 HTTP 200, 소요 시간 65.8초, machine_code=VM-001, restricted=true,
의약품 재고 6종·총 63개가 반환됐습니다. 이 경로는 `get_db`의 DATABASE_URL을 사용하므로
키오스크 DB의 VM-001 기기 존재를 확인했습니다. 기기 UUID를 임의로 만들지 않았습니다.

이 경로의 핸들러와 `machine_medicines`는 SELECT/메타데이터 조회만 하며
시드/주문 만료/재고 차감/commit을 호출하지 않는 것을 소스로 확인하고 실행했습니다.
이 결과는 machine_inventory 데이터이며 주문용 products.id 확인이나 테스트 사용 허가는 아닙니다.
상품 GET·승인 목록 GET·주문 조회/생성/취소·QR 갱신/세션 조회는 이번에 호출하지 않았습니다.
서버 시작 시 별도 백그라운드 작업 여부까지 이 조회로 보증하는 것은 아닙니다.

로컬 검증: 정적 분석 문제 없음, 자동 테스트 78개 통과·실서버 opt-in 테스트 1개 건너뜀.
73초/76초 경계 테스트는 가상 시간/MockClient 결과이며 실제 서버 시간 측정과 구분합니다.
공유용 APK는 최신 계약 수정 반영을 위해 false 설정으로만 재빌드합니다.
요청한 VM-001/team-demo/true APK는 기기 변경 테스트 사용 승인 확인 후 생성해야 합니다.
