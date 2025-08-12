import flet as ft


def home_body(page: ft.Page) -> ft.Control:
    """Return Home page content control (doc-aligned body container pattern)."""
    primary_btn = ft.ElevatedButton("Primary Action")
    secondary_btn = ft.OutlinedButton("Secondary")
    card = ft.Card(
        content=ft.Container(
            padding=16,
            content=ft.Column(
                [
                    ft.Text("Branded Card", size=20, weight=ft.FontWeight.BOLD),
                    ft.Text("Uses themed surface and text."),
                ],
                tight=True,
                spacing=6,
            ),
        )
    )
    return ft.SafeArea(
        ft.Column(
            [
                ft.Text("Home", size=28, weight=ft.FontWeight.BOLD),
                ft.Text("Welcome to the SL NIC Bridge app."),
                ft.Divider(),
                card,
                ft.Row([primary_btn, secondary_btn], spacing=10),
            ],
            expand=True,
            alignment=ft.MainAxisAlignment.START,
            horizontal_alignment=ft.CrossAxisAlignment.START,
        ),
        expand=True,
    )
