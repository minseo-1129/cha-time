Tea voice font folder

Place the locally downloaded Kyobo Handwriting 2025 font file in this folder.

Recommended local path:
assets/fonts/<your-downloaded-font>.ttf

The app discovers the first .ttf or .otf in this folder at startup and loads it
as the Tea voice typeface. The exact filename does not need to be hard-coded.

The font is intentionally used only for Tea's authored voice:
- system responses
- "잔이 비었어요"
- "내일 또 들러줘."
- action labels
- input hint

Calendar month / weekdays / date numbers and the user's own message remain in
the quiet sans-serif system typeface.

Do not remove this README; it keeps the folder present in Git even when the
font binary exists only locally.
