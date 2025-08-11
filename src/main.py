import flet as ft

from components.navbar import create_navbar
from pages.home import home_view
from pages.settings import settings_view
from config import APP_TITLE, apply_theme


def main(page: ft.Page):
    page.title = APP_TITLE
    page.theme_mode = ft.ThemeMode.LIGHT
    apply_theme(page)

    def route_change(e: ft.RouteChangeEvent):
        # Re-apply theme to reflect current mode and palette colors
        apply_theme(page)
        page.views.clear()
        if page.route in ("/", "/home"):
            page.views.append(home_view(page))
        elif page.route == "/settings":
            page.views.append(settings_view(page))
        else:
            # 404 fallback
            page.views.append(
                ft.View(
                    route=page.route,
                    appbar=create_navbar(page),
                    controls=[
                        ft.SafeArea(
                            ft.Column(
                                [
                                    ft.Text("Page not found", size=24, weight=ft.FontWeight.BOLD),
                                    ft.Text(f"Route: {page.route}"),
                                ],
                                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                                alignment=ft.MainAxisAlignment.CENTER,
                                expand=True,
                            ),
                            expand=True,
                        )
                    ],
                )
            )
        page.update()

    def view_pop(e: ft.ViewPopEvent):
        # Handle back navigation (Android back button / programmatic pops)
        page.views.pop()
        if page.views:
            page.go(page.views[-1].route)

    page.on_route_change = route_change
    page.on_view_pop = view_pop

    # Go to the initial route (preserves hot-reload route when available)
    page.go(page.route if page.route else "/")


ft.app(main)
