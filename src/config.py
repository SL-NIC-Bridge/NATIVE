from typing import Dict

# Application configuration
APP_TITLE: str = "SL NIC Bridge"

# Brand colors
BRIGHT_ORANGE: str = "#FF7A00"  # bright orange
BROWN: str = "#795548"           # material brown 500

# Color palettes
# Note: Prefer Flet's Theme & semantic colors over manual palettes.
# These palettes are retained for backward compatibility only.
LIGHT_PALETTE: Dict[str, str] = {
    "primary": BRIGHT_ORANGE,
    "secondary": BROWN,
    "background": "#FFFFFF",
    "surface": "#FAFAFA",
    "on_primary": "#FFFFFF",
    "on_background": "#000000",
}

DARK_PALETTE: Dict[str, str] = {
    "primary": BRIGHT_ORANGE,
    "secondary": BROWN,
    "background": "#121212",
    "surface": "#1E1E1E",
    "on_primary": "#000000",
    "on_background": "#FFFFFF",
}
