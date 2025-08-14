import flet as ft


def application_body(page: ft.Page) -> ft.Control:
    """Return Application page content control (doc-aligned body container pattern)."""
    return ft.SafeArea(
        ft.Column(
            [
                ft.Text("Application", size=28, weight=ft.FontWeight.BOLD),
                ft.Text("This is the Application page."),
                ft.Divider(),
                ft.Text("Application-specific content will go here."),
            ],
            expand=True,
            alignment=ft.MainAxisAlignment.START,
            horizontal_alignment=ft.CrossAxisAlignment.START,
        ),
        expand=True,
    )
