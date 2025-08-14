import flet as ft
from typing import Dict

def get_palette(mode: ft.ThemeMode | None) -> Dict[str, str]:
    """
    Return color palette by theme mode.
    
    Args:
        mode: The current theme mode (light/dark)
        
    Returns:
        Dict[str, str]: Color palette for the specified theme mode
    """
    from config import DARK_PALETTE, LIGHT_PALETTE
    return DARK_PALETTE if mode == ft.ThemeMode.DARK else LIGHT_PALETTE

def apply_theme(page: ft.Page) -> None:
    """
    Apply the app theme based on current page.theme_mode.

    Uses Material 3 color scheme seeded by the brand color. Controls should
    avoid hard-coded colors and rely on theme defaults.
    
    Args:
        page: The Flet page to apply the theme to
    """
    from config import BRIGHT_ORANGE
    
    page.theme = ft.Theme(
        color_scheme_seed=BRIGHT_ORANGE,
        use_material3=True,
    )
    # Enable adaptive UI (platform-specific look & feel for controls)
    page.adaptive = True
    # Let Flet compute background/surfaces by theme; keep common defaults
    page.scroll = ft.ScrollMode.AUTO
