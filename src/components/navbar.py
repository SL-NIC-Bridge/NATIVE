import flet as ft
from typing import Callable, Optional
from config import APP_TITLE

def create_navbar(page: ft.Page, compact: bool = False) -> ft.AppBar:
    # Rely on theme for colors (title defaults to onSurface, AppBar bg to surface)
    # Title-only AppBar; navigation handled by bottom NavigationBar
    return ft.AppBar(
        title=ft.Text(APP_TITLE),
        center_title=False,
        actions=None,
    )


def create_bottom_nav(
    page: ft.Page,
    selected_index: int,
    on_change: Optional[Callable[[ft.ControlEvent], None]] = None,
) -> ft.NavigationBar:
    """Create a bottom navigation bar with proper selection and routing.

    Icons are specified as strings for compatibility across Flet versions.
    """
    def default_on_change(e: ft.ControlEvent):
        idx = e.control.selected_index
        page.go("/home" if idx == 0 else "/settings")

    return ft.NavigationBar(
        selected_index=selected_index,
        destinations=[
            ft.NavigationBarDestination(icon="home_outlined", selected_icon="home", label="Home"),
            ft.NavigationBarDestination(icon="settings_outlined", selected_icon="settings", label="Settings"),
        ],
        on_change=on_change or default_on_change,
    )