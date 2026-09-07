# cha-time design reference

These files are the interactive design source of truth for the shipping product **cha-time**.

The filenames and some copy still use the historical design names `Tea` / `소담`; those are design-era references, not the current app/store name.

```text
design/
  sodam-prototype.html      calendar → tea session → closing → fortune card
  sodam-season-matrix.html  season × weather rules and motion specs
  support.js                rendering runtime
  tex/                      paper-grain overlays used by the reference and Flutter port
```

## Voice font

The reference expects a local Kyobo Handwriting 2025 font under `assets/fonts/`. The font binary is intentionally not committed unless redistribution is explicitly allowed by its license.

Calendar structural typography remains sans-serif. The handwriting is reserved for cha-time's authored voice, user reflection text, actions, and fortune card.

## Product flow encoded here

- Calendar home: month navigation, today highlight, finished blossom / unfinished raindrop markers, visit count
- Session: one reflection → one sip; six sips empty one cup; typed responses
- Empty cup: refill or finish
- Refill: cup visibly fills in stages rather than instantly resetting
- Closing: saucer + blossom trace + closing line
- Fortune: tap the blossom to open a paper card with a line to keep for tomorrow
- Past finished days: reopen the stored fortune from the calendar
- Relationship progression: voice/CTA change after ≤6, ≤20, and 21+ completed visits

## Season × weather model

Season owns what is present: paper tone, tea tone, trace language, and base steam. Weather owns how it appears: light wash, particles, steam multiplier, and typing speed.

The reference defines spring / summer / rainy season / autumn / winter crossed with clear / cloudy / rain / snow, plus six exception combinations such as flower rain, shower, cold rain, dry winter sunlight, and first snow.

The Flutter port implements the visual states and seasonal rules. Live weather data itself is intentionally not fabricated; until a production provider is chosen, QA selects weather via `--dart-define=CHA_TIME_WEATHER=...` and production defaults to clear.

## Generative text boundary

The design reference keeps normal replies constrained to local authored text and reserves generation for narrow end-of-session/fortune behavior. The Flutter client currently uses safe local fallbacks because a production AI backend/provider has not yet been selected. API secrets must not be embedded in the mobile client.

## Porting constants

- cup states: `assets/images/tea_bowl_{empty,1of6..5of6,v1}.png`
- six sends per cup
- typing: ~92–144 ms normal chars, ~60–100 ms spaces, ~190–250 ms punctuation, multiplied by weather
- refill: 0 → 35% → 70% → 100% over 140/170/180 ms steps
- fortune card uses `design/tex/paper_card.png`
- paper background uses `design/tex/paper_soft.png`

When this document and historical handoff notes disagree, the latest Flutter implementation, this design folder, and the latest user instruction take precedence.
