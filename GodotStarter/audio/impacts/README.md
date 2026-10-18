# Billiard-style impact sounds

Six original synthesized mono PCM WAV sounds, created for this project. No external recordings or sample libraries were used.

- `cue_*.wav`: short, bright cue-like contacts for successful sweep, palm, and dash hits.
- `ball_*.wav`: fuller resin-ball clacks for enemy collisions.

Rebuild with `python Tools/generate_billiard_sfx.py` from the repository root. Each family has three deterministic variations. Runtime pitch variation, strength-based volume, distance attenuation, voice limits, pair contact deduplication, and a limiter are handled by `scripts/impact_audio.gd`.
