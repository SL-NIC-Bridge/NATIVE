import 'package:flutter/material.dart';
import '../../../features/application/models/form_config_model.dart';
import 'dynamic_form_field.dart';
import '../custom_button.dart';

class DynamicMultiStepForm extends StatefulWidget {
  final FormConfig formConfig;
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic> formData) onSubmit;
  final VoidCallback? onCancel;

  const DynamicMultiStepForm({
    super.key,
    required this.formConfig,
    this.initialData,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<DynamicMultiStepForm> createState() => _DynamicMultiStepFormState();
}

class _DynamicMultiStepFormState extends State<DynamicMultiStepForm> {
  late PageController _pageController;
  int _currentStep = 0;
  Map<String, dynamic> _formData = {};
  Map<String, String> _fieldErrors = {};
  bool _isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _formData = Map<String, dynamic>.from(widget.initialData ?? {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isFirstStep => _currentStep == 0;
  bool get _isLastStep => _currentStep == widget.formConfig.steps.length - 1;

  void _updateFieldValue(String fieldId, dynamic value) {
    setState(() {
      _formData[fieldId] = value;
      _fieldErrors.remove(fieldId); // Clear error when user makes changes
    });
  }

  bool _validateCurrentStep() {
    final currentStepConfig = widget.formConfig.steps[_currentStep];
    final errors = <String, String>{};
    
    for (final field in currentStepConfig.fields) {
      final value = _formData[field.fieldId];
      
      // Check required fields
      if (field.required && (value == null || value.toString().isEmpty)) {
        errors[field.fieldId] = '${field.label} is required';
        continue;
      }
      
      // Skip validation for empty non-required fields
      if (value == null || value.toString().isEmpty) continue;
      
      // Validate using field's validation rules
      for (final rule in field.validationRules) {
        final error = _validateRule(value.toString(), rule, field);
        if (error != null) {
          errors[field.fieldId] = error;
          break;
        }
      }
    }
    
    setState(() {
      _fieldErrors = errors;
    });
    
    return errors.isEmpty;
  }

  String? _validateRule(String value, ValidationRule rule, FormFieldConfig field) {
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
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return rule.message;
        }
        break;
      case 'min':
        if (field.type == FieldType.number) {
          final numValue = double.tryParse(value);
          if (numValue != null && numValue < (rule.value as num)) {
            return rule.message;
          }
        }
        break;
      case 'max':
        if (field.type == FieldType.number) {
          final numValue = double.tryParse(value);
          if (numValue != null && numValue > (rule.value as num)) {
            return rule.message;
          }
        }
        break;
    }
    return null;
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_isLastStep) {
        _submitForm();
      } else {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousStep() {
    if (!_isFirstStep) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitForm() async {
    if (_validateCurrentStep()) {
      setState(() => _isSubmitting = true);
      try {
        await widget.onSubmit(_formData);
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.formConfig.title),
        leading: widget.onCancel != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onCancel,
              )
            : null,
      ),
      body: Column(
        children: [
          // Step indicator
          if (widget.formConfig.steps.length > 1)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(widget.formConfig.steps.length, (index) {
                  final isActive = index == _currentStep;
                  final isCompleted = index < _currentStep;
                  
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < widget.formConfig.steps.length - 1 ? 8 : 0,
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: isCompleted || isActive
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.formConfig.steps[index].title,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isCompleted || isActive
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade600,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          
          // Form content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              itemCount: widget.formConfig.steps.length,
              itemBuilder: (context, stepIndex) {
                final step = widget.formConfig.steps[stepIndex];
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (step.description.isNotEmpty) ...[
                        Text(
                          step.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      ...step.fields.map((field) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: DynamicFormField(
                            config: field,
                            value: _formData[field.fieldId],
                            onChanged: (value) => _updateFieldValue(field.fieldId, value),
                            errorText: _fieldErrors[field.fieldId],
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (!_isFirstStep)
                  Expanded(
                    child: CustomButton(
                      onPressed: _isSubmitting ? null : _previousStep,
                      text: 'Previous',
                      type: ButtonType.secondary,
                    ),
                  ),
                
                if (!_isFirstStep) const SizedBox(width: 16),
                
                Expanded(
                  child: CustomButton(
                    onPressed: _isSubmitting ? null : _nextStep,
                    text: _isLastStep ? 'Submit' : 'Next',
                    isLoading: _isSubmitting,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}