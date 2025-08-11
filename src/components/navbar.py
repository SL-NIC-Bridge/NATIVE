import flet as ft
from config import APP_TITLE, get_palette

def create_navbar(page: ft.Page) -> ft.AppBar:
    def change_route(e: ft.ControlEvent):
        route = e.control.data
        if route:
            page.go(route)

    palette = get_palette(page.theme_mode)

    return ft.AppBar(
        title=ft.Text(APP_TITLE, color=palette["on_background"]),
        center_title=False,
        bgcolor=palette["surface"],
        actions=[
            ft.TextButton(
                "Home",
                data="/home",
                on_click=change_route,
                style=ft.ButtonStyle(color=palette["primary"]),
            ),
            ft.TextButton(
                "Settings",
                data="/settings",
                on_click=change_route,
                style=ft.ButtonStyle(color=palette["primary"]),
            ),
        ],
    )