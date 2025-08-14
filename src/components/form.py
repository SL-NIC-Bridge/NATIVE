import flet as ft
import time
from typing import Dict, List, Any, Optional, Callable
from flet import Page

from models.forms import FormConfig, FormSection, FormField, FormState
from utils.form_utils import validate_form, validate_field

class FormBuilder:
    """
    A flexible form builder that supports multi-step forms with validation and file uploads.
    """
    
    def __init__(
        self,
        page: Page,
        config: FormConfig,
        on_submit: Callable[[Dict[str, Any]], None],
        on_cancel: Optional[Callable[[], None]] = None,
    ):
        self.page = page
        self.config = config
        self.on_submit = on_submit
        self.on_cancel = on_cancel
        
        # Initialize form state
        self.state = {
            'current_step': 0,
            'values': {},
            'errors': {},
            'touched': {},
            'is_submitting': False,
            'files': {}
        }
        
        # Initialize form controls and components
        self.controls = {}
        self.error_texts = {}
        self._file_upload_components = {}
        
        # Main container that will hold the current step
        self.main_container = ft.Container()
        
        self._build_form()
    
    def _build_form(self):
        """Initialize form controls and state."""
        # Initialize values from config
        for section in self.config['sections']:
            for field in section['fields']:
                field_key = field['key']
                self.state['values'][field_key] = field.get('default_value', '')
                self.state['touched'][field_key] = False
                
                # Create control and error text for each field
                control = self._create_field_control(field)
                self.controls[field_key] = control
                
                # Create error text component for all field types
                error_text = ft.Text(
                    "",
                    color=ft.Colors.RED,
                    size=12,
                    visible=False
                )
                self.error_texts[field_key] = error_text
        
        # Build initial view
        self._update_view()
    
    def _create_field_control(self, field: FormField) -> ft.Control:
        """Create a form field control based on field type."""
        field_key = field['key']
        
        if field['field_type'] == 'file':
            return self._create_file_upload(field)
        
        # Common properties for input fields
        input_field = ft.TextField(
            label=field['label'],
            value=field.get('default_value', ''),
            hint_text=field.get('placeholder', ''),
            disabled=field.get('disabled', False),
            on_change=lambda e, key=field_key: self._handle_change(key, e.control.value),
            on_blur=lambda e, key=field_key: self._handle_blur(key),
            expand=True,
        )
        
        # Set input type
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
    
    def _create_file_upload(self, field: FormField) -> ft.Column:
        """Create a file upload control."""
        field_key = field['key']
        
        # Initialize file picker
        file_picker = ft.FilePicker()
        self.page.overlay.append(file_picker)
        
        def handle_file_pick(e: ft.FilePickerResultEvent):
            if not e.files:
                return
                
            if field_key not in self.state['files']:
                self.state['files'][field_key] = []
                
            # Add new files
            for file in e.files:
                file_info = {
                    'name': file.name,
                    'path': getattr(file, 'path', file.name),
                    'size': file.size,
                    'mime_type': getattr(file, 'mime_type', 'application/octet-stream'),
                    'id': f"{file.name}_{int(time.time())}"
                }
                self.state['files'][field_key].append(file_info)
            
            # Update UI and validate
            self._update_file_list_display(field_key)
            self._validate_field(field_key)
            self.page.update()
            
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
        
        # Create file list display
        file_list = ft.Column(spacing=8)
        
        # Store references for updates
        self._file_upload_components[field_key] = {
            'button': upload_button,
            'list': file_list,
            'picker': file_picker
        }
        
        # Initial update of file list
        self._update_file_list_display(field_key)
        
        return ft.Column(
            controls=[
                ft.Row(controls=[upload_button]),
                file_list
            ],
            spacing=10
        )
    
    def _update_file_list_display(self, field_key: str):
        """Update the file list display for a file upload field."""
        if field_key not in self._file_upload_components:
            return
            
        file_list_control = self._file_upload_components[field_key]['list']
        files = self.state['files'].get(field_key, [])
        
        if not files:
            file_list_control.controls = []
        else:
            file_list_control.controls = [
                ft.Container(
                    content=ft.Row(
                        controls=[
                            ft.Icon(ft.Icons.INSERT_DRIVE_FILE, size=20),
                            ft.Column(
                                controls=[
                                    ft.Text(file_info['name'], size=14, weight=ft.FontWeight.BOLD),
                                    ft.Text(f"{file_info['size']} bytes", size=12, color=ft.Colors.GREY_600)
                                ],
                                spacing=2,
                                expand=True
                            ),
                            ft.IconButton(
                                icon=ft.Icons.DELETE,
                                icon_color=ft.Colors.RED_400,
                                tooltip="Remove file",
                                on_click=lambda e, key=field_key, idx=idx: self._remove_file(key, idx)
                            )
                        ],
                        alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
                        vertical_alignment=ft.CrossAxisAlignment.CENTER,
                    ),
                    padding=8,
                    border=ft.border.all(1, ft.Colors.GREY_300),
                    border_radius=8,
                    bgcolor=ft.Colors.GREY_50
                )
                for idx, file_info in enumerate(files)
            ]
    
    def _remove_file(self, field_key: str, file_index: int):
        """Remove a file from the file list."""
        if field_key in self.state['files'] and len(self.state['files'][field_key]) > file_index:
            self.state['files'][field_key].pop(file_index)
            self._update_file_list_display(field_key)
            self._validate_field(field_key)
            self.page.update()
    
    def _handle_change(self, field_key: str, value: Any):
        """Handle field value changes."""
        self.state['values'][field_key] = value
        # Clear error when user starts typing
        if field_key in self.state['errors']:
            del self.state['errors'][field_key]
            self._update_field_error(field_key)
        self.page.update()
    
    def _handle_blur(self, field_key: str):
        """Handle field blur events."""
        self.state['touched'][field_key] = True
        self._validate_field(field_key)
        self.page.update()
    
    def _validate_field(self, field_key: str):
        """Validate a single field and update error state."""
        # Find the field config
        field_config = None
        for section in self.config['sections']:
            for field in section['fields']:
                if field['key'] == field_key:
                    field_config = field
                    break
            if field_config:
                break
                
        if not field_config:
            return
            
        # Get field value - handle file fields differently
        if field_config['field_type'] == 'file':
            field_value = self.state['files'].get(field_key, [])
        else:
            field_value = self.state['values'].get(field_key, '')
            
        # Validate the field
        error = validate_field(field_config, field_value, self.state['files'])
        
        # Update error state
        if error:
            self.state['errors'][field_key] = error
        elif field_key in self.state['errors']:
            del self.state['errors'][field_key]
        
        # Update UI
        self._update_field_error(field_key)
    
    def _update_field_error(self, field_key: str):
        """Update the error display for a field."""
        if field_key not in self.error_texts:
            return
            
        error_text = self.error_texts[field_key]
        error = self.state['errors'].get(field_key, '')
        is_touched = self.state['touched'].get(field_key, False)
        
        # Show error if the field has been touched and has an error
        if is_touched and error:
            error_text.value = error
            error_text.visible = True
            
            # Also update the control's border color if it's a text field
            if field_key in self.controls:
                control = self.controls[field_key]
                if hasattr(control, 'border_color'):
                    control.border_color = ft.Colors.RED
        else:
            error_text.value = ""
            error_text.visible = False
            
            # Reset border color
            if field_key in self.controls:
                control = self.controls[field_key]
                if hasattr(control, 'border_color'):
                    control.border_color = None
    
    def _go_to_step(self, step: int):
        """Navigate to a specific step in the form."""
        if 0 <= step < len(self.config['sections']):
            self.state['current_step'] = step
            self._update_view()
    
    def _update_view(self):
        """Update the main container with the current step content."""
        current_step = self.state['current_step']
        current_section = self.config['sections'][current_step]
        
        # Create step indicator
        step_indicators = []
        for i in range(len(self.config['sections'])):
            if i == current_step:
                indicator = ft.Container(
                    content=ft.Text(str(i + 1), color=ft.Colors.WHITE, weight=ft.FontWeight.BOLD),
                    width=35,
                    height=35,
                    border_radius=17.5,
                    alignment=ft.alignment.center,
                    bgcolor=ft.Colors.BLUE_500,
                )
            elif i < current_step:
                indicator = ft.Container(
                    content=ft.Icon(ft.Icons.CHECK, color=ft.Colors.WHITE, size=20),
                    width=35,
                    height=35,
                    border_radius=17.5,
                    alignment=ft.alignment.center,
                    bgcolor=ft.Colors.GREEN_500,
                )
            else:
                indicator = ft.Container(
                    content=ft.Text(str(i + 1), color=ft.Colors.GREY_600),
                    width=35,
                    height=35,
                    border_radius=17.5,
                    alignment=ft.alignment.center,
                    bgcolor=ft.Colors.GREY_200,
                    border=ft.border.all(2, ft.Colors.GREY_300)
                )
            step_indicators.append(indicator)
        
        step_indicator_row = ft.Row(
            controls=step_indicators,
            alignment=ft.MainAxisAlignment.CENTER,
            spacing=20
        )
        
        # Create form fields for current step
        field_controls = []
        for field in current_section['fields']:
            field_key = field['key']
            field_control = self.controls[field_key]
            error_text = self.error_texts[field_key]
            
            # Update field values from state
            if hasattr(field_control, 'value') and field['field_type'] != 'file':
                field_control.value = self.state['values'].get(field_key, '')
            
            # Update error display
            self._update_field_error(field_key)
            
            field_controls.append(
                ft.Column(
                    controls=[field_control, error_text],
                    spacing=4
                )
            )
        
        # Navigation buttons
        buttons = []
        
        # Add cancel button if handler provided
        if self.on_cancel:
            buttons.append(
                ft.TextButton(
                    self.config.get('cancel_text', 'Cancel'),
                    on_click=lambda _: self.on_cancel(),
                    style=ft.ButtonStyle(color=ft.Colors.GREY_600)
                )
            )
        
        # Previous button
        if current_step > 0:
            buttons.append(
                ft.ElevatedButton(
                    "Previous",
                    on_click=self._handle_previous,
                    style=ft.ButtonStyle(
                        color=ft.Colors.BLUE_500,
                        bgcolor=ft.Colors.WHITE,
                        side=ft.border.BorderSide(1, ft.Colors.BLUE_500)
                    ),
                    disabled=self.state['is_submitting']
                )
            )
        
        # Next/Submit button
        if current_step < len(self.config['sections']) - 1:
            buttons.append(
                ft.ElevatedButton(
                    "Next",
                    on_click=self._handle_next,
                    style=ft.ButtonStyle(
                        bgcolor=ft.Colors.BLUE_500,
                        color=ft.Colors.WHITE
                    ),
                    disabled=self.state['is_submitting']
                )
            )
        else:
            submit_text = "Submitting..." if self.state['is_submitting'] else "Submit"
            buttons.append(
                ft.ElevatedButton(
                    submit_text,
                    on_click=lambda _: self._handle_submit(),
                    style=ft.ButtonStyle(
                        bgcolor=ft.Colors.GREEN_500,
                        color=ft.Colors.WHITE
                    ),
                    disabled=self.state['is_submitting']
                )
            )
        
        # Create button row
        if len(buttons) == 1:
            button_alignment = ft.MainAxisAlignment.END
        else:
            button_alignment = ft.MainAxisAlignment.SPACE_BETWEEN
            
        button_row = ft.Row(
            controls=buttons,
            alignment=button_alignment,
            spacing=10
        )
        
        # Create form content
        content_controls = [
            step_indicator_row,
        ]
        
        # Add section title and description
        if current_section.get('title'):
            content_controls.append(
                ft.Text(
                    current_section['title'],
                    size=24,
                    weight=ft.FontWeight.BOLD,
                    text_align=ft.TextAlign.CENTER
                )
            )
        
        if current_section.get('description'):
            content_controls.append(
                ft.Text(
                    current_section['description'],
                    color=ft.Colors.GREY_600,
                    size=16,
                    text_align=ft.TextAlign.CENTER
                )
            )
        
        content_controls.extend([
            ft.Divider(height=20),
            *field_controls,
            ft.Divider(height=30),
            button_row
        ])
        
        # Update main container
        self.main_container.content = ft.Column(
            controls=content_controls,
            spacing=20,
            expand=True,
            scroll=ft.ScrollMode.AUTO
        )
        self.main_container.padding = 30
        self.main_container.expand = True
        
        # Update page
        self.page.update()
    
    def _handle_next(self, e):
        """Handle next button click."""
        # Validate current step before proceeding
        current_section = self.config['sections'][self.state['current_step']]
        field_keys = [field['key'] for field in current_section['fields']]
        
        # Mark all fields in current step as touched and validate
        has_errors = False
        for key in field_keys:
            self.state['touched'][key] = True
            self._validate_field(key)
            if key in self.state['errors']:
                has_errors = True
        
        if not has_errors:
            # Move to next step
            next_step = self.state['current_step'] + 1
            if next_step < len(self.config['sections']):
                self._go_to_step(next_step)
        else:
            # Update UI to show validation errors
            self._update_view()
    
    def _handle_previous(self, e):
        """Handle previous button click."""
        if self.state['current_step'] > 0:
            self._go_to_step(self.state['current_step'] - 1)
    
    def _handle_submit(self):
        """Handle form submission."""
        if self.state['is_submitting']:
            return
            
        # Validate all fields before submission
        all_errors = {}
        for section in self.config['sections']:
            for field in section['fields']:
                field_key = field['key']
                self.state['touched'][field_key] = True
                self._validate_field(field_key)
                if field_key in self.state['errors']:
                    all_errors[field_key] = self.state['errors'][field_key]
        
        if all_errors:
            # If there are errors, go to the first step with an error
            for i, section in enumerate(self.config['sections']):
                if any(field['key'] in all_errors for field in section['fields']):
                    self._go_to_step(i)
                    break
            return
        
        # Prepare form data
        form_data = self.state['values'].copy()
        if self.state['files']:
            form_data['_files'] = self.state['files']
        
        # Set submitting state
        self.state['is_submitting'] = True
        self._update_view()
        
        try:
            self.on_submit(form_data)
        except Exception as e:
            # Handle submission error
            print(f"Form submission error: {e}")
            # You might want to show an error message to the user here
        finally:
            self.state['is_submitting'] = False
            self._update_view()
    
    def get_form_data(self) -> Dict[str, Any]:
        """Get current form data."""
        form_data = self.state['values'].copy()
        if self.state['files']:
            form_data['_files'] = self.state['files']
        return form_data
    
    def reset_form(self):
        """Reset the form to initial state."""
        self.state['current_step'] = 0
        self.state['errors'] = {}
        self.state['touched'] = {}
        self.state['is_submitting'] = False
        
        # Reset values to defaults
        for section in self.config['sections']:
            for field in section['fields']:
                field_key = field['key']
                self.state['values'][field_key] = field.get('default_value', '')
                self.state['touched'][field_key] = False
                
        # Clear files
        self.state['files'] = {}
        for field_key in self._file_upload_components:
            self._update_file_list_display(field_key)
        
        self._update_view()
    
    def build(self) -> ft.Control:
        """Build and return the form UI."""
        return self.main_container