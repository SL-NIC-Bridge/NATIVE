import flet as ft
from typing import Callable, Optional, List

from config import APP_TITLE, ROUTES
from models.routes import RouteConfig
from utils.route_utils import (
    get_route_by_index,
    get_route_config,
    get_default_route
)

def create_navbar(page: ft.Page, compact: bool = False) -> ft.AppBar:
    # Rely on theme for colors (title defaults to onSurface, AppBar bg to surface)
    # Title-only AppBar; navigation handled by bottom NavigationBar
    return ft.AppBar(
        title=ft.Text(APP_TITLE),
        center_title=False,
        actions=None,
    )


def create_nav_destinations() -> List[ft.NavigationBarDestination]:
    """Create navigation bar destinations from route configurations."""
    return [
        ft.NavigationBarDestination(
            icon=route["icon"],
            selected_icon=route["selected_icon"],
            label=route["label"]
        )
        for route in sorted(ROUTES, key=lambda r: r["index"])
        if route.get("index") is not None  # Only include routes that should be in the nav
    ]

def create_bottom_nav(
    page: ft.Page,
    selected_index: int,
    on_change: Optional[Callable[[ft.ControlEvent], None]] = None,
) -> ft.NavigationBar:
    """Create a bottom navigation bar with proper selection and routing.

    Uses centralized route configurations for consistency.
    """
    def default_on_change(e: ft.ControlEvent):
        if route := get_route_by_index(ROUTES, e.control.selected_index):
            page.go(route["path"])
        else:
            # Fallback to default route if index is invalid
            default = get_default_route(ROUTES)
            page.go(default["path"])
            e.control.selected_index = default["index"]

    return ft.NavigationBar(
        selected_index=selected_index,
        destinations=create_nav_destinations(),
        on_change=on_change or default_on_change,
    )