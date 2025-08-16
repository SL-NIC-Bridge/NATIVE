from typing import Dict, List, Any, Callable
from models.forms import FormConfig, FormSection, FormField, FormFieldValidation

# Application configuration
APP_TITLE: str = "SL NIC Bridge"

# Brand colors
BRIGHT_ORANGE: str = "#FF7A00"  # bright orange
BROWN: str = "#795548"           # material brown 500

# Color palettes
# Note: Prefer Flet's Theme & semantic colors over manual palettes.
# These palettes are retained for backward compatibility only.
LIGHT_PALETTE: Dict[str, str] = {
    "primary": BRIGHT_ORANGE,
    "secondary": BROWN,
    "background": "#FFFFFF",
    "surface": "#FAFAFA",
    "on_primary": "#FFFFFF",
    "on_background": "#000000",
}

DARK_PALETTE: Dict[str, str] = {
    "primary": BRIGHT_ORANGE,
    "secondary": BROWN,
    "background": "#121212",
    "surface": "#1E1E1E",
    "on_primary": "#000000",
    "on_background": "#FFFFFF",
}

# Route configurations
ROUTES = [
    {
        "path": "/home",
        "title": "Home",
        "icon": "home_outlined",
        "selected_icon": "home",
        "label": "Home",
        "index": 0
    },
    {
        "path": "/application",
        "title": "Application",
        "icon": "DESCRIPTION_OUTLINED",
        "selected_icon": "DESCRIPTION",
        "label": "Application",
        "index": 1
    },
    {
        "path": "/settings",
        "title": "Settings",
        "icon": "settings_outlined",
        "selected_icon": "settings",
        "label": "Settings",
        "index": 2
    }
]

# Example form configuration
EXAMPLE_FORM_CONFIG: FormConfig = {
    'id': 'example_form',
    'title': 'Example Multi-Step Form',
    'description': 'This is an example of a multi-step form with validation and file uploads',
    'sections': [
        {
            'key': 'personal_info',
            'title': 'Personal Information',
            'description': 'Please provide your personal details',
            'fields': [
                {
                    'key': 'full_name',
                    'label': 'Full Name',
                    'field_type': 'text',
                    'placeholder': 'John Doe',
                    'required': True,
                    'disabled': False,
                    'validation': {
                        'required': True,
                        'min_length': 3,
                        'max_length': 100
                    }
                },
                {
                    'key': 'email',
                    'label': 'Email Address',
                    'field_type': 'email',
                    'placeholder': 'john@example.com',
                    'required': True,
                    'validation': {
                        'required': True,
                        'pattern': r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        'message': 'Please enter a valid email address'
                    }
                },
                {
                    'key': 'phone',
                    'label': 'Phone Number',
                    'field_type': 'text',
                    'placeholder': '+1 (555) 123-4567',
                    'required': False,
                    'validation': {
                        'pattern': r'^\+?[\d\s-]+$',
                        'message': 'Please enter a valid phone number'
                    }
                }
            ]
        },
        {
            'key': 'documents',
            'title': 'Documents',
            'description': 'Upload the required documents',
            'fields': [
                {
                    'key': 'id_proof',
                    'label': 'ID Proof (PDF, JPG, PNG)',
                    'field_type': 'file',
                    'required': True,
                    'file_extensions': ['pdf', 'jpg', 'jpeg', 'png'],
                    'multiple_files': False,
                    'validation': {
                        'required': True
                    }
                },
                {
                    'key': 'additional_docs',
                    'label': 'Additional Documents (Optional)',
                    'field_type': 'file',
                    'required': False,
                    'file_extensions': ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
                    'multiple_files': True
                }
            ]
        },
        {
            'key': 'review',
            'title': 'Review and Submit',
            'description': 'Please review your information before submitting',
            'fields': [
                {
                    'key': 'terms_agreement',
                    'label': 'I agree to the terms and conditions',
                    'field_type': 'checkbox',
                    'required': True,
                    'validation': {
                        'required': True,
                        'message': 'You must agree to the terms and conditions'
                    }
                },
                {
                    'key': 'signature',
                    'label': 'Signature',
                    'field_type': 'signature',
                    'required': True,
                    'canvas_width': 400,
                    'canvas_height': 200,
                    'allow_image_upload': True,
                    'file_extensions': ['jpg', 'jpeg', 'png', 'gif'],
                    'validation': {
                        'required': True
                    }
                },
            ]
        }
    ],
    'submit_text': 'Submit Application',
    'cancel_text': 'Cancel',
}
