import flet as ft
import flet.canvas as cv
import io
from typing import Optional, Dict, Any
from PIL import Image, ImageDraw


def export_signature_as_image(canvas: cv.Canvas, width: int, height: int, 
                            background_color: str = "white", 
                            format: str = "PNG") -> Optional[bytes]:
    """
    Export canvas signature as image bytes using Pillow.
    """
    try:
        # Create a new image with white background
        img = Image.new('RGB', (width, height), background_color)
        draw = ImageDraw.Draw(img)
        
        # Process each shape in the canvas
        for shape in canvas.shapes:
            if isinstance(shape, cv.Line):
                # Extract line properties
                x1, y1 = shape.x1, shape.y1
                x2, y2 = shape.x2, shape.y2
                
                # Get paint properties
                paint = shape.paint
                color = "black"  # Default color
                width_stroke = 2  # Default width
                
                if paint:
                    # Convert Flet color to PIL color
                    if hasattr(paint, 'color') and paint.color:
                        color = _convert_flet_color_to_pil(paint.color)
                    
                    # Get stroke width
                    if hasattr(paint, 'stroke_width') and paint.stroke_width:
                        width_stroke = int(paint.stroke_width)
                
                # Draw the line
                draw.line([(x1, y1), (x2, y2)], fill=color, width=width_stroke)
            
            elif isinstance(shape, cv.Circle):
                # Handle circle shapes if present
                center_x, center_y = shape.x, shape.y
                radius = shape.radius
                
                paint = shape.paint
                color = "black"
                width_stroke = 2
                
                if paint:
                    if hasattr(paint, 'color') and paint.color:
                        color = _convert_flet_color_to_pil(paint.color)
                    if hasattr(paint, 'stroke_width') and paint.stroke_width:
                        width_stroke = int(paint.stroke_width)
                
                # Draw circle outline
                bbox = [
                    center_x - radius, center_y - radius,
                    center_x + radius, center_y + radius
                ]
                draw.ellipse(bbox, outline=color, width=width_stroke)
            
            elif isinstance(shape, cv.Rect):
                # Handle rectangle shapes if present
                x, y = shape.x, shape.y
                rect_width, rect_height = shape.width, shape.height
                
                paint = shape.paint
                color = "black"
                width_stroke = 2
                
                if paint:
                    if hasattr(paint, 'color') and paint.color:
                        color = _convert_flet_color_to_pil(paint.color)
                    if hasattr(paint, 'stroke_width') and paint.stroke_width:
                        width_stroke = int(paint.stroke_width)
                
                # Draw rectangle outline
                bbox = [x, y, x + rect_width, y + rect_height]
                draw.rectangle(bbox, outline=color, width=width_stroke)
            
            elif isinstance(shape, cv.Path):
                # Handle path shapes - more complex
                _draw_path_shape(draw, shape)
        
        # Convert image to bytes
        img_bytes = io.BytesIO()
        img.save(img_bytes, format=format, quality=95 if format.upper() == 'JPEG' else None)
        img_bytes.seek(0)
        
        return img_bytes.getvalue()
        
    except Exception as ex:
        print(f"Canvas export error: {ex}")
        return None


def _convert_flet_color_to_pil(flet_color) -> str:
    """
    Convert Flet color to PIL-compatible color.
    """
    try:
        # If it's already a string, return it
        if isinstance(flet_color, str):
            return flet_color
        
        # Handle Flet Colors constants
        color_mappings = {
            ft.Colors.BLACK: "black",
            ft.Colors.WHITE: "white",
            ft.Colors.RED: "red",
            ft.Colors.GREEN: "green",
            ft.Colors.BLUE: "blue",
            ft.Colors.YELLOW: "yellow",
            ft.Colors.ORANGE: "orange",
            ft.Colors.PURPLE: "purple",
            ft.Colors.PINK: "pink",
            ft.Colors.CYAN: "cyan",
            ft.Colors.GREY: "grey",
            ft.Colors.BROWN: "brown",
        }
        
        if flet_color in color_mappings:
            return color_mappings[flet_color]
        
        # Handle hex colors
        if hasattr(flet_color, 'value'):
            hex_value = flet_color.value
            if isinstance(hex_value, str) and hex_value.startswith('#'):
                return hex_value
            elif isinstance(hex_value, int):
                # Convert int to hex color
                return f"#{hex_value:06x}"
        
        # Default to black if conversion fails
        return "black"
        
    except Exception:
        return "black"


def _draw_path_shape(draw, path_shape: cv.Path):
    """
    Draw a path shape on PIL ImageDraw.
    """
    try:
        paint = path_shape.paint
        color = "black"
        width_stroke = 2
        
        if paint:
            if hasattr(paint, 'color') and paint.color:
                color = _convert_flet_color_to_pil(paint.color)
            if hasattr(paint, 'stroke_width') and paint.stroke_width:
                width_stroke = int(paint.stroke_width)
        
        if hasattr(path_shape, 'elements') and path_shape.elements:
            points = []
            for element in path_shape.elements:
                if hasattr(element, 'x') and hasattr(element, 'y'):
                    points.append((element.x, element.y))
            
            if len(points) > 1:
                for i in range(len(points) - 1):
                    draw.line([points[i], points[i + 1]], fill=color, width=width_stroke)
                    
    except Exception as ex:
        print(f"Path drawing error: {ex}")


def get_signature_image_bytes(field_key: str, state: Dict[str, Any]) -> Optional[bytes]:
    """
    Helper function to get signature image bytes from form state.
    Works for both drawn and uploaded signatures.
    """
    try:
        signature_data = state.get("signature_data", {}).get(field_key, {})
        signature_type = signature_data.get("type")
        
        if signature_type == "drawn":
            # Export drawn signature from canvas
            canvas = signature_data.get("canvas")
            if canvas and canvas.shapes:
                dimensions = state.get("canvas_dimensions", {}).get(field_key, {})
                width = dimensions.get("width", 300)
                height = dimensions.get("height", 120)
                return export_signature_as_image(canvas, width, height)
        
        elif signature_type == "uploaded":
            # Return stored image bytes
            return signature_data.get("image_bytes")
        
        return None
        
    except Exception as ex:
        print(f"Error getting signature image for {field_key}: {ex}")
        return None