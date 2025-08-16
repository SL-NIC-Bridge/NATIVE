import flet as ft
from typing import Dict, List, Any, Optional, Callable
from flet import Page

from models.forms import FormConfig, FormSection, FormField, FormState
from utils.form_utils import validate_form, validate_field


class FormBuilder:
    """
    Pure form state manager - no UI component logic.
    All field-specific logic is handled by input components.
    """
    
    def __init__(
        self,
        page: Page,
        config: FormConfig,
        on_submit: Callable[[Dict[str, Any]], None],
        on_cancel: Optional[Callable[[], None]] = None,
        auto_validate: bool = True,
    ):
        self.page = page
        self.config = config
        self.on_submit = on_submit
        self.on_cancel = on_cancel
        self.auto_validate = auto_validate
        
        # Initialize state
        self.state = self._initialize_state()
        
        # Component storage - just references
        self.controls = {}
        self.error_texts = {}
        
        # Main container
        self.main_container = ft.Container(expand=True)
        
        # Build the form
        self._create_all_controls()
        self._render_current_step()
    
    def _initialize_state(self) -> Dict[str, Any]:
        """Initialize form state with default values."""
        initial_values = {}
        
        for section in self.config['sections']:
            for field in section['fields']:
                field_key = field['key']
                default_value = field.get('default_value')
                
                if default_value is not None:
                    initial_values[field_key] = default_value
                else:
                    # Set appropriate defaults by field type
                    field_type = field['field_type']
                    if field_type == 'checkbox':
                        initial_values[field_key] = False
                    elif field_type == 'number':
                        initial_values[field_key] = 0
                    else:
                        initial_values[field_key] = ''
        
        return {
            'current_step': 0,
            'values': initial_values,
            'errors': {},
            'touched': {},
            'is_submitting': False,
            'files': {}
        }
    
    def _create_all_controls(self):
        """Create all form controls by delegating to input components."""
        for section in self.config['sections']:
            for field in section['fields']:
                field_key = field['key']
                
                # Create the field control - pure delegation
                control = self._create_field_control(field)
                self.controls[field_key] = control
                
                # Create error text display
                error_text = ft.Text(
                    "",
                    color=ft.Colors.RED,
                    size=12,
                    visible=False
                )
                self.error_texts[field_key] = error_text
    
    def _create_field_control(self, field: FormField) -> ft.Control:
        """
        Pure delegation to input components.
        FormBuilder provides only generic callbacks.
        """
        from .inputs import (
            create_text_input, 
            create_file_upload, 
            create_signature_field, 
            create_checkbox_input
        )
        
        field_key = field['key']
        field_type = field['field_type']
        
        # Generic callbacks that work for ANY field type
        change_callback = lambda key, value: self.handle_field_change(key, value)
        blur_callback = lambda key: self.handle_field_blur(key)
        validate_callback = lambda key: self.validate_field_on_change(key)
        
        # Simple delegation - no field-specific logic here
        if field_type in ['text', 'email', 'number', 'password', 'textarea']:
            return create_text_input(field, field_key, change_callback, blur_callback)
        
        elif field_type == 'checkbox':
            return create_checkbox_input(field, field_key, change_callback)
        
        elif field_type == 'file':
            return create_file_upload(
                field, field_key, self.page, self.state,
                change_callback, validate_callback
            )
        
        elif field_type == 'signature':
            return create_signature_field(
                field, field_key, self.page, self.state,
                change_callback, validate_callback
            )
        
        else:
            # Default to text input
            return create_text_input(field, field_key, change_callback, blur_callback)
    
    # ===============================
    # GENERIC EVENT HANDLERS
    # ===============================
    
    def handle_field_change(self, field_key: str, value: Any):
        """Generic handler for ANY field value change."""
        self.state['values'][field_key] = value
        self.state['touched'][field_key] = True
        
        # Auto-validate if enabled and field was previously invalid
        if self.auto_validate and field_key in self.state['errors']:
            self._validate_single_field(field_key)
        
        self.page.update()
    
    def handle_field_blur(self, field_key: str):
        """Generic handler for ANY field blur event."""
        self.state['touched'][field_key] = True
        
        if self.auto_validate:
            self._validate_single_field(field_key)
    
    def validate_field_on_change(self, field_key: str):
        """Generic validation trigger - can be called by any component."""
        if self.auto_validate:
            self._validate_single_field(field_key)
    
    # ===============================
    # VALIDATION METHODS
    # ===============================
    
    def _validate_single_field(self, field_key: str) -> bool:
        """Validate a single field and update error display."""
        field = self._get_field_by_key(field_key)
        if not field:
            return True
        
        value = self.state['values'].get(field_key)
        error = validate_field(field, value, self.state['files'])
        
        # Update state
        if error:
            self.state['errors'][field_key] = error
        else:
            self.state['errors'].pop(field_key, None)
        
        # Update error display
        self._update_error_display(field_key)
        return not bool(error)
    
    def _validate_current_step(self) -> bool:
        """Validate all fields in the current step."""
        current_section = self.config['sections'][self.state['current_step']]
        is_valid = True
        
        for field in current_section['fields']:
            field_key = field['key']
            self.state['touched'][field_key] = True
            
            if not self._validate_single_field(field_key):
                is_valid = False
        
        self.page.update()
        return is_valid
    
    def _validate_all_fields(self) -> bool:
        """Validate the entire form."""
        all_fields = []
        for section in self.config['sections']:
            all_fields.extend(section['fields'])
        
        errors = validate_form(all_fields, self.state['values'], self.state['files'])
        
        # Update state
        self.state['errors'] = errors
        
        # Mark all fields as touched and update displays
        for field in all_fields:
            field_key = field['key']
            self.state['touched'][field_key] = True
            self._update_error_display(field_key)
        
        self.page.update()
        return len(errors) == 0
    
    def _get_field_by_key(self, field_key: str) -> Optional[FormField]:
        """Find field configuration by key."""
        for section in self.config['sections']:
            for field in section['fields']:
                if field['key'] == field_key:
                    return field
        return None
    
    def _update_error_display(self, field_key: str):
        """Update error text visibility and content."""
        if field_key not in self.error_texts:
            return
        
        error = self.state['errors'].get(field_key, "")
        error_text = self.error_texts[field_key]
        
        error_text.value = error
        error_text.visible = bool(error and self.state['touched'][field_key])
    
    # ===============================
    # UI RENDERING (minimal)
    # ===============================
    
    def _render_current_step(self):
        """Render the current form step."""
        current_section = self.config['sections'][self.state['current_step']]
        
        # Build form fields for current step
        field_components = []
        for field in current_section['fields']:
            field_key = field['key']
            
            # Simple container: control + error
            field_container = ft.Column([
                self.controls[field_key],
                self.error_texts[field_key]
            ], spacing=5)
            
            field_components.append(field_container)
        
        # Build navigation and header components
        header = self._build_step_header(current_section)
        navigation = self._build_navigation_buttons()
        
        # Assemble form
        form_content = ft.Column([
            header,
            ft.Divider(),
            *field_components,
            ft.Container(height=20),  # Spacer
            navigation
        ], spacing=20, scroll=ft.ScrollMode.AUTO)
        
        self.main_container.content = form_content
        self.page.update()
    
    def _build_step_header(self, current_section: FormSection) -> ft.Control:
        """Render centered step indicators (numbers). Completed steps show a check."""
        current_index = self.state['current_step']
        sections = self.config.get('sections', [])
        total_steps = len(sections)

        indicators: list[ft.Control] = []
        for i in range(total_steps):
            # Completed
            if i < current_index:
                avatar = ft.CircleAvatar(
                    content=ft.Icon(ft.Icons.CHECK, size=16, color=ft.Colors.WHITE),
                    bgcolor=ft.Colors.GREEN, 
                    radius=16,
                    tooltip=sections[i].get('title', '') if isinstance(sections[i], dict) else ''
                )
            # Current
            elif i == current_index:
                avatar = ft.CircleAvatar(
                    content=ft.Text(str(i + 1), size=14, weight=ft.FontWeight.BOLD, color=ft.Colors.WHITE),
                    bgcolor=ft.Colors.BLUE,
                    radius=16,
                    tooltip=sections[i].get('title', '') if isinstance(sections[i], dict) else ''
                )
            # Pending
            else:
                avatar = ft.CircleAvatar(
                    content=ft.Text(str(i + 1), size=14, weight=ft.FontWeight.BOLD, color=ft.Colors.BLACK),
                    bgcolor=ft.Colors.GREY_300,
                    radius=16,
                    tooltip=sections[i].get('title', '') if isinstance(sections[i], dict) else ''
                )

            indicators.append(avatar)
            # Add spacing between avatars
            if i < total_steps - 1:
                indicators.append(ft.Container(width=12))

        return ft.Container(
            content=ft.Row(indicators, alignment=ft.MainAxisAlignment.CENTER),
            padding=ft.padding.symmetric(vertical=8)
        )
    
    def _build_navigation_buttons(self) -> ft.Control:
        """Build navigation button row."""
        is_last_step = self.state['current_step'] == len(self.config['sections']) - 1
        
        return ft.Row([
            ft.ElevatedButton(
                "Previous",
                on_click=self._handle_previous,
                visible=self.state['current_step'] > 0,
                icon=ft.Icons.ARROW_BACK
            ),
            ft.ElevatedButton(
                "Next",
                on_click=self._handle_next,
                visible=not is_last_step,
                icon=ft.Icons.ARROW_FORWARD
            ),
            ft.ElevatedButton(
                "Submit",
                on_click=self._handle_submit,
                visible=is_last_step,
                disabled=self.state['is_submitting'],
                icon=ft.Icons.SEND
            ),
            ft.TextButton(
                "Cancel",
                on_click=lambda _: self.on_cancel() if self.on_cancel else None,
                icon=ft.Icons.CANCEL
            )
        ], alignment=ft.MainAxisAlignment.END, spacing=10)
    
    # ===============================
    # NAVIGATION EVENT HANDLERS
    # ===============================
    
    def _handle_previous(self, _):
        """Navigate to previous step."""
        if self.state['current_step'] > 0:
            self.state['current_step'] -= 1
            self._render_current_step()
    
    def _handle_next(self, _):
        """Navigate to next step with validation."""
        if self._validate_current_step():
            if self.state['current_step'] < len(self.config['sections']) - 1:
                self.state['current_step'] += 1
                self._render_current_step()

    def _prepare_submission_data(self) -> Dict[str, Any]:
        """Simple signature processing using stored state data."""
        submission_data = self.state['values'].copy()
        
        # Process signature fields
        for section in self.config['sections']:
            for field in section['fields']:
                if field['field_type'] == 'signature':
                    field_key = field['key']
                    value = self.state['values'].get(field_key, '')
                    
                    if value:  # Has signature
                        # Import the helper function
                        from .inputs.signature_inputs import get_signature_image_bytes
                        
                        # Get image bytes - works for both drawn and uploaded
                        img_bytes = get_signature_image_bytes(field_key, self.state)
                        
                        # Replace string value with image data
                        submission_data[field_key] = {
                            'type': 'signature',
                            'data': img_bytes or b'',
                            'format': 'PNG'
                        }
        
        return submission_data
    
    def _handle_submit(self, _):
        """Handle form submission with signature data."""
        self.state['is_submitting'] = True
        self._render_current_step()
        
        try:
            if self._validate_all_fields():
                # Prepare submission data with signature images
                submission_data = self._prepare_submission_data()
                self.on_submit(submission_data)  # Pass enhanced data
        except Exception as e:
            print(f"Form submission error: {e}")
        finally:
            self.state['is_submitting'] = False
            self._render_current_step()
    
    # ===============================
    # PUBLIC API
    # ===============================
    
    def get_form_container(self) -> ft.Container:
        """Get the main form container."""
        return self.main_container
    
    def get_form_state(self) -> Dict[str, Any]:
        """Get current form state."""
        return self.state.copy()
    
    def set_field_value(self, field_key: str, value: Any):
        """Programmatically set a field value."""
        if field_key in self.state['values']:
            self.handle_field_change(field_key, value)
    
    def get_field_value(self, field_key: str) -> Any:
        """Get current field value."""
        return self.state['values'].get(field_key)
    
    def clear_form(self):
        """Reset form to initial state."""
        self.state = self._initialize_state()
        
        # Clear all error displays
        for error_text in self.error_texts.values():
            error_text.value = ""
            error_text.visible = False
        
        self._render_current_step()
    
    def validate_form(self) -> bool:
        """Manually trigger form validation."""
        return self._validate_all_fields()
    
    def go_to_step(self, step_index: int):
        """Navigate to specific step."""
        if 0 <= step_index < len(self.config['sections']):
            if step_index > self.state['current_step']:
                if not self._validate_current_step():
                    return False
            
            self.state['current_step'] = step_index
            self._render_current_step()
            return True
        return False