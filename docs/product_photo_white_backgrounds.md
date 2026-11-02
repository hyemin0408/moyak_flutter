# 상품 사진 흰 배경 편집 (2026-11-01)

추가 작업: 새 일회용 렌즈 세정액(901000032)의 검은 외곽 프레임을 흰색으로 편집해
`assets/products/daily_disposable_lens_white.png`로 저장·연결했다.
원본 `올데이-모이스처 1팩 일회용 렌즈 세정액 10ml x 25개.png`는 보존했다.
도구는 기본 제공 image_gen이며 주요 표기 10mL/25EA와 박스·앰플 구성을 육안 확인했다.
AI 편집본으로 원본과 픽셀 단위 동일성을 보증하지 않는다. 상품명·가격·재고는 변경하지 않았다.

이번 프롬프트: "Background-only correction of this exact photo. Replace the black outer
border and external background with pure white #FFFFFF. Preserve box and single ampoule,
angle, relative sizes, teal/white colors, labels and all numbers. Retain 올데이-모이스처액,
ALL-DAY MOISTURE+, 25 EA, 10mL x 25EA and 10mL. Never change them to 20ml or 50A.
Do not redraw, enhance, invent, translate, relight or change product typography or objects.
Keep complete uncropped contours. No new text, objects or watermark. Square output."

후속 변경: 가그린은 사용자가 제공한 `가그린 레귤러 100ml (2).png`로 다시 교체했다.
아래 mouthwash_white.png는 이전 편집 기록이며 현재 연결된 사진이 아니다.

도구: 기본 제공 image_gen (imagegen 스킬), 외부 API 키/CLI는 사용하지 않았다.
의약외품 21종을 육안 확인하고 흰 배경인 16종은 원본 그대로 유지했다.
색 배경이 있는 5종은 아래 편집본을 별도 저장해 연결했다. 원본 파일은 보존했다.
상품 목록의 이미지 영역도 흰색으로 채워 비율 유지 시 남는 여백을 통일했다.
상품명/가격/재고/상품 ID/주문/화면 이동은 변경하지 않았다.

| 코드 | 원본 | 연결한 편집본 (assets/products/) |
|---|---|---|
| 901000003 | 어린이밴드.png | children_band_white.png |
| 901000031 | 콘택트렌즈 다목적 용액 360ml.png | lens_solution_white.png |
| 901000044 | 순수한면 팬티라이너 40매.png | pantyliner_white.png |
| 901000053 | 일회용 덴탈 마스크 50매.png | dental_mask_white.png |
| 901000062 | 가그린 레귤러 100ml.png | mouthwash_white.png |

AI 편집본이므로 원본과 픽셀 단위로 동일한 제품 사진이라는 보증은 아니다.
제품 구성을 육안 검토했다. 가그린의 1차 편집본은 용량 글씨가 120mL로 바뀌어
사용하지 않았으며, 원본의 100ml를 유지한 재편집본만 연결했다.
편집본의 파일 로딩/디코딩과 모서리 배경의 불투명한 흰색 여부를 자동 검증한다.

## 공통 편집 프롬프트

Use case: precise-object-edit. Edit target: the single attached existing product
photograph for a Flutter product catalog. Change ONLY the external background to
flat pure white (#FFFFFF). Preserve the exact photographed packaging, bottle,
masks, proportions, viewing angle, placement, existing brand names, all Korean and
English text, numbers, label graphics, characters, product colors and details.
Do not redesign, redraw, translate, correct, invent or remove any product label
text. Keep every object, including bottle and box together where present, complete
and uncropped. Remove the colored/gray/cream environmental backdrop and any
pedestal; place the same unchanged objects on a clean pure white background.
Very subtle neutral contact shadow only, no tint, no gradient, no added text or
objects. Output one square product image.

각 입력에는 위 표의 원본을 한 장씩 지정했다.

## 가그린 재편집 시 추가 지정

Retain the original bottle shape/perspective and ALL label details, especially the
capacity text exactly '100ml'. It is a 100ml bottle, absolutely NOT 120mL or 200ml.
Replace ONLY the gray environmental background and pedestal outside the bottle
silhouette with solid pure white #FFFFFF. Do not redraw, enhance, relight,
straighten, redesign or invent any of the product, letters, numbers or cap.
Do not upscale product details into invented text. Preserve the whole bottle
uncropped at the same relative position and scale as the input.

2026-11-02: Built-in image_gen edit: remove only top-right '유한킴벌리 직영' overlay; preserve product package, text, framing and white background. Original: assets/products/좋은느낌 대형 14매.png. App asset: assets/products/goodfeel_large_14_clean.png. Visually inspected; original retained. Included in moyak-kiosk-20261102.apk; image catalog tests: 7 passed.
