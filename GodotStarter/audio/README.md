# Original game sounds

`dash_whoosh.wav` is an original synthesized 0.22-second filtered-noise whoosh. Rebuild from the repository root with `python Tools/generate_dash_sfx.py`. No third-party samples are used.

`impacts/` contains the original billiard-style hit and ball-contact sounds, with its own rebuild instructions.

All sounds use the scene's bounded audio pool and limited ImpactSFX bus. The dash sound plays once on successful activation, independently of whether an enemy is hit.
