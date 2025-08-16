import flet as ft
from typing import Dict, Any

def create_checkbox_input(field: Dict[str, Any], field_key: str, on_change_callback) -> ft.Control:
    """Create a checkbox input control."""
    
    checkbox = ft.Checkbox(
        label=field['label'],
        value=field.get('default_value', False),
        disabled=field.get('disabled', False),
        on_change=lambda e: on_change_callback(field_key, e.control.value),
    )
    
    return checkbox