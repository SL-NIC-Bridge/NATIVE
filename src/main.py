import flet as ft
from typing import Dict, Callable

from components.navbar import create_navbar, create_bottom_nav
from pages.home import home_body
from pages.settings import settings_body
from pages.application import application_body
from utils.theme_utils import apply_theme
from config import APP_TITLE, ROUTES
from models.routes import RouteConfig
from utils.route_utils import (
    get_route_config,
    get_route_by_index,
    get_default_route
)

def main(page: ft.Page):
    page.title = APP_TITLE
    page.theme_mode = ft.ThemeMode.LIGHT
    apply_theme(page)
    # Ensure the page background adapts with theme (helps on Android)
    page.bgcolor = ft.Colors.SURFACE

    # Use themed surface color so background adapts to light/dark.
    body_container = ft.Container(expand=True, bgcolor=ft.Colors.SURFACE)

    # Map route paths to their corresponding body functions
    body_functions = {
        "/home": home_body,
        "/application": application_body,
        "/settings": settings_body
    }

    def set_tab(index: int):
        """Set the current tab based on the index."""
        if route := get_route_by_index(index):
            body_container.content = body_functions[route["path"]](page)
            nav.selected_index = index
            page.update()

    def route_change(route: str):
        """Handle route changes and update the view accordingly."""
        # Get the route config or use default if not found
        route_config = get_route_config(ROUTES, route) or get_default_route(ROUTES)
        
        # Update the body content based on the route
        body_container.content = body_functions.get(
            route_config["path"], 
            lambda _: ft.Text(f"Page {route} not found")
        )(page)
        
        # Update the navigation bar to reflect the current route
        nav.selected_index = route_config["index"]
        page.update()

    # Root view
    root_view = ft.View(
        route="/",
        appbar=create_navbar(page),
        controls=[body_container],
        bgcolor=ft.Colors.SURFACE,
    )

    # Bottom navigation driving content swap
    nav = create_bottom_nav(page, selected_index=0)
    root_view.navigation_bar = nav

    # Set up route change handler
    page.on_route_change = lambda route: route_change(route.route)

    # Mount single view and initialize to Home tab
    page.views.clear()
    page.views.append(root_view)
    route_change(page.route or "/home")


ft.app(main)
