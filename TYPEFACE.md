# Tea typography

Preferred Tea voice typeface: **교보문고 손글씨 2025 이유빈**

## Current implementation

Tea loads its voice font at runtime through `TeaFonts.loadVoice()` in `lib/main.dart`.

The loader scans:

```text
assets/fonts/
```

and prefers a 2025/Kyobo font file when available.

Current voice-font usage includes:

- system responses
- opening prompt
- submitted user text
- input text
- input hint
- empty-cup line: `잔이 비었어요`
- closing line: `내일 또 들러줘.`
- action labels

Calendar structural typography (month, weekdays, day numbers) intentionally remains a quiet sans-serif so handwriting reads as Tea's voice rather than navigation chrome.

Do not switch the whole calendar to handwriting.

## Font-file caution

Do not expose, redistribute, or commit a font file unless its license and exact source permit repository redistribution.

See `docs/PROJECT_HANDOFF.md` for the current product/visual contract.
