import 'package:flutter/material.dart';
import 'package:sl_nic_bridge/src/core/config/field_type.dart';
import 'package:sl_nic_bridge/src/core/config/form_config_model.dart' as form_config;
import '../custom_text_field.dart';

class DynamicFormField extends StatefulWidget {
  final form_config.FormField config;
  final dynamic value;
  final Function(dynamic value) onChanged;
  final String? errorText;

  const DynamicFormField({
    super.key,
    required this.config,
    this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<DynamicFormField> createState() => _DynamicFormFieldState();
}

class _DynamicFormFieldState extends State<DynamicFormField> {
  late TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value?.toString() ?? '',
    );
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
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.config.type as FieldType) {
      case FieldType.text:
      case FieldType.email:
      case FieldType.phone:
        return _buildTextField();
      case FieldType.number:
        return _buildNumberField();
      case FieldType.textarea:
        return _buildTextAreaField();
      case FieldType.date:
        return _buildDateField();
      case FieldType.select:
        return _buildSelectField();
      case FieldType.radio:
        return _buildRadioField();
      case FieldType.checkbox:
        return _buildCheckboxField();
      case FieldType.file:
        return _buildFileField();
      case FieldType.signature:
        return _buildSignatureField();
    }
  }

  Widget _buildTextField() {
    return CustomTextField(
      controller: _controller,
      label: widget.config.label,
      hintText: widget.config.placeholder,
      keyboardType: _getKeyboardType(),
      validator: _getValidator(),
      onTap: widget.config.type == FieldType.phone ? null : () {
        // Handle any special tap behavior
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
    );
  }

  Widget _buildTextAreaField() {
    return CustomTextField(
      controller: _controller,
      label: widget.config.label,
      hintText: widget.config.placeholder,
      maxLines: widget.config.properties['maxLines'] ?? 3,
      validator: _getValidator(),
    );
  }

  Widget _buildDateField() {
    return CustomTextField(
      controller: _controller,
      label: widget.config.label,
      hintText: widget.config.placeholder,
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
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
        DropdownButtonFormField<String>(
          initialValue: widget.value?.toString(),
          hint: Text(widget.config.placeholder),
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
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () {
              // TODO: Implement file picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File picker not implemented yet')),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.upload_file, size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  widget.config.placeholder,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
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

  Widget _buildSignatureField() {
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
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () {
              // TODO: Implement signature pad
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signature pad not implemented yet')),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.draw, size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  widget.config.placeholder,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
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
    switch (widget.config.type as FieldType) {
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