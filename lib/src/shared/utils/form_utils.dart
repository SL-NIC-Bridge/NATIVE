import 'package:flutter/material.dart' hide FormField;
import 'package:flutter/services.dart';
import '../../core/config/form_config_model.dart';

class FormUtils {
  /// Validates a single field value against its validation rules
  static String? validateField(String? value, FormField field) {
    // Check required fields first
    if (field.required && (value == null || value.trim().isEmpty)) {
      return '${field.label} is required';
    }
    
    // Skip validation for empty non-required fields
    if (value == null || value.trim().isEmpty) return null;

    final trimmedValue = value.trim();

    // Apply validation rules
    for (final rule in field.validationRules) {
      final error = _validateRule(trimmedValue, rule, field);
      if (error != null) {
        return error;
      }
    }

    return null;
  }

  /// Validates a specific rule against a value
  static String? _validateRule(String value, ValidationRule rule, FormField field) {
    switch (rule.type) {
      case 'minLength':
        if (value.length < (rule.value as num).toInt()) {
          return rule.message;
        }
        break;
      case 'maxLength':
        if (value.length > (rule.value as num).toInt()) {
          return rule.message;
        }
        break;
      case 'pattern':
        if (!RegExp(rule.value.toString()).hasMatch(value)) {
          return rule.message;
        }
        break;
      case 'email':
        if (!_isValidEmail(value)) {
          return rule.message;
        }
        break;
      case 'min':
        if (field.type == 'number') {
          final numValue = double.tryParse(value);
          if (numValue == null || numValue < (rule.value as num)) {
            return rule.message;
          }
        }
        break;
      case 'max':
        if (field.type == 'number') {
          final numValue = double.tryParse(value);
          if (numValue == null || numValue > (rule.value as num)) {
            return rule.message;
          }
        }
        break;
    }
    return null;
  }

  /// Validates an email format
  static bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  /// Validates a Sri Lankan phone number
  static bool isValidSriLankanPhone(String phone) {
    return RegExp(r'^(\+94|0)[0-9]{9}$').hasMatch(phone);
  }

  /// Validates a Sri Lankan NIC number (old and new format)
  static bool isValidNIC(String nic) {
    return RegExp(r'^([0-9]{9}[vVxX]|[0-9]{12})$').hasMatch(nic);
  }

  /// Formats phone number for display
  static String formatPhoneNumber(String phone) {
    if (phone.startsWith('+94')) {
      return phone;
    } else if (phone.startsWith('0')) {
      return '+94${phone.substring(1)}';
    }
    return phone;
  }

  /// Gets form configuration by form type ID
  static Map<String, dynamic>? getFormConfig(FormConfig formConfig, String formTypeId) {
    return formConfig.formConfigs[formTypeId] as Map<String, dynamic>?;
  }

  /// Gets all available form types
  static List<FormType> getAvailableFormTypes(FormConfig formConfig) {
    return formConfig.formTypes;
  }

  /// Parses steps from form configuration
  static List<FormStep> parseFormSteps(Map<String, dynamic>? formConfigData) {
    if (formConfigData == null || !formConfigData.containsKey('steps')) {
      return [];
    }
    
    final stepsData = formConfigData['steps'] as List?;
    if (stepsData == null) return [];
    
    return stepsData.map((stepData) => FormStep.fromJson(stepData)).toList();
  }

  /// Validates an entire form step
  static Map<String, String> validateFormStep(
    FormStep step, 
    Map<String, dynamic> formData
  ) {
    final errors = <String, String>{};
    for (final field in step.fields) {
      final value = formData[field.fieldId]?.toString();
      final error = validateField(value, field);
      if (error != null) {
        errors[field.fieldId] = error;
      }
    }
    return errors;
  }

  /// Validates an entire form configuration
  static Map<String, String> validateCompleteForm(
    FormConfig formConfig, 
    FormType formType,
    Map<String, dynamic> formData
  ) {
    final errors = <String, String>{};
    final formConfigData = getFormConfig(formConfig, formType.id);
    final steps = parseFormSteps(formConfigData);
    
    for (final step in steps) {
      final stepErrors = validateFormStep(step, formData);
      errors.addAll(stepErrors);
    }
    return errors;
  }

  /// Cleans and prepares form data for submission
  static Map<String, dynamic> prepareFormDataForSubmission(
    FormConfig formConfig,
    String formTypeId,
    Map<String, dynamic> rawFormData
  ) {
    final cleanedData = <String, dynamic>{};
    final formConfigData = getFormConfig(formConfig, formTypeId);
    final steps = parseFormSteps(formConfigData);
    
    for (final step in steps) {
      for (final field in step.fields) {
        final value = rawFormData[field.fieldId];
        if (value != null) {
          switch (field.type) {
            case 'text':
            case 'textarea':
            case 'email':
              cleanedData[field.fieldId] = value.toString().trim();
              break;
            case 'phone':
              cleanedData[field.fieldId] = formatPhoneNumber(value.toString().trim());
              break;
            case 'number':
              cleanedData[field.fieldId] = double.tryParse(value.toString()) ?? 0;
              break;
            case 'checkbox':
              cleanedData[field.fieldId] = value == true;
              break;
            case 'date':
              if (value is DateTime) {
                cleanedData[field.fieldId] = value.toIso8601String();
              } else {
                cleanedData[field.fieldId] = value;
              }
              break;
            default:
              cleanedData[field.fieldId] = value;
          }
        }
      }
    }
    return cleanedData;
  }

  /// Gets field options for select/radio fields
  static List<Map<String, String>> getFieldOptions(FormField field) {
    if (field.type == 'select' || field.type == 'radio') {
      final options = field.properties['options'];
      if (options is List) {
        return options.cast<Map<String, dynamic>>()
            .map((option) => {
                  'value': option['value'].toString(),
                  'label': option['label'].toString(),
                })
            .toList();
      }
    }
    return [];
  }

  /// Shows date picker and returns formatted date
  static Future<String?> showFormDatePicker(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365 * 100)),
    );

    if (date != null) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    return null;
  }

  /// Creates a text input formatter based on field type
  static List<TextInputFormatter> getInputFormatters(FormField field) {
    final formatters = <TextInputFormatter>[];
    
    switch (field.type) {
      case 'phone':
        // Allow only digits, +, and spaces
        formatters.add(FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')));
        break;
      case 'number':
        // Allow only digits and decimal point
        formatters.add(FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')));
        break;
      case 'text':
        // Check if there's a maxLength validation rule
        final maxLengthRule = field.validationRules
            .where((rule) => rule.type == 'maxLength')
            .firstOrNull;
        if (maxLengthRule != null) {
          formatters.add(LengthLimitingTextInputFormatter(
            (maxLengthRule.value as num).toInt()
          ));
        }
        break;
      default:
        break;
    }

    return formatters;
  }

  /// Gets keyboard type based on field type
  static TextInputType getKeyboardType(FormField field) {
    switch (field.type) {
      case 'email':
        return TextInputType.emailAddress;
      case 'phone':
        return TextInputType.phone;
      case 'number':
        return TextInputType.number;
      case 'textarea':
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  /// Merges common fields with form-specific field overrides
  static FormField mergeCommonField(
    Map<String, dynamic> commonFieldData,
    Map<String, dynamic>? fieldVariationData
  ) {
    final mergedData = Map<String, dynamic>.from(commonFieldData);
    
    if (fieldVariationData != null) {
      // Merge field variation data, overriding common field properties
      mergedData.addAll(fieldVariationData);
    }
    
    return FormField.fromJson(mergedData);
  }

  /// Gets a processed FormField with common fields and variations applied
  static FormField? getProcessedField(
    FormConfig formConfig,
    String fieldId
  ) {
    // Check if it's in common fields
    final commonFieldData = formConfig.commonFields[fieldId] as Map<String, dynamic>?;
    
    if (commonFieldData != null) {
      // Check for field variations
      final fieldVariationData = formConfig.fieldVariations[fieldId] as Map<String, dynamic>?;
      return mergeCommonField(commonFieldData, fieldVariationData);
    }
    
    return null;
  }

  /// Creates a form step with processed fields (merging common fields and variations)
  static FormStep createProcessedFormStep(
    FormConfig formConfig,
    Map<String, dynamic> stepData
  ) {
    final fieldsData = stepData['fields'] as List? ?? [];
    final processedFields = <FormField>[];
    
    for (final fieldData in fieldsData) {
      if (fieldData is String) {
        // Field reference - get from common fields
        final processedField = getProcessedField(formConfig, fieldData);
        if (processedField != null) {
          processedFields.add(processedField);
        }
      } else if (fieldData is Map<String, dynamic>) {
        // Inline field definition
        processedFields.add(FormField.fromJson(fieldData));
      }
    }
    
    return FormStep(
      id: stepData['id'] as String,
      title: stepData['title'] as String,
      description: stepData['description'] as String,
      fields: processedFields,
    );
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}