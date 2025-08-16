import flet as ft
import time
from typing import Dict, List, Any, Optional, Callable, Union
from flet import Page
import re
from datetime import datetime

from models.forms import FormConfig, FormField

def validate_field(
    field: FormField, 
    value: Any, 
    files: Optional[Dict[str, List[Dict[str, Any]]]] = None
) -> Optional[str]:
    """
    Validate a single field with improved logic and clearer error messages.
    Returns error message if validation fails, None if valid.
    """
    validation = field.get('validation', {})
    field_type = field['field_type']
    is_required = field.get('required', False)
    label = field.get('label', field['key'])
    
    # Helper to check if value is empty
    def is_empty(val):
        return val is None or val == '' or (isinstance(val, str) and val.strip() == '')
    
    # Required field validation
    if is_required:
        if field_type == 'file':
            file_list = files.get(field['key'], []) if files else []
            if not file_list:
                return f"{label} is required"
                
        elif field_type == 'signature':
            has_drawn = value and str(value).strip() and value != ''
            has_file = files and field['key'] in files and files[field['key']]
            if not (has_drawn or has_file):
                return f"{label} is required"
                
        elif field_type == 'checkbox':
            if not value:  # checkbox value is boolean
                return f"{label} must be checked"
                
        else:  # text, email, number, etc.
            if is_empty(value):
                return f"{label} is required"
    
    # Skip further validation if empty and not required
    if field_type not in ['file', 'signature', 'checkbox'] and is_empty(value):
        return None
    
    # Type-specific validations
    if field_type == 'email' and not is_empty(value):
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_pattern, str(value).strip()):
            return f"Please enter a valid email address"
    
    elif field_type == 'number' and not is_empty(value):
        try:
            num = float(value)
            if 'min' in validation and num < validation['min']:
                return f"{label} must be at least {validation['min']}"
            if 'max' in validation and num > validation['max']:
                return f"{label} must be at most {validation['max']}"
        except (ValueError, TypeError):
            return f"Please enter a valid number"
    
    elif field_type == 'password' and not is_empty(value):
        pwd = str(value)
        if 'min_length' in validation and len(pwd) < validation['min_length']:
            return f"Password must be at least {validation['min_length']} characters"
        if validation.get('require_uppercase') and not re.search(r'[A-Z]', pwd):
            return "Password must contain at least one uppercase letter"
        if validation.get('require_lowercase') and not re.search(r'[a-z]', pwd):
            return "Password must contain at least one lowercase letter"
        if validation.get('require_digit') and not re.search(r'\d', pwd):
            return "Password must contain at least one number"
        if validation.get('require_special') and not re.search(r'[!@#$%^&*(),.?":{}|<>]', pwd):
            return "Password must contain at least one special character"
    
    # String length validations (for text fields)
    if isinstance(value, str) and not is_empty(value):
        if 'min_length' in validation and len(value.strip()) < validation['min_length']:
            return f"{label} must be at least {validation['min_length']} characters"
        if 'max_length' in validation and len(value.strip()) > validation['max_length']:
            return f"{label} must be at most {validation['max_length']} characters"
        if 'pattern' in validation and not re.match(validation['pattern'], value.strip()):
            return validation.get('message', f"Invalid {label.lower()} format")
    
    # File validations
    if field_type in ['file', 'signature'] and files and field['key'] in files:
        file_list = files[field['key']]
        allowed_extensions = field.get('allowed_extensions', field.get('file_extensions', []))
        
        if allowed_extensions and file_list:
            for file_info in file_list:
                if 'name' in file_info:
                    file_name = file_info['name'].lower()
                    if '.' in file_name:
                        ext = file_name.split('.')[-1]
                        if ext not in [e.lower() for e in allowed_extensions]:
                            return f"File type not allowed. Allowed: {', '.join(allowed_extensions).upper()}"
        
        # File size validation
        max_size = field.get('max_file_size')
        if max_size and file_list:
            for file_info in file_list:
                if file_info.get('size', 0) > max_size:
                    max_mb = max_size / (1024 * 1024)
                    return f"File size too large. Maximum: {max_mb:.1f}MB"
    
    # Custom validation
    custom_validator = validation.get('custom_validator')
    if custom_validator and callable(custom_validator):
        try:
            custom_error = custom_validator(value)
            if custom_error:
                return custom_error
        except Exception as e:
            return f"Validation error: {str(e)}"
    
    return None


def validate_form(
    fields: List[FormField], 
    values: Dict[str, Any], 
    files: Optional[Dict[str, List[Dict[str, Any]]]] = None
) -> Dict[str, str]:
    """
    Validate all form fields and return a dictionary of field_key -> error_message.
    Only returns fields that have validation errors.
    """
    errors = {}
    
    for field in fields:
        field_key = field['key']
        value = values.get(field_key, '')
        error = validate_field(field, value, files)
        
        if error:
            errors[field_key] = error
    
    return errors


def get_initial_form_state(config: FormConfig) -> Dict[str, Any]:
    """
    Initialize form state with default values from config.
    """
    initial_values = {}
    
    for section in config['sections']:
        for field in section['fields']:
            default_value = field.get('default_value')
            if default_value is not None:
                initial_values[field['key']] = default_value
            else:
                # Set appropriate default based on field type
                field_type = field['field_type']
                if field_type == 'checkbox':
                    initial_values[field['key']] = False
                elif field_type in ['number']:
                    initial_values[field['key']] = 0
                else:
                    initial_values[field['key']] = ''
    
    return {
        'current_step': 0,
        'values': initial_values,
        'errors': {},
        'touched': {},
        'is_submitting': False,
        'files': {}
    }