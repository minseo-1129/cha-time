Tea PNG UI primitives

These are intentionally raster/paper-textured controls rather than clean
system SVG icons.

Current PNG controls:
- calendar_default.png
- calendar_prev_default.png
- calendar_next_default.png
- send_default.png
- send_disabled.png

Pressed feedback is handled in Flutter with a tiny scale + opacity change, so
the organic PNG artwork remains the visible primitive.

Not used:
- chat bubbles
- calendar day cards / saucers

Calendar status stays motif-only:
- no record: nothing
- unfinished: status_raindrop.png
- finished: trace_blossom.png
