import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sl_nic_bridge/src/core/config/field_type.dart';
import 'package:sl_nic_bridge/src/core/config/form_config_model.dart' as form_config;
import 'package:sl_nic_bridge/src/core/config/field_dependency.dart';
import 'package:sl_nic_bridge/src/core/providers/field_data_provider.dart';
import '../custom_text_field.dart';
import '../signature_pad.dart';
import '../file_upload_field.dart';

class DynamicFormField extends ConsumerStatefulWidget {
  final form_config.FormField config;
  final dynamic value;
  final Function(dynamic value) onChanged;
  final String? errorText;
  final Map<String, dynamic> formData;

  const DynamicFormField({
    super.key,
    required this.config,
    this.value,
    required this.onChanged,
    this.errorText,
    required this.formData,
  });

  @override
  ConsumerState<DynamicFormField> createState() => _DynamicFormFieldState();
}

class _DynamicFormFieldState extends ConsumerState<DynamicFormField> {
  late TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value?.toString() ?? '',
    );
    
    if (widget.config.dataSource != null) {
      final endpoint = widget.config.dataSource!['endpoint'] as String;
      final params = widget.config.dataSource!['params'] as Map<String, dynamic>?;
      
      // Start loading the data
      Future.microtask(() {
        ref.read(fieldDataProvider(widget.config.fieldId).notifier)
           .loadData(endpoint, params: params);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DynamicFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.text = widget.value?.toString() ?? '';
    }

    // If this field has dynamic data source and depends on other fields,
    // reload when dependent field values change
    if (widget.config.dataSource != null && 
        widget.config.dataSource!['params'] != null) {
      final params = Map<String, dynamic>.from(widget.config.dataSource!['params']);
      bool shouldReload = false;

      // Check if any param references another field and that field's value has changed
      for (final entry in params.entries) {
        if (entry.value is String && entry.value.toString().startsWith('\$')) {
          final fieldId = entry.value.toString().substring(1); // Remove the $ prefix
          if (widget.formData[fieldId] != oldWidget.formData[fieldId]) {
            shouldReload = true;
            break;
          }
        }
      }

      if (shouldReload) {
        final endpoint = widget.config.dataSource!['endpoint'] as String;
        final resolvedParams = params.map((key, value) {
          if (value is String && value.startsWith('\$')) {
            final fieldId = value.substring(1);
            return MapEntry(key, widget.formData[fieldId]);
          }
          return MapEntry(key, value);
        });

        ref.read(fieldDataProvider(widget.config.fieldId).notifier)
           .loadData(endpoint, params: resolvedParams);
      }
    }
  }

  (bool visible, bool enabled) _evaluateDependencies() {
    if (widget.config.dependencies == null || widget.config.dependencies!.isEmpty) {
      return (true, true);
    }

    bool shouldBeVisible = true;
    bool shouldBeEnabled = true;

    for (final dependency in widget.config.dependencies!) {
      final fieldValue = widget.formData[dependency.field];
      final conditionMet = dependency.evaluate(fieldValue);

      if (!conditionMet) {
        switch (dependency.behavior) {
          case DependencyBehavior.hide:
            shouldBeVisible = false;
            break;
          case DependencyBehavior.disable:
            shouldBeEnabled = false;
            break;
        }
      }

      if (!shouldBeVisible) break; // No need to check further if we're hiding the field
    }

    return (shouldBeVisible, shouldBeEnabled);
  }

  Widget _wrapWithDisabled(Widget child, bool enabled) {
    if (enabled) return child;
    
    return IgnorePointer(
      ignoring: true,
      child: Opacity(
        opacity: 0.5,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (isVisible, isEnabled) = _evaluateDependencies();
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    Widget field;
    switch (widget.config.type) {
      case FieldType.text:
      case FieldType.email:
      case FieldType.phone:
        field = _buildTextField();
        break;
      case FieldType.number:
        field = _buildNumberField();
        break;
      case FieldType.textarea:
        field = _buildTextAreaField();
        break;
      case FieldType.date:
        field = _buildDateField();
        break;
      case FieldType.select:
        field = _buildSelectField();
        break;
      case FieldType.radio:
        field = _buildRadioField();
        break;
      case FieldType.checkbox:
        field = _buildCheckboxField();
        break;
      case FieldType.file:
        field = _buildFileField();
        break;
      case FieldType.signature:
        field = _buildSignatureField();
        break;
    }
    
    return _wrapWithDisabled(field, isEnabled);
  }

  Widget _buildTextField() {
    return CustomTextField(
      controller: _controller,
      label: widget.config.label,
      hintText: widget.config.placeholder,
      keyboardType: _getKeyboardType(),
      validator: _getValidator(),
      readOnly: false, // We handle disabling through the wrapper
      onTap: widget.config.type == FieldType.phone ? null : () {
        // Handle any special tap behavior
      },
      onChanged: (value) {
        widget.onChanged(value);
      },
    );
  }

  Widget _buildNumberField() {
    return CustomTextField(
      controller: _controller,
      label: widget.config.label,
      hintText: widget.config.placeholder,
      keyboardType: TextInputType.number,
      validator: _getValidator(),
      readOnly: false, // We handle disabling through the wrapper
      onChanged: (value) {
        widget.onChanged(value);
      },
    );
  }

  Widget _buildTextAreaField() {
    return CustomTextField(
      controller: _controller,
      label: widget.config.label,
      hintText: widget.config.placeholder,
      maxLines: widget.config.properties['maxLines'] ?? 3,
      validator: _getValidator(),
      readOnly: false, // We handle disabling through the wrapper
      onChanged: (value) {
        widget.onChanged(value);
      },
    );
  }

  Widget _buildDateField() {
    return CustomTextField(
      controller: _controller,
      label: widget.config.label,
      hintText: widget.config.placeholder,
      readOnly: true,
      onTap: () async {
        final minDate = DateTime.tryParse(widget.config.properties['minDate']?.toString() ?? '') ?? DateTime(1900);
        final maxDate = DateTime.tryParse(widget.config.properties['maxDate']?.toString() ?? '') ?? DateTime(2100);
        
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().isAfter(maxDate) ? maxDate : 
                     (DateTime.now().isBefore(minDate) ? minDate : DateTime.now()),
          firstDate: minDate,
          lastDate: maxDate,
        );
        if (date != null) {
          final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          _controller.text = dateString;
          widget.onChanged(dateString);
        }
      },
      validator: _getValidator(),
    );
  }

  Widget _buildSelectField() {
    // If there's a dataSource, use it to load dynamic options
    if (widget.config.dataSource != null) {
      final dataState = ref.watch(fieldDataProvider(widget.config.fieldId));
      
      return dataState.when(
        data: (options) => _buildSelectFieldContent(options),
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.config.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ),
        error: (error, stack) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.config.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load options',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      );
    }

    // Otherwise use static options from properties
    final options = List<Map<String, dynamic>>.from(
      widget.config.properties['options'] ?? [],
    );
    
    return _buildSelectFieldContent(options);
  }

  Widget _buildSelectFieldContent(List<Map<String, dynamic>> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.config.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: widget.value?.toString(),
          hint: Text(widget.config.placeholder ?? ''),
          decoration: const InputDecoration(),
          validator: _getValidator(),
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option['value'].toString(),
              child: Text(option['label'].toString()),
            );
          }).toList(),
          onChanged: (value) {
            widget.onChanged(value);
          },
          icon: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          focusColor: Colors.transparent,
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRadioField() {
    final options = List<Map<String, dynamic>>.from(
      widget.config.properties['options'] ?? [],
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.config.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...options.map((option) {
          return RadioListTile<String>(
            title: Text(option['label'].toString()),
            value: option['value'].toString(),
            groupValue: widget.value?.toString(),
            onChanged: (value) {
              widget.onChanged(value);
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
          );
        }),
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckboxField() {
    if (widget.config.properties.containsKey('options')) {
      // Multiple checkboxes
      final options = List<Map<String, dynamic>>.from(
        widget.config.properties['options'] ?? [],
      );
      final selectedValues = List<String>.from(widget.value ?? []);
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.config.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...options.map((option) {
            final optionValue = option['value'].toString();
            return CheckboxListTile(
              title: Text(option['label'].toString()),
              value: selectedValues.contains(optionValue),
              onChanged: (checked) {
                final newValues = List<String>.from(selectedValues);
                if (checked == true) {
                  newValues.add(optionValue);
                } else {
                  newValues.remove(optionValue);
                }
                widget.onChanged(newValues);
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            );
          }),
          if (widget.errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      );
    } else {
      // Single checkbox
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            title: Text(widget.config.label),
            value: widget.value == true,
            onChanged: (checked) {
              widget.onChanged(checked);
            },
            contentPadding: EdgeInsets.zero,
          ),
          if (widget.errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      );
    }
  }

  Widget _buildFileField() {
    return FileUploadField(
      label: widget.config.label,
      placeholder: widget.config.placeholder,
      properties: widget.config.properties,
      initialValue: widget.value,
      onFileSelected: (fileData) {
        widget.onChanged(fileData);
      },
      onFileCleared: () {
        widget.onChanged(null);
      },
    );
  }

  Widget _buildSignatureField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SignaturePad(
          label: widget.config.label,
          placeholder: widget.config.placeholder,
          backgroundColor: Color(int.parse(
            widget.config.properties['backgroundColor']?.toString() ?? 'FFFFFFFF',
            radix: 16,
          )),
          penColor: Color(int.parse(
            widget.config.properties['penColor']?.toString() ?? 'FF000000',
            radix: 16,
          )),
          strokeWidth: (widget.config.properties['strokeWidth'] as num?)?.toDouble() ?? 2.0,
          onSigned: (data) {
            widget.onChanged({
              'bytes': data,
              'format': 'image/png',
              'timestamp': DateTime.now().toIso8601String(),
            });
          },
          onClear: () {
            widget.onChanged(null);
          },
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  TextInputType? _getKeyboardType() {
    switch (widget.config.type) {
      case FieldType.email:
        return TextInputType.emailAddress;
      case FieldType.phone:
        return TextInputType.phone;
      case FieldType.number:
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  String? Function(String?)? _getValidator() {
    return (value) {
      // Check required validation
      if (widget.config.required && (value?.isEmpty ?? true)) {
        return '${widget.config.label} is required';
      }

      // Check other validation rules
      for (final rule in widget.config.validationRules) {
        final error = _validateRule(value, rule);
        if (error != null) return error;
      }

      return null;
    };
  }

  String? _validateRule(String? value, form_config.ValidationRule rule) {
    if (value?.isEmpty ?? true) return null;

    switch (rule.type) {
      case 'minLength':
        if (value!.length < (rule.value as num).toInt()) {
          return rule.message;
        }
        break;
      case 'maxLength':
        if (value!.length > (rule.value as num).toInt()) {
          return rule.message;
        }
        break;
      case 'pattern':
        if (!RegExp(rule.value.toString()).hasMatch(value!)) {
          return rule.message;
        }
        break;
      case 'email':
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
          return rule.message;
        }
        break;
      case 'min':
        if (widget.config.type == FieldType.number) {
          final numValue = double.tryParse(value!);
          if (numValue != null && numValue < (rule.value as num)) {
            return rule.message;
          }
        }
        break;
      case 'max':
        if (widget.config.type == FieldType.number) {
          final numValue = double.tryParse(value!);
          if (numValue != null && numValue > (rule.value as num)) {
            return rule.message;
          }
        }
        break;
    }
    return null;
  }
}