import flet as ft
from utils.theme_utils import apply_theme

def settings_body(page: ft.Page) -> ft.Control:
    """Return Settings page content control (doc-aligned body container pattern)."""
    theme_switch = ft.Switch(label="Dark mode", value=page.theme_mode == ft.ThemeMode.DARK)

    def toggle_theme(e: ft.ControlEvent):
        page.theme_mode = ft.ThemeMode.DARK if theme_switch.value else ft.ThemeMode.LIGHT
        apply_theme(page)
        page.update()

    theme_switch.on_change = toggle_theme

    return ft.SafeArea(
        ft.Column(
            [
                ft.Text("Adjust your application settings below.", color=ft.Colors.GREY_600),
                ft.Divider(),
                theme_switch,
            ],
            expand=True,
            alignment=ft.MainAxisAlignment.START,
            horizontal_alignment=ft.CrossAxisAlignment.START,
        ),
        expand=True,
    )
