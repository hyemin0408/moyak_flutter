# 실제 백엔드 연결 기록 (2026-10-21)

이 문서는 이전 계정·앱 API 점검의 이력입니다. 아래 실서버 검증 기록은 과거 결과이며
이번 키오스크 최종 작업에서 재실행하지 않았습니다.

> 이후 키오스크 상품·주문·기기 QR 연결 코드가 추가되었습니다.
> 현재 실행 설정·연결 범위·검증 제한은 [키오스크 연동 문서](kiosk_backend_integration.md)를 기준으로 확인하세요.
> 아래 별도 서비스 페이지 제거 시점의 설명과 구분됩니다.

## 확인한 원본

- 저장소: https://github.com/JONGBOK1/moyak-backend
- 분석 커밋: `4712cb844e6a8879b6fa95c76042bfa3ec01f752`
- README.md, docs/flutter-handoff.md, docs/map-api.md, .env.example 및 src/api/routes,
  src/accounts, src/consult/auth.py를 확인했다.
- 배포 서버: `https://moyak-backend.onrender.com`
- 배포 API 명세: `https://moyak-backend.onrender.com/openapi.json`, `/docs`
- README/인수인계의 일부 “인증 없음” 설명은 오래됐다. 실제 auth.py 및 배포 OpenAPI에는
  회원가입/로그인/회원 정보 API가 있다. 요청·응답은 최신 코드 및 배포 명세를 기준으로 했다.

## 현재 화면 구성과 보존한 API 코드

일반 앱 `lib/main.dart` → 시작 → 기존 키오스크 홈.
추가했던 **계정·약품 조회** 버튼, 전용 페이지와 해당 페이지 테스트는 제거했다.
세 홈의 기존 구매 메뉴와 QR 이동은 그대로다. 별도 모바일 상담 시연 앱도 제거했다.
아래 API 클라이언트·모델은 계약 테스트와 명시적으로 실행하는 실제 서버 테스트에서
사용하므로 보존했다. 현재 키오스크 화면에서는 호출하지 않는다.

| 기능 | 실제 요청 | 주요 요청 / 응답 |
|---|---|---|
| 서버 상태 | GET /health | `status: ok` |
| 아이디 확인 | GET /auth/username-available?username= | `username, available` |
| 가입 | POST /auth/signup | `username, password, name?` → 세션(201) |
| 로그인 | POST /auth/login | `username, password` → 세션 |
| 회원 정보 | GET /auth/me | Bearer 토큰 → `id, username, name, role` |
| 약품 검색 | GET /drugs/search?q=&limit=20 | `[{item_seq,item_name,company}]` |
| AI 상담 (화면 제거, API 코드만 보존) | POST /chat | `question, history:[{role,content}]` → `answer,sources,evidence,recommendations` |

인증 응답은 `access_token, token_type, expires_in, user`이다.
Supabase가 비밀번호를 검증한 뒤 **백엔드가 자체 서명한 Bearer 토큰**을 돌려준다.
Flutter는 토큰을 해석하거나 임의 발급하지 않는다. 신원을 주장하는 임시 `X-Moyak-*`
헤더도 보내지 않는다.

가입은 실제 서버 계정을 생성한다. 제공받은 시험 계정이 없어 임의 가입이나 로그인 성공을
실서버에서 만들지 않았다. 현재 앱에는 계정 입력 화면이 없다.
로그인·가입 요청 및 Bearer 회원 조회 계약은 API 클라이언트 테스트로 검증한다.

## 데이터·보안·오류 처리

- `moyak_api_models.dart`: 실제 wire 응답 전용 모델. 기존 demo_* 모델과 분리.
- `moyak_api_client.dart`: HTTP/JSON/UTF-8/Bearer/75초 타임아웃/오류 변환 담당.
- `backend_services_screen.dart`: 제거됨. 별도의 계정·약품 조회 페이지는 제공하지 않는다.
- 서버가 실패해도 데모 약품·답변·인증 성공으로 대체하지 않는다.
- POST 자동 재전송을 하지 않는다. 타임아웃은 성공도 실패 확정도 아니며 가입 재시도 시
  이미 생성된 계정이라면 로그인 또는 아이디 확인을 사용한다.
- 제거된 페이지의 세션 관리 UI도 함께 제거했다. API 클라이언트에는 전역 토큰 저장소가 없다.
  비밀번호와 토큰을 소스/로그/파일/일반 환경 설정에 저장하지 않는다.
- 계정 로그인은 본인인증, 앱-키오스크 연동, 약사 승인과 같은 상태가 아니다.
  기존 개발용 홈 상태 선택 및 가상 회원 이름과 연결하지 않았다.
- 약품 검색에는 판매가격·재고·승인이 없으므로 기존 장바구니로 전환하거나 가격을 만들지 않는다.
- 401은 로그인 만료/실패, 409는 중복, 422는 입력 오류, 429는 요청량 제한,
  5xx/네트워크/타임아웃/잘못된 JSON은 사용자용 오류로 표시한다.

## 실행

```powershell
flutter run -d emulator-5554 -t lib/main.dart
```

공식 서버가 변경되는 경우에만 확인된 HTTPS 주소를 전달한다.

```powershell
flutter run -t lib/main.dart --dart-define=MOYAK_API_BASE_URL=https://확인된-서버-주소
```

Flutter에 .env.example의 OPENAI/PINECONE/DAILY/SUPABASE_SERVICE_ROLE_KEY/
CONSULT_AUTH_SECRET 등을 복사하지 않는다. 이것들은 백엔드 서버 전용이다.
Android 정식 빌드에도 INTERNET 권한을 추가했으며 HTTP 평문 허용은 켜지 않았다.

## 검증

- 배포 서버 health 200, OpenAPI 200, 약품 검색 200, auth/status의 설정/상태 정상 확인.
- 인증 없는 /auth/me 401 및 잘못된 Bearer 거부 확인.
- 개인정보 없는 출처 확인 질문을 /chat에 1회 전송해 200과 응답 구조를 확인.
  이 질문 응답은 sources/evidence가 비어 있었으며 빈 목록을 그대로 처리한다.
- 일반 테스트는 실제 네트워크/계정 생성/결제/장치를 사용하지 않는다.
- 실제 읽기 전용 API 테스트는 별도 명령으로 명시 실행한다.

```powershell
flutter analyze
flutter test
flutter test test/moyak_api_live_test.dart --dart-define=MOYAK_LIVE_API_TEST=true
```

## 아직 연결하지 않은 기능

- 실제 기기의 ID: 문서의 VM-001은 시연 기본값이며 이 Flutter 설치 기기의 실제 ID는 미확인.
- QR 발급·스캔·세션 polling, 실제 본인인증, 승인 약 목록의 실데이터 매핑.
- 지도와 재고: `/api/v1/map/...` 엔드포인트는 있으나 지도 플랫폼 설정/기기 확인 필요.
- 상담 생성·약사 결정·화상(Daily)·상담 녹음/요약 API: 별도 화면 및 권한 설계 필요.
- 일반 상품 API `/vending/machines/{id}/products`와 주문: 기기 ID 확정 및 상품/재고 매핑 필요.
- 결제·배출: README와 구현 모두 **모의 결제·모의 장치 응답**이다. 실제 PG·MQTT 연동 아님.
  기존 Flutter 결제/배출 화면은 개발용 미리보기로 유지하며 실결제 API에 연결하지 않았다.
- 토큰 영구 저장/앱 재실행 로그인 유지/기기 전체 공유 세션: 현재 의도적으로 미지원.
- 백엔드 일부 상담 API는 클라이언트 신원 헤더/인증 생략 호환 경로를 허용한다.
  정식 서비스 전 Bearer 기반 권한 강제와 운영 인증 경계를 서버에서도 강화해야 한다.

기존 `docs/backend_integration.md`의 가상 인터페이스는 사전 설계 자료이며,
실제 서버 계약과 동일하다고 가정하지 않는다. 이 문서와 새 API 모델이 확인한 계약이다.

## 키오스크 담당 범위 정리

- 별도 모바일 약사 상담 시연 앱 `lib/demo_mobile/`를 제거했습니다.
- 추가 정리: `backend_services_screen.dart`와 홈 진입 버튼 및 전용 화면 테스트도 제거했습니다.
- 공통 API 클라이언트·모델 및 API 계약 테스트는 유지합니다. `/chat` 클라이언트는 보존하지만 현재 화면에서 호출하지 않습니다.
- AI 및 계정 UI 연동 검증은 제거 전 기록입니다. 현재 키오스크에는 별도 API 서비스 페이지가 없습니다.
- 기존 키오스크 상담 안내·QR·상품 선택·장바구니·구매 흐름은 유지합니다.
