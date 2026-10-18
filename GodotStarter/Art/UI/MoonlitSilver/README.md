# Moonlit Silver

Prepared from the user's selected A variant in `output/ui-variants-2026-10-16/A-moonlit-silver.png`, generated with built-in imagegen. PNG crops preserve alpha and use nearest-neighbor filtering. The HUD uses the empty slot as a scalable panel, plus the two resource orbs. The minimap is drawn live inside the silver panel; the source minimap crop is retained for future use, since its map contents are baked in.

Runtime HUD: `scripts/hud.gd`. Resource depletion is drawn inside the orb glass; text and enemy bars are rendered live.
