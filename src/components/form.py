import flet as ft
import flet.canvas as cv
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
        elif field['field_type'] == 'signature':
            return self._create_signature_field(field)
        
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
    
    def _create_signature_field(self, field: FormField) -> ft.Control:
        """Create a signature field with canvas drawing and optional image upload."""
        field_key = field['key']
        canvas_width = field.get('canvas_width', 400)
        canvas_height = field.get('canvas_height', 200)
        allow_image_upload = field.get('allow_image_upload', True)
        
        # Store canvas dimensions in state for use in other methods
        if 'canvas_dimensions' not in self.state:
            self.state['canvas_dimensions'] = {}
        self.state['canvas_dimensions'][field_key] = {
            'width': canvas_width,
            'height': canvas_height
        }
        
        # Create state for tracking drawing
        class DrawingState:
            x: float = 0
            y: float = 0
            drawing: bool = False
            
        drawing_state = DrawingState()
        
        # Define gesture handlers
        def pan_start(e: ft.DragStartEvent):
            # Constrain initial coordinates to canvas boundaries
            drawing_state.x = max(0, min(e.local_x, canvas_width))
            drawing_state.y = max(0, min(e.local_y, canvas_height))
            drawing_state.drawing = True
            
        def pan_update(e: ft.DragUpdateEvent):
            if drawing_state.drawing:
                # Constrain coordinates to canvas boundaries
                new_x = max(0, min(e.local_x, canvas_width))
                new_y = max(0, min(e.local_y, canvas_height))
                
                # Add a line from previous position to current position
                canvas.shapes.append(
                    cv.Line(
                        drawing_state.x, drawing_state.y, 
                        new_x, new_y, 
                        paint=ft.Paint(stroke_width=3, color="black")
                    )
                )
                # Update position
                drawing_state.x = new_x
                drawing_state.y = new_y
                # Mark as drawn
                self._handle_signature_change(field_key, canvas)
                # Request page update instead of direct canvas update
                self.page.update()
                
        def pan_end(e: ft.DragEndEvent):
            drawing_state.drawing = False
        
        # Create canvas for drawing with gesture detector
        canvas = cv.Canvas(
            width=canvas_width,
            height=canvas_height,
            shapes=[],
            content=ft.GestureDetector(
                on_pan_start=pan_start,
                on_pan_update=pan_update,
                on_pan_end=pan_end,
                drag_interval=10,
            )
        )
        
        # Create a container with border to constrain the signature area
        canvas_container = ft.Container(
            content=canvas,
            width=canvas_width,
            height=canvas_height,
            border=ft.border.all(1, "black"),
            border_radius=5,
            clip_behavior=ft.ClipBehavior.HARD_EDGE,
            visible=True  # Initially visible
        )
        
        # Create clear button
        clear_button = ft.ElevatedButton(
            "Clear",
            on_click=lambda e, key=field_key, c=canvas: self._clear_signature(key, c)
        )
        
        # Create container for signature controls
        signature_container = ft.Column([
            ft.Text(field.get('label', ''), weight=ft.FontWeight.BOLD),
        ])
        
        # Create file display container (initially hidden)
        file_display = ft.Column(visible=False)
        
        # Create file upload container (initially hidden)
        file_upload_container = ft.Container(
            width=canvas_width,
            height=canvas_height,
            border=ft.border.all(1, "black"),
            border_radius=5,
            clip_behavior=ft.ClipBehavior.HARD_EDGE,
            content=ft.Column([
                ft.Container(
                    content=ft.Icon(ft.Icons.UPLOAD_FILE, size=40, color="#AAAAAA"),
                    alignment=ft.alignment.center,
                    expand=True
                ),
                ft.Text("Drag and drop or click to upload", color="#AAAAAA", text_align=ft.TextAlign.CENTER),
            ], alignment=ft.MainAxisAlignment.CENTER),
            visible=False  # Initially hidden
        )
        
        # Create tabs for switching between draw and upload
        tabs = ft.Tabs(
            selected_index=0,
            on_change=lambda e, key=field_key, cc=canvas_container, fc=file_upload_container: 
                self._switch_signature_mode(key, e.control.selected_index, cc, fc),
            tabs=[
                ft.Tab(text="Draw", icon=ft.Icons.EDIT),
                ft.Tab(text="Upload", icon=ft.Icons.UPLOAD_FILE),
            ],
        )
        
        # Add tabs to signature container
        signature_container.controls.append(tabs)
        
        # Add content container that will hold both canvas and file upload
        content_container = ft.Container(
            content=ft.Stack([
                canvas_container,
                file_upload_container,
            ]),
            width=canvas_width,
            height=canvas_height,
        )
        signature_container.controls.append(content_container)
        
        # Add clear button for drawing mode
        draw_controls = ft.Row([clear_button], alignment=ft.MainAxisAlignment.END)
        signature_container.controls.append(draw_controls)
        
        # Add file upload if allowed
        if allow_image_upload:
            # Create file picker for signature image upload
            file_picker = ft.FilePicker()
            self.page.overlay.append(file_picker)
            self.page.update()
            
            # Store file picker in form state
            if 'file_pickers' not in self.state:
                self.state['file_pickers'] = {}
            self.state['file_pickers'][field_key] = file_picker
            
            # Store file display in form state
            if 'file_displays' not in self.state:
                self.state['file_displays'] = {}
            self.state['file_displays'][field_key] = file_display
            
            # Make file upload container clickable to open file picker
            file_upload_container.on_click = lambda e, fp=file_picker: fp.pick_files(
                allow_multiple=False,
                    allowed_extensions=field.get('allowed_extensions', ['jpg', 'jpeg', 'png'])
                )
            
            
            # Set up file picker on_result event
            file_picker.on_result = lambda e, key=field_key: self._update_signature_file_display(key, e)
            
            # Add file display to signature container
            signature_container.controls.append(file_display)
        
        # Add error text
        error_text = ft.Text(
            visible=False,
            color="red",
            size=12
        )
        
        # Store error text in form state
        if 'error_texts' not in self.state:
            self.state['error_texts'] = {}
        self.state['error_texts'][field_key] = error_text
        
        # Add error text to signature container
        signature_container.controls.append(error_text)
        
        return signature_container
    
    def _handle_signature_change(self, field_key: str, canvas: cv.Canvas):
        """Handle signature change from canvas drawing."""
        # Store the signature status in the form state
        self.state['values'][field_key] = "signature_drawn"
        
        # Clear error when user starts drawing
        if field_key in self.state['errors']:
            del self.state['errors'][field_key]
            self._update_field_error(field_key)
        
        self.page.update()
    
    def _clear_signature(self, field_key: str, canvas: cv.Canvas):
        """Clear the signature canvas."""
        # Clear the canvas by removing all shapes
        canvas.shapes.clear()
        self.state['values'][field_key] = ""
        self.page.update()
        
    def _switch_signature_mode(self, field_key: str, tab_index: int, canvas_container: ft.Container, file_upload_container: ft.Container):
        """Switch between drawing and file upload modes."""
        # Get file display container
        file_display = self.state['file_displays'].get(field_key) if 'file_displays' in self.state else None
        
        # Check if we have an uploaded file
        has_uploaded_file = file_display and file_display.visible and len(file_display.controls) > 0
        
        if tab_index == 0:  # Draw mode
            # Show canvas container
            canvas_container.visible = True
            # Hide file upload container
            file_upload_container.visible = False
            # Hide file display if any
            if file_display:
                file_display.visible = False
        else:  # Upload mode
            # Hide canvas container
            canvas_container.visible = False
            
            if has_uploaded_file:
                # If we have an uploaded file, show the file display
                file_display.visible = True
                # Hide file upload container
                file_upload_container.visible = False
            else:
                # If no uploaded file, show the file upload container
                file_upload_container.visible = True
                # Hide file display
                if file_display:
                    file_display.visible = False
        
        self.page.update()
    
    def _update_signature_file_display(self, field_key: str, e: ft.FilePickerResultEvent):
        """Update the signature file display when a file is selected."""
        # Get file display container
        file_display = self.state['file_displays'].get(field_key)
        if not file_display:
            return
            
        # Get canvas dimensions from state
        canvas_dimensions = self.state.get('canvas_dimensions', {}).get(field_key, {'width': 400, 'height': 200})
        canvas_width = canvas_dimensions['width']
        canvas_height = canvas_dimensions['height']
            
        # Clear previous file display
        file_display.controls.clear()
        
        if e.files and len(e.files) > 0:
            # Get selected file
            file_info = e.files[0]
            
            # Store file path in form state
            self.state['values'][field_key] = file_info.path
            
            # Find the file upload container to hide it and show the preview instead
            for field_container in self.controls:
                if isinstance(field_container, ft.Container) and field_container.content:
                    if hasattr(field_container.content, 'key') and field_container.content.key == field_key:
                        # This is our field container
                        for control in field_container.content.controls:
                            if isinstance(control, ft.Container) and hasattr(control, 'content') and isinstance(control.content, ft.Stack):
                                # This is our stack container with canvas and file upload
                                for stack_item in control.content.controls:
                                    if hasattr(stack_item, 'visible') and not isinstance(stack_item, cv.Canvas):
                                        # This is our file upload container, hide it
                                        stack_item.visible = False
            
            # Create file display with preview and delete button
            file_display.controls.append(
                ft.Column([
                    ft.Container(
                        content=ft.Image(
                            src=file_info.path,
                            width=canvas_width,
                            height=canvas_height,
                            fit=ft.ImageFit.CONTAIN,
                        ),
                        width=canvas_width,
                        height=canvas_height,
                        border=ft.border.all(1, "black"),
                        border_radius=5,
                        padding=10,
                        clip_behavior=ft.ClipBehavior.HARD_EDGE,
                    ),
                    ft.Row([
                        ft.Text(file_info.name, expand=True),
                        ft.IconButton(
                            icon=ft.Icons.DELETE,
                            on_click=lambda e, key=field_key: self._remove_signature_file(key)
                        )
                    ])
                ])
            )
            file_display.visible = True
            
            # Clear any errors
            if 'error_texts' in self.state and field_key in self.state['error_texts']:
                self.state['error_texts'][field_key].visible = False
        else:
            file_display.visible = False
            # Clear form state
            self.state['values'][field_key] = ""
            
            # Find the file upload container to show it again
            for field_container in self.controls:
                if isinstance(field_container, ft.Container) and field_container.content:
                    if hasattr(field_container.content, 'key') and field_container.content.key == field_key:
                        # This is our field container
                        for control in field_container.content.controls:
                            if isinstance(control, ft.Container) and hasattr(control, 'content') and isinstance(control.content, ft.Stack):
                                # This is our stack container with canvas and file upload
                                for stack_item in control.content.controls:
                                    if hasattr(stack_item, 'visible') and not isinstance(stack_item, cv.Canvas):
                                        # This is our file upload container, show it
                                        stack_item.visible = True
            
        self.page.update()
        
    def _remove_signature_file(self, field_key: str):
        """Remove the signature file."""
        # Get file display container
        file_display = self.state['file_displays'].get(field_key)
        if not file_display:
            return
            
        # Clear file display
        file_display.controls.clear()
        file_display.visible = False
        
        # Clear form state
        self.state['values'][field_key] = ""
        
        # Switch back to upload mode view (empty state)
        # Find the tabs in the parent container
        for field_container in self.controls:
            if isinstance(field_container, ft.Container) and field_container.content:
                if hasattr(field_container.content, 'key') and field_container.content.key == field_key:
                    # This is our field container
                    for control in field_container.content.controls:
                        if isinstance(control, ft.Tabs):
                            # Set to upload tab if we're already there
                            if control.selected_index == 1:
                                # Update the UI to show empty upload state
                                self.page.update()
        
        self.page.update()
    
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