import flet as ft
from components.form import FormBuilder
from config import FORM_CONFIG

def handle_form_submit(data: dict):
    """Handle form submission."""
    print("Form submitted with data:", data)
    # Here you would typically send the data to your backend
    # For example:
    # response = api.submit_application(data)
    # Handle the response

def application_body(page: ft.Page) -> ft.Control:
    """Return Application page with a multi-step form."""
    # Create the form instance
    form = FormBuilder(
        page=page,
        config=FORM_CONFIG,
        on_submit=handle_form_submit,
        on_cancel=lambda: page.go("/")  # Go to home on cancel
    )
    
    # Build the form UI
    form_ui = form.get_form_container()
    
    # Create a scrollable column for the form
    form_content = ft.Column(
        [
            ft.Container(
                content=ft.Column(
                    [
                        ft.Text("Please fill out the form below to submit your application.",
                              color=ft.Colors.GREY_600),
                        ft.Divider(),
                        form_ui
                    ],
                    spacing=16,
                ),
                padding=ft.padding.symmetric(horizontal=16, vertical=8),
            )
        ],
        expand=True,
        scroll=ft.ScrollMode.AUTO,
    )
    
    # Wrap in a container that will handle the keyboard
    return ft.Container(
        content=form_content,
        expand=True,
        padding=ft.padding.only(bottom=20),  # Add some bottom padding for better mobile experience
    )
