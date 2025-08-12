from typing import Dict
import flet as ft

# Static product details
APP_TITLE: str = "SL NIC Bridge"

# Brand colors
BRIGHT_ORANGE: str = "#FF7A00"  # bright orange
BROWN: str = "#795548"           # material brown 500

# Note: Prefer Flet's Theme & semantic colors over manual palettes.
# Palettes are retained for backward compatibility only.
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


def get_palette(mode: ft.ThemeMode | None) -> Dict[str, str]:
    """Deprecated: Return color palette by theme mode. Avoid using directly."""
    return DARK_PALETTE if mode == ft.ThemeMode.DARK else LIGHT_PALETTE


def apply_theme(page: ft.Page) -> None:
    """Apply the app theme based on current page.theme_mode.

    Uses Material 3 color scheme seeded by the brand color. Controls should
    avoid hard-coded colors and rely on theme defaults.
    """
    page.theme = ft.Theme(
        color_scheme_seed=BRIGHT_ORANGE,
        use_material3=True,
    )
    # Let Flet compute background/surfaces by theme; keep common defaults
    page.scroll = ft.ScrollMode.AUTO
