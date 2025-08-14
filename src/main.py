import flet as ft

from components.navbar import create_navbar, create_bottom_nav
from pages.home import home_body
from pages.settings import settings_body
from utils.theme_utils import apply_theme
from config import APP_TITLE

def main(page: ft.Page):
    page.title = APP_TITLE
    page.theme_mode = ft.ThemeMode.LIGHT
    apply_theme(page)
    # Ensure the page background adapts with theme (helps on Android)
    page.bgcolor = ft.Colors.SURFACE

    # Use themed surface color so background adapts to light/dark.
    body_container = ft.Container(expand=True, bgcolor=ft.Colors.SURFACE)

    def set_tab(index: int):
        if index == 0:
            body_container.content = home_body(page)
        else:
            body_container.content = settings_body(page)
        nav.selected_index = index
        page.update()

    # Root view
    root_view = ft.View(
        route="/",
        appbar=create_navbar(page),
        controls=[body_container],
        bgcolor=ft.Colors.SURFACE,
    )

    # Bottom navigation driving content swap
    nav = create_bottom_nav(page, selected_index=0, on_change=lambda e: set_tab(e.control.selected_index))
    root_view.navigation_bar = nav

    # Mount single view and initialize to Home tab
    page.views.clear()
    page.views.append(root_view)
    set_tab(0)


ft.app(main)
