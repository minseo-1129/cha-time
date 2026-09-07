# cha-time typography

Preferred voice typeface: **교보문고 손글씨 2025 이유빈**.

## Current implementation

`ChaTimeFonts.loadVoice()` scans:

```text
assets/fonts/
```

and loads a local `.ttf`/`.otf`, preferring a 2025/Kyobo filename when available.

Voice-font usage includes:

- opening and system responses
- submitted user text
- text input and hint
- `잔이 비었어요`
- empty-cup/closing copy
- action labels
- fortune-card text and signature

Calendar structure (month, weekdays, dates) intentionally remains a quiet sans-serif so the handwriting reads as cha-time's voice rather than navigation chrome.

## Release protection

`scripts/build_release.sh` now stops before release if no `.ttf` or `.otf` exists in `assets/fonts/`. This prevents another AAB from silently falling back to the system font.

## Font-file caution

Do not commit, expose, or redistribute the font binary unless its license and exact source explicitly permit repository redistribution. Keep a licensed local copy on the release machine and back it up separately.
