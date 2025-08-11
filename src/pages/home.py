import flet as ft
from components.navbar import create_navbar
from config import get_palette


def home_view(page: ft.Page) -> ft.View:
    palette = get_palette(page.theme_mode)

    primary_btn = ft.ElevatedButton(
        "Primary Action",
        bgcolor=palette["primary"],
        color=palette["on_primary"],
    )

    secondary_btn = ft.OutlinedButton(
        "Secondary",
        style=ft.ButtonStyle(color=palette["secondary"]),
    )

    card = ft.Container(
        bgcolor=palette["surface"],
        padding=16,
        border_radius=12,
        content=ft.Column(
            [
                ft.Text("Branded Card", size=20, weight=ft.FontWeight.BOLD, color=palette["on_background"]),
                ft.Text("Uses surface background and on-background text.", color=palette["on_background"]),
            ],
            tight=True,
            spacing=6,
        ),
    )

    return ft.View(
        route="/home",
        appbar=create_navbar(page),
        controls=[
            ft.SafeArea(
                ft.Column(
                    [
                        ft.Text("Home", size=28, weight=ft.FontWeight.BOLD, color=palette["on_background"]),
                        ft.Text("Welcome to the SL NIC Bridge app.", color=palette["on_background"]),
                        ft.Divider(color=palette["secondary"]),
                        card,
                        ft.Row([primary_btn, secondary_btn], spacing=10),
                    ],
                    expand=True,
                    alignment=ft.MainAxisAlignment.START,
                    horizontal_alignment=ft.CrossAxisAlignment.START,
                ),
                expand=True,
            )
        ],
    )
