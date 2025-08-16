import flet as ft
import time
from typing import Dict, Any, Callable

def create_file_upload(
    field: Dict[str, Any], 
    field_key: str, 
    page: ft.Page, 
    state: Dict[str, Any],
    handle_change_callback: Callable,
    validate_callback: Callable
) -> ft.Column:
    """Create a self-contained file upload control with its own list management."""
    
    # Initialize file picker
    file_picker = ft.FilePicker()
    page.overlay.append(file_picker)
    
    # Create file list display
    file_list = ft.Column(spacing=8)
    
    def update_file_list_display():
        """Update the file list display - internal to this component."""
        files = state['files'].get(field_key, [])
        
        if not files:
            file_list.controls = [
                ft.Text("No files uploaded", 
                       size=12, 
                       color=ft.Colors.GREY_500, 
                       italic=True)
            ]
        else:
            file_list.controls = []
            for file in files:
                file_item = ft.Container(
                    content=ft.Row([
                        ft.Icon(ft.Icons.INSERT_DRIVE_FILE, size=20),
                        ft.Column([
                            ft.Text(file['name'], 
                                   size=14, 
                                   weight=ft.FontWeight.BOLD),
                            ft.Text(f"{file.get('size', 0)} bytes", 
                                   size=12, 
                                   color=ft.Colors.GREY_500),
                        ], tight=True, spacing=2),
                        ft.IconButton(
                            icon=ft.Icons.CLOSE,
                            on_click=lambda e, f=file: remove_file(f),
                            tooltip="Remove file"
                        ),
                    ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
                    padding=ft.padding.symmetric(vertical=4, horizontal=8),
                    border=ft.border.all(1, ft.Colors.GREY_300),
                    border_radius=8,
                )
                file_list.controls.append(file_item)
        
        page.update()
    
    def remove_file(file_to_remove: Dict[str, Any]):
        """Remove file from the list - internal logic."""
        files = state['files'].get(field_key, [])
        state['files'][field_key] = [f for f in files if f['id'] != file_to_remove['id']]
        
        # Update form value - let FormBuilder know about the change
        remaining_files = state['files'][field_key]
        if remaining_files:
            # If multiple files allowed, could pass file list or first file path
            handle_change_callback(field_key, remaining_files[0]['path'])
        else:
            handle_change_callback(field_key, '')
        
        # Update our display
        update_file_list_display()
        
        # Trigger validation
        validate_callback(field_key)
    
    def handle_file_pick(e: ft.FilePickerResultEvent):
        """Handle file selection - internal logic."""
        if not e.files:
            return
            
        if field_key not in state['files']:
            state['files'][field_key] = []
            
        # Add new files
        for file in e.files:
            file_info = {
                'name': file.name,
                'path': getattr(file, 'path', file.name),
                'size': file.size,
                'mime_type': getattr(file, 'mime_type', 'application/octet-stream'),
                'id': f"{file.name}_{int(time.time())}"
            }
            
            # Handle multiple vs single file
            if field.get('multiple', True):
                state['files'][field_key].append(file_info)
            else:
                state['files'][field_key] = [file_info]  # Replace existing
        
        # Notify FormBuilder of value change (generic interface)
        files = state['files'][field_key]
        if files:
            # For form value, use first file path or could use file count
            handle_change_callback(field_key, files[0]['path'])
        
        # Update our display
        update_file_list_display()
        
        # Trigger validation
        validate_callback(field_key)
    
    # Set up file picker callback
    file_picker.on_result = handle_file_pick
    
    # Create upload button
    upload_button = ft.ElevatedButton(
        f"Upload {field['label']}",
        on_click=lambda _: file_picker.pick_files(
            allow_multiple=field.get('multiple', True),
            allowed_extensions=field.get('allowed_extensions')
        ),
        icon=ft.Icons.UPLOAD_FILE
    )
    
    # Create the main container
    container = ft.Column(
        controls=[
            ft.Text(field.get('label', ''), weight=ft.FontWeight.BOLD),
            ft.Row(controls=[upload_button]),
            file_list
        ],
        spacing=10
    )
    
    # Initialize display
    update_file_list_display()
    
    return container