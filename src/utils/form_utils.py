from typing import Dict, Any, List, Optional, Callable
import re
from datetime import datetime

from models.forms import FormField, FormFieldValidation

def validate_field(
    field: FormField, 
    value: Any, 
    files: Optional[Dict[str, List[Dict[str, Any]]]] = None
) -> Optional[str]:
    """
    Validate a single form field based on its validation rules.
    Returns an error message if validation fails, None otherwise.
    """
    validation = field.get('validation', {})
    
    # Handle required field validation
    if field.get('required', False):
        if value is None or value == '':
            return f"{field['label']} is required"
    
    # Skip further validation if the field is empty and not required
    if value is None or value == '':
        return None
    
    # Type-specific validations
    if field['field_type'] == 'email':
        if not re.match(r'^[^@\s]+@[^@\s]+\.[^@\s]+$', str(value)):
            return "Please enter a valid email address"
    
    elif field['field_type'] == 'number':
        try:
            num = float(value)
            if 'min' in validation and num < validation['min']:
                return f"Value must be at least {validation['min']}"
            if 'max' in validation and num > validation['max']:
                return f"Value must be at most {validation['max']}"
        except (ValueError, TypeError):
            return "Please enter a valid number"
    
    # String length validations
    if isinstance(value, str):
        if 'min_length' in validation and len(value) < validation['min_length']:
            return f"Must be at least {validation['min_length']} characters"
        if 'max_length' in validation and len(value) > validation['max_length']:
            return f"Must be at most {validation['max_length']} characters"
        if 'pattern' in validation and not re.match(validation['pattern'], value):
            return validation.get('message', 'Invalid format')
    
    # File validations
    if field['field_type'] == 'file' and files and field['key'] in files:
        file_list = files[field['key']]
        if field.get('required') and not file_list:
            return f"{field['label']} is required"
        
        # Check file extensions
        if 'file_extensions' in field and file_list:
            for file_info in file_list:
                if 'name' in file_info:
                    ext = file_info['name'].split('.')[-1].lower()
                    if ext not in field['file_extensions']:
                        return f"File type not allowed. Allowed types: {', '.join(field['file_extensions'])}"
    
    # Signature validations
    if field['field_type'] == 'signature':
        # For signature fields, we check if there's a value (canvas data) or a file
        has_signature = bool(value) if isinstance(value, str) else False
        has_signature_file = False
        
        if files and field['key'] in files and files[field['key']]:
            has_signature_file = True
            
        if field.get('required') and not (has_signature or has_signature_file):
            return f"{field['label']} is required"
            
        # If there's a file, check extensions if specified
        if has_signature_file and 'file_extensions' in field:
            for file_info in files[field['key']]:
                if 'name' in file_info:
                    ext = file_info['name'].split('.')[-1].lower()
                    if ext not in field['file_extensions']:
                        return f"Image type not allowed. Allowed types: {', '.join(field['file_extensions'])}"
    
    # Custom validation function
    if 'custom_validator' in validation and callable(validation['custom_validator']):
        custom_error = validation['custom_validator'](value)
        if custom_error:
            return custom_error
    
    return None

def validate_form(
    fields: List[FormField], 
    values: Dict[str, Any], 
    files: Optional[Dict[str, List[Dict[str, Any]]]] = None
) -> Dict[str, str]:
    """
    Validate all form fields and return a dictionary of errors.
    """
    errors = {}
    for field in fields:
        field_key = field['key']
        value = values.get(field_key, '')
        error = validate_field(field, value, files)
        if error:
            errors[field_key] = error
    return errors

def get_initial_form_state(config: Dict[str, Any]) -> Dict[str, Any]:
    """
    Initialize the form state with default values.
    """
    initial_values = {}
    
    for section in config['sections']:
        for field in section['fields']:
            if 'default_value' in field:
                initial_values[field['key']] = field['default_value']
    
    return {
        'current_step': 0,
        'values': initial_values,
        'errors': {},
        'touched': {},
        'is_submitting': False,
        'files': {}
    }
