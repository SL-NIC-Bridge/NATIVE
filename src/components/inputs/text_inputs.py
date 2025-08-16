import flet as ft
from typing import Dict, Any

def create_text_input(field: Dict[str, Any], field_key: str, on_change_callback, on_blur_callback) -> ft.Control:
    """Create a text input control based on field type."""
    
    # Common properties for input fields
    input_field = ft.TextField(
        label=field['label'],
        value=field.get('default_value', ''),
        hint_text=field.get('placeholder', ''),
        disabled=field.get('disabled', False),
        on_change=lambda e: on_change_callback(field_key, e.control.value),
        on_blur=lambda e: on_blur_callback(field_key),
        expand=True,
    )
    
    # Set input type based on field type
    if field['field_type'] == 'email':
        input_field.keyboard_type = ft.KeyboardType.EMAIL
    elif field['field_type'] == 'number':
        input_field.keyboard_type = ft.KeyboardType.NUMBER
    elif field['field_type'] == 'password':
        input_field.password = True
        input_field.can_reveal_password = True
    elif field['field_type'] == 'textarea':
        input_field.multiline = True
        input_field.min_lines = field.get('rows', 3)
        input_field.max_lines = field.get('max_rows', 10)
    
    return input_field