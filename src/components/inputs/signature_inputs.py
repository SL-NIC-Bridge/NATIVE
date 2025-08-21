import flet as ft
import flet.canvas as cv
from typing import Dict, Any, Callable, Optional
import base64
import io
from PIL import Image
from utils.signature_utils import get_signature_image_bytes



def create_signature_field(
    field: Dict[str, Any],
    field_key: str,
    page: ft.Page,
    state: Dict[str, Any],
    handle_change_callback: Callable,
    blur_callback: Optional[Callable] = None,
    clear_signature_callback: Optional[Callable] = None,
    update_file_display_callback: Optional[Callable] = None,
) -> ft.Control:
    """Create a signature field with canvas drawing and optional image upload."""
    
    # Configuration with enhanced defaults
    canvas_width = field.get("canvas_width", 300)
    canvas_height = field.get("canvas_height", 120)
    allow_image_upload = field.get("allow_image_upload", True)
    allowed_extensions = field.get("allowed_extensions", ["jpg", "jpeg", "png", "gif", "bmp"])
    max_file_size = field.get("max_file_size", 5 * 1024 * 1024)  # 5MB default
    stroke_width = field.get("stroke_width", 2)
    stroke_color = field.get("stroke_color", ft.Colors.BLACK)
    background_color = field.get("background_color", ft.Colors.WHITE)
    required = field.get("required", False)
    
    # Store canvas dimensions and signature data in state
    if "canvas_dimensions" not in state:
        state["canvas_dimensions"] = {}
    state["canvas_dimensions"][field_key] = {"width": canvas_width, "height": canvas_height}
    
    # Initialize signature data storage
    if "signature_data" not in state:
        state["signature_data"] = {}
    state["signature_data"][field_key] = {
        "canvas": None,
        "image_bytes": None,
        "type": None
    }
    
    # Enhanced component state
    component_state = {
        "mode": "draw",  # "draw" or "upload"
        "has_signature": False,
        "is_drawing": False,
        "last_x": 0.0,
        "last_y": 0.0,
        "signature_data": None,  # Store signature data
        "file_data": None,  # Store uploaded file data
        "is_valid": not required,  # Track validation state
    }
    
    # Create canvas with enhanced styling
    canvas = cv.Canvas(
        width=canvas_width, 
        height=canvas_height, 
        shapes=[],
        # bgcolor=background_color
    )
    
    # Enhanced drawing event handlers
    def on_pan_start(e: ft.DragStartEvent):
        """Handle start of drawing gesture."""
        component_state["last_x"] = max(0, min(e.local_x, canvas_width))
        component_state["last_y"] = max(0, min(e.local_y, canvas_height))
        component_state["is_drawing"] = True
        
    def on_pan_update(e: ft.DragUpdateEvent):
        """Handle drawing movement."""
        if not component_state["is_drawing"]:
            return
            
        new_x = max(0, min(e.local_x, canvas_width))
        new_y = max(0, min(e.local_y, canvas_height))
        
        # Add line segment to canvas
        canvas.shapes.append(
            cv.Line(
                component_state["last_x"], component_state["last_y"], 
                new_x, new_y,
                paint=ft.Paint(
                    stroke_width=stroke_width, 
                    color=stroke_color,
                    stroke_cap=ft.StrokeCap.ROUND,
                    stroke_join=ft.StrokeJoin.ROUND
                ),
            )
        )
        
        component_state["last_x"] = new_x
        component_state["last_y"] = new_y
        
        # Mark as having signature on first stroke
        if not component_state["has_signature"]:
            component_state["has_signature"] = True
            component_state["is_valid"] = True
            component_state["signature_data"] = "hand_drawn"
            
            # Store signature type and canvas in state
            state["signature_data"][field_key]["type"] = "drawn"
            state["signature_data"][field_key]["canvas"] = canvas
            
            handle_change_callback(field_key, "signature_drawn")
            update_status_text("✓ Signature drawn", ft.Colors.GREEN)
            
        page.update()
        
    def on_pan_end(e: ft.DragEndEvent):
        """Handle end of drawing gesture."""
        component_state["is_drawing"] = False
        # Trigger blur callback if provided
        if blur_callback:
            blur_callback(field_key)
    
    # Enhanced UI components
    canvas_container = ft.Container(
        content=ft.GestureDetector(
            content=canvas,
            on_pan_start=on_pan_start,
            on_pan_update=on_pan_update,
            on_pan_end=on_pan_end,
            drag_interval=3,  # Smoother drawing
        ),
        width=canvas_width,
        height=canvas_height,
        border=ft.border.all(
            2 if component_state["is_valid"] else 1, 
            ft.Colors.GREEN_400 if component_state["has_signature"] and component_state["is_valid"] 
            else ft.Colors.RED_400 if not component_state["is_valid"] and required
            else ft.Colors.GREY_400
        ),
        border_radius=8,
        bgcolor=background_color,
        clip_behavior=ft.ClipBehavior.HARD_EDGE,
    )
    
    # Enhanced upload area
    upload_area = ft.Container(
        content=ft.Column(
            [
                ft.Icon(ft.Icons.CLOUD_UPLOAD, size=48, color=ft.Colors.BLUE_400),
                ft.Text("Click to upload signature image", 
                       weight=ft.FontWeight.BOLD,
                       color=ft.Colors.BLUE_600, 
                       text_align=ft.TextAlign.CENTER),
                ft.Text("or drag and drop here",
                       size=12,
                       color=ft.Colors.GREY_600,
                       text_align=ft.TextAlign.CENTER),
                ft.Text(f"Supported: {', '.join(allowed_extensions).upper()}",
                       size=10, 
                       color=ft.Colors.GREY_500,
                       text_align=ft.TextAlign.CENTER),
                ft.Text(f"Max size: {max_file_size // (1024*1024)}MB",
                       size=10,
                       color=ft.Colors.GREY_500,
                       text_align=ft.TextAlign.CENTER),
            ],
            alignment=ft.MainAxisAlignment.CENTER,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            spacing=8,
        ),
        width=canvas_width,
        height=canvas_height,
        border=ft.border.all(2, ft.Colors.BLUE_300),
        border_radius=8,
        bgcolor=ft.Colors.BLUE_50,
        ink=True,
        visible=False,
        animate=ft.Animation(300, ft.AnimationCurve.EASE_IN_OUT),
    )
    
    # Enhanced preview container
    preview_container = ft.Container(
        width=canvas_width,
        height=canvas_height,
        border=ft.border.all(2, ft.Colors.GREEN_400),
        border_radius=8,
        bgcolor=ft.Colors.WHITE,
        visible=False,
        clip_behavior=ft.ClipBehavior.HARD_EDGE,
    )
    
    # Enhanced status text
    status_text = ft.Text(
        "", 
        size=12, 
        color=ft.Colors.GREY_600,
        weight=ft.FontWeight.BOLD
    )
    
    def update_status_text(message: str, color: str = ft.Colors.GREY_600):
        """Update status text with message and color."""
        status_text.value = message
        status_text.color = color
        page.update()
    
    def update_border_state():
        """Update border color based on validation state."""
        if component_state["has_signature"] and component_state["is_valid"]:
            border_color = ft.Colors.GREEN_400
            border_width = 2
        elif not component_state["is_valid"] and required:
            border_color = ft.Colors.RED_400
            border_width = 2
        else:
            border_color = ft.Colors.GREY_400
            border_width = 1
            
        canvas_container.border = ft.border.all(border_width, border_color)
        if preview_container.visible:
            preview_container.border = ft.border.all(border_width, border_color)
    
    def update_visibility():
        """Update component visibility based on current mode and state."""
        if component_state["mode"] == "draw":
            canvas_container.visible = True
            upload_area.visible = False
            preview_container.visible = False
        else:  # upload mode
            canvas_container.visible = False
            if component_state["has_signature"] and preview_container.content:
                upload_area.visible = False
                preview_container.visible = True
            else:
                upload_area.visible = True
                preview_container.visible = False
        
        update_border_state()
    
    def validate_signature():
        """Validate the signature field."""
        is_valid = not required or component_state["has_signature"]
        component_state["is_valid"] = is_valid
        
        if not is_valid:
            update_status_text("⚠ Signature is required", ft.Colors.RED_600)
        elif component_state["has_signature"]:
            if component_state["mode"] == "draw":
                update_status_text("✓ Signature drawn", ft.Colors.GREEN_600)
            else:
                update_status_text("✓ Signature uploaded", ft.Colors.GREEN_600)
        else:
            update_status_text("", ft.Colors.GREY_600)
        
        update_border_state()
        return is_valid
    
    def clear_signature(e=None):
        """Clear the current signature with enhanced cleanup."""
        # Clear canvas
        canvas.shapes.clear()
        
        # Clear preview
        preview_container.content = None
        
        # Reset component state
        component_state["has_signature"] = False
        component_state["signature_data"] = None
        component_state["file_data"] = None
        component_state["is_valid"] = not required
        
        # Clear signature data from state
        state["signature_data"][field_key] = {
            "canvas": canvas,  # Keep canvas reference but clear shapes
            "image_bytes": None,
            "type": None
        }
        
        # External callbacks
        if clear_signature_callback:
            try:
                clear_signature_callback(field_key, canvas)
            except Exception as ex:
                print(f"Clear signature callback error: {ex}")
                
        if update_file_display_callback:
            try:
                class EmptyResult:
                    files = []
                update_file_display_callback(field_key, EmptyResult())
            except Exception as ex:
                print(f"Update file display callback error: {ex}")
        
        # Update form state
        handle_change_callback(field_key, "")
        
        # Update UI
        update_status_text("Signature cleared", ft.Colors.ORANGE_600)
        update_visibility()
        page.update()
        
        # Clear status after delay
        def clear_status():
            update_status_text("", ft.Colors.GREY_600)
            page.update()
    
    def validate_file_size(file_size: int) -> bool:
        """Validate uploaded file size."""
        if file_size > max_file_size:
            size_mb = file_size / (1024 * 1024)
            max_mb = max_file_size / (1024 * 1024)
            update_status_text(
                f"❌ File too large: {size_mb:.1f}MB (max: {max_mb:.1f}MB)", 
                ft.Colors.RED_600
            )
            return False
        return True
    
    def validate_file_extension(filename: str) -> bool:
        """Validate uploaded file extension."""
        if not filename:
            return False
            
        ext = filename.lower().split('.')[-1] if '.' in filename else ""
        if ext not in [e.lower() for e in allowed_extensions]:
            update_status_text(
                f"❌ Invalid file type. Allowed: {', '.join(allowed_extensions)}", 
                ft.Colors.RED_600
            )
            return False
        return True
    
    def process_uploaded_file(file):
        """Process and display uploaded file with enhanced validation."""
        try:
            # Get file properties
            file_name = getattr(file, "name", "Unknown file")
            file_size = getattr(file, "size", 0)
            
            # Validate file
            if not validate_file_extension(file_name):
                return
                
            if not validate_file_size(file_size):
                return
            
            # Update file display callback
            if update_file_display_callback:
                class FileResult:
                    def __init__(self, files):
                        self.files = files
                update_file_display_callback(field_key, FileResult([file]))
            
            # Create preview with better error handling
            file_path = getattr(file, "path", None)
            file_bytes = getattr(file, "bytes", None)
            
            if file_path:
                preview_container.content = ft.Image(
                    src=file_path,
                    width=canvas_width,
                    height=canvas_height,
                    fit=ft.ImageFit.CONTAIN,
                    border_radius=ft.border_radius.all(6),
                )
            elif file_bytes:
                try:
                    # Validate image data
                    img = Image.open(io.BytesIO(file_bytes))
                    img.verify()  # Verify it's a valid image
                    
                    b64_data = base64.b64encode(file_bytes).decode()
                    preview_container.content = ft.Image(
                        src_base64=b64_data,
                        width=canvas_width,
                        height=canvas_height,
                        fit=ft.ImageFit.CONTAIN,
                        border_radius=ft.border_radius.all(6),
                    )
                except Exception as img_ex:
                    update_status_text(f"❌ Invalid image file: {str(img_ex)}", ft.Colors.RED_600)
                    return
            else:
                update_status_text("❌ Could not read file data", ft.Colors.RED_600)
                return
            
            # Update component state
            component_state["has_signature"] = True
            component_state["is_valid"] = True
            component_state["file_data"] = file
            
            # Store image data in state
            # If we have a file path but no in-memory bytes, try reading from disk
            if not file_bytes and file_path:
                try:
                    path_to_read = file_path
                    if isinstance(path_to_read, str) and path_to_read.startswith("file://"):
                        path_to_read = path_to_read[7:]
                    with open(path_to_read, "rb") as f:
                        file_bytes = f.read()
                except Exception as ex:
                    # Don't fail hard here; keep file_bytes as None but warn
                    print(f"Warning: unable to read file bytes from path {file_path}: {ex}")

            state["signature_data"][field_key] = {
                "canvas": None,
                "image_bytes": file_bytes,
                "type": "uploaded",
                "filename": file_name,
                "size": file_size
            }
            
            # Update status
            size_text = f" ({file_size // 1024}KB)" if file_size else ""
            update_status_text(f"✓ {file_name}{size_text} uploaded", ft.Colors.GREEN_600)
            
            # Update form
            handle_change_callback(field_key, f"file_uploaded:{file_name}")
            update_visibility()
            
        except Exception as ex:
            update_status_text(f"❌ Error uploading file: {str(ex)}", ft.Colors.RED_600)
            
        page.update()
    
    def on_file_selected(e):
        """Handle file selection from picker."""
        if e.files and len(e.files) > 0:
            process_uploaded_file(e.files[0])
    
    # Enhanced file picker setup
    file_picker = ft.FilePicker(on_result=on_file_selected)
    page.overlay.append(file_picker)
    
    def open_file_picker(e):
        """Open file picker with validation."""
        file_picker.pick_files(
            allow_multiple=False,
            allowed_extensions=allowed_extensions,
            file_type=ft.FilePickerFileType.IMAGE
        )
        
    
    upload_area.on_click = open_file_picker
    
    def on_tab_change(e):
        """Handle tab change between draw and upload modes."""
        new_mode = "draw" if e.control.selected_index == 0 else "upload"
        component_state["mode"] = new_mode
        update_visibility()
        page.update()
    
    def undo_last_stroke(e=None):
        """Undo the last drawn stroke."""
        if canvas.shapes and component_state["mode"] == "draw":
            canvas.shapes.pop()
            
            # If no shapes left, mark as no signature
            if not canvas.shapes:
                component_state["has_signature"] = False
                component_state["signature_data"] = None
                component_state["is_valid"] = not required
                
                # Update state
                state["signature_data"][field_key] = {
                    "canvas": canvas,
                    "image_bytes": None,
                    "type": None
                }
                
                handle_change_callback(field_key, "")
                update_status_text("Last stroke undone", ft.Colors.ORANGE_600)
            else:
                update_status_text("Last stroke undone", ft.Colors.ORANGE_600)
            
            update_border_state()
            page.update()
    
    # Build enhanced component layout
    content_stack = ft.Stack([
        canvas_container,
        upload_area,
        preview_container,
    ])
    
    # Enhanced control buttons
    undo_button = ft.IconButton(
        icon=ft.Icons.UNDO,
        tooltip="Undo last stroke",
        on_click=undo_last_stroke,
        icon_color=ft.Colors.ORANGE_600,
    )
    
    clear_button = ft.IconButton(
        icon=ft.Icons.CLEAR,
        tooltip="Clear signature",
        on_click=clear_signature,
        icon_color=ft.Colors.RED_600,
    )
    
    controls_row = ft.Row(
        [
            status_text,
            ft.Container(expand=True),  # Spacer
            undo_button,
            clear_button,
        ],
        alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
        vertical_alignment=ft.CrossAxisAlignment.CENTER,
    )
    
    # Build component structure
    components = []
    
    # Label with required indicator
    label_text = field.get("label", "Signature")
    if required:
        label_text += " *"
    
    label = ft.Text(
        label_text, 
        weight=ft.FontWeight.BOLD,
        size=14,
        color=ft.Colors.RED_600 if required and not component_state["is_valid"] else ft.Colors.BLACK
    )
    components.append(label)
    
    # Description if provided
    description = field.get("description")
    if description:
        components.append(
            ft.Text(
                description,
                size=12,
                color=ft.Colors.GREY_600,
                italic=True
            )
        )
    
    # Mode tabs if upload is allowed
    if allow_image_upload:
        tabs = ft.Tabs(
            selected_index=0,
            on_change=on_tab_change,
            tabs=[
                ft.Tab(
                    text="Draw", 
                    icon=ft.Icons.EDIT
                ),
                ft.Tab(
                    text="Upload", 
                    icon=ft.Icons.UPLOAD_FILE
                ),
            ],
        )
        components.append(tabs)
    
    components.extend([content_stack, controls_row])
    
    # Set initial state
    update_visibility()
    validate_signature()
    
    # Create main container
    main_container = ft.Column(
        controls=components, 
        spacing=12, 
        tight=True
    )
    
    # Add validation method to the returned control
    def validate():
        return validate_signature()
    
    main_container.validate = validate
    
    return main_container