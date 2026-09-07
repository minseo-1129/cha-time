# Sodam design reference

Interactive design reference for Tea / 소담, built as self-contained HTML.
Open either file directly in a browser — no build step, no server, no npm.

```text
design/
  sodam-prototype.html      한 잔의 회고 — 캘린더 → 세션 → 마무리 → 포춘 카드
  sodam-season-matrix.html  계절 × 날씨 규칙 보드 (레이어 소유권 · 5×4 매트릭스 · 모션 스펙)
  support.js                rendering runtime for the two files above
  tex/                      paper-grain overlays generated for this reference
```

Both files read the repository's existing PNGs from `../assets/images/` and
`../assets/ui/` — no image is duplicated into `design/`.

## Voice font

The files declare `@font-face` against:

```text
../assets/fonts/KyoboHandwriting2025lyb.ttf
```

That file is intentionally **not committed** (see `TYPEFACE.md`). Drop your
local copy at that path to see the intended voice typography; without it the
handwriting falls back to Noto Sans KR and everything still works. Structural
calendar typography stays sans-serif by design — do not switch it to handwriting.

## What the prototype covers

| Screen | Behavior |
| --- | --- |
| 캘린더 홈 | 월 이동, 오늘 강조, 마친 날(벚꽃)·남겨둔 날(물방울) 흔적, 누적 잔 수 |
| 차 한 잔 세션 | 한 마디 → 한 모금. 6모금이면 잔이 빈다. 응답은 글자 단위 타이핑 |
| 잔이 비었을 때 | 「한 잔 더 마실래」 / 「오늘 이만 마칠래」 — 리필은 잔이 세 단계로 다시 찬다 |
| 마무리 | 받침과 흔적만 남는다. 벚꽃을 누르면 포춘 카드 |
| 포춘 카드 | 종이 카드가 기울어 올라오며 내일 기억할 한 마디. 캘린더의 지난 마친 날에서 다시 열림 |

## Design decisions this reference encodes

**누적 관계 3단계.** 방문 횟수로 목소리가 바뀝니다 — 1단계(≤6잔) 존댓말 없는 짧은
수용, 2단계(≤20잔) 조금 더 들여다봄, 3단계(21잔+) 「자네」 호칭. CTA 문구와 작별
인사도 단계를 따릅니다. 대화형 챗봇으로 내려앉지 않도록 응답은 한 문장 24자 이내,
조언·질문·칭찬을 금지합니다.

**그날의 맥락은 여섯 레이어로 나뉩니다.** 계절은 *무엇이 있는가*(종이 톤, 차 색,
흔적, 김 기본값)를, 날씨는 *그것이 어떻게 보이는가*(빛 방향·색온도, 입자, 김 배수,
타이핑 배속)를 소유합니다. 두 축이 같은 속성을 다투지 않으므로 20개 조합이 6개
규칙으로 표현됩니다. 예외 6조합(꽃비·소나기·갠 하늘·찬비·마른 햇빛·첫눈)만 규칙을
덮어씁니다. 전체 표는 `sodam-season-matrix.html`.

**생성형은 두 지점에만.** 일반 응답은 대본 풀에서 고릅니다. 잔이 비는 마지막 한
마디와 포춘 카드 문장만 생성형이며, 실패 시 항상 대본으로 안전하게 떨어집니다.
프로토타입에서는 브라우저 내장 헬퍼를 쓰므로, 앱 구현 시 이 두 호출만 서버로
옮기면 됩니다.

## Porting notes for `lib/main.dart`

- 잔 단계는 `assets/images/tea_bowl_{empty,1of6..5of6,v1}.png` 7단계를 그대로 씁니다.
  `v1`이 가득 찬 상태(6/6)입니다.
- 김(steam)은 이미지가 아니라 블러 처리한 그라디언트 3개입니다. 잔이 비면 투명도 0으로
  0.6초에 걸쳐 사라집니다.
- 타이핑 속도: 일반 글자 92–144ms, 공백 60–100ms, 문장부호 뒤 190–250ms.
- 리필 애니메이션: 0 → 35% → 70% → 100%, 각 140/170/180ms.
- 포춘 카드 등장: 500ms `cubic-bezier(.2,.8,.2,1)`, 28px 위로 + `-1.1deg` 기울기 유지.
