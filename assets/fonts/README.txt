cha-time voice font folder

Place the locally licensed Kyobo Handwriting 2025 font file in this folder before release builds.

Recommended local path:
assets/fonts/KyoboHandwriting2025lyb.ttf

The app discovers a .ttf or .otf in this folder at startup and loads it as cha-time's voice typeface. The exact filename does not need to be hard-coded, though 2025/Kyobo filenames are preferred.

The release script intentionally fails if this folder contains no real font binary, so a Play AAB cannot silently ship with the system-font fallback.

The handwriting is used for cha-time's authored voice, reflection input/text, actions, closing copy, and fortune card. Calendar structural text remains sans-serif.

Do not commit or redistribute the font binary unless its license explicitly permits that.
