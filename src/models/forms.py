from typing import TypedDict, List, Literal, Optional, Callable, Dict, Any
from flet import Control

class FormFieldValidation(TypedDict):
    """Validation rules for a form field."""
    required: bool
    min_length: Optional[int]
    max_length: Optional[int]
    pattern: Optional[str]
    custom_validator: Optional[Callable[[str], Optional[str]]]

class FormField(TypedDict):
    """Definition of a single form field."""
    key: str
    label: str
    field_type: Literal["text", "email", "password", "number", "date", "file", "select", "multiselect", "checkbox"]
    placeholder: Optional[str]
    default_value: Any
    required: bool
    disabled: bool
    options: Optional[List[Dict[str, Any]]]  # For select/multiselect
    validation: Optional[FormFieldValidation]
    file_extensions: Optional[List[str]]  # For file uploads
    multiple_files: Optional[bool]  # For file uploads

class FormSection(TypedDict):
    """A section/step in the multi-step form."""
    key: str
    title: str
    description: Optional[str]
    fields: List[FormField]

class FormState(TypedDict):
    """State management for the form."""
    current_step: int
    values: Dict[str, Any]
    errors: Dict[str, str]
    touched: Dict[str, bool]
    is_submitting: bool
    files: Dict[str, List[Dict[str, Any]]]  # For file uploads

class FormConfig(TypedDict):
    """Complete form configuration."""
    id: str
    title: str
    description: Optional[str]
    sections: List[FormSection]
    submit_text: str
    cancel_text: str
    on_submit: Callable[[Dict[str, Any]], None]
    on_cancel: Optional[Callable[[], None]]
