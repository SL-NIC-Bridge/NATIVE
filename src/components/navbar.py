import flet as ft
from config import APP_TITLE

def create_navbar(page: ft.Page) -> ft.AppBar:
    def change_route(e: ft.ControlEvent):
        route = e.control.data
        if route:
            page.go(route)

    # Rely on theme for colors (title defaults to onSurface, AppBar bg to surface)
    return ft.AppBar(
        title=ft.Text(APP_TITLE),
        center_title=False,
        actions=[
            ft.TextButton(
                "Home",
                data="/home",
                on_click=change_route,
            ),
            ft.TextButton(
                "Settings",
                data="/settings",
                on_click=change_route,
            ),
        ],
    )