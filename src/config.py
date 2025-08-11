from typing import Dict
import flet as ft

# Static product details
APP_TITLE: str = "SL NIC Bridge"

# Brand colors
BRIGHT_ORANGE: str = "#FF7A00"  # bright orange
BROWN: str = "#795548"           # material brown 500

# Palettes for light and dark modes
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
    """Return color palette by theme mode."""
    return DARK_PALETTE if mode == ft.ThemeMode.DARK else LIGHT_PALETTE


def apply_theme(page: ft.Page) -> None:
    """Apply background/foreground colors based on current page.theme_mode."""
    palette = get_palette(page.theme_mode)
    # Set page-level colors using hex strings
    page.bgcolor = palette["background"]
    page.scroll = ft.ScrollMode.AUTO
