import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/form_config_model.dart';
import '../../../shared/widgets/dynamic_form/dynamic_multi_step_form.dart';

class DynamicFormScreen extends ConsumerWidget {
  const DynamicFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DynamicMultiStepForm(
      formConfig: _getSampleFormConfig(),
      onSubmit: (formData) async {
        // Handle form submission
        await _handleFormSubmission(context, formData);
      },
      onCancel: () {
        context.pop();
      },
    );
  }

  FormConfig _getSampleFormConfig() {
    return FormConfig(
      id: 'sample-dynamic-form',
      title: 'Dynamic Multi-Step Form',
      description: 'A sample form demonstrating all field types',
      steps: [
        // Step 1: Personal Information
        FormStep(
          id: 'personal-info',
          title: 'Personal Info',
          description: 'Please provide your basic personal information',
          fields: [
            FormFieldConfig(
              fieldId: 'firstName',
              type: FieldType.text,
              label: 'First Name',
              placeholder: 'Enter your first name',
              required: true,
              properties: {},
              validationRules: [
                ValidationRule(
                  type: 'minLength',
                  value: 2,
                  message: 'First name must be at least 2 characters',
                ),
              ],
            ),
            FormFieldConfig(
              fieldId: 'lastName',
              type: FieldType.text,
              label: 'Last Name',
              placeholder: 'Enter your last name',
              required: true,
              properties: {},
              validationRules: [
                ValidationRule(
                  type: 'minLength',
                  value: 2,
                  message: 'Last name must be at least 2 characters',
                ),
              ],
            ),
            FormFieldConfig(
              fieldId: 'email',
              type: FieldType.email,
              label: 'Email Address',
              placeholder: 'Enter your email',
              required: true,
              properties: {},
              validationRules: [
                ValidationRule(
                  type: 'email',
                  value: true,
                  message: 'Please enter a valid email address',
                ),
              ],
            ),
            FormFieldConfig(
              fieldId: 'phone',
              type: FieldType.phone,
              label: 'Phone Number',
              placeholder: 'Enter your phone number',
              required: false,
              properties: {},
              validationRules: [],
            ),
            FormFieldConfig(
              fieldId: 'dateOfBirth',
              type: FieldType.date,
              label: 'Date of Birth',
              placeholder: 'Select your date of birth',
              required: true,
              properties: {},
              validationRules: [],
            ),
          ],
        ),
        
        // Step 2: Additional Details
        FormStep(
          id: 'additional-details',
          title: 'Details',
          description: 'Additional information and preferences',
          fields: [
            FormFieldConfig(
              fieldId: 'age',
              type: FieldType.number,
              label: 'Age',
              placeholder: 'Enter your age',
              required: true,
              properties: {},
              validationRules: [
                ValidationRule(
                  type: 'min',
                  value: 18,
                  message: 'Age must be at least 18',
                ),
                ValidationRule(
                  type: 'max',
                  value: 120,
                  message: 'Age must be less than 120',
                ),
              ],
            ),
            FormFieldConfig(
              fieldId: 'country',
              type: FieldType.select,
              label: 'Country',
              placeholder: 'Select your country',
              required: true,
              properties: {
                'options': [
                  {'value': 'us', 'label': 'United States'},
                  {'value': 'uk', 'label': 'United Kingdom'},
                  {'value': 'ca', 'label': 'Canada'},
                  {'value': 'au', 'label': 'Australia'},
                  {'value': 'de', 'label': 'Germany'},
                  {'value': 'fr', 'label': 'France'},
                  {'value': 'lk', 'label': 'Sri Lanka'},
                ],
              },
              validationRules: [],
            ),
            FormFieldConfig(
              fieldId: 'gender',
              type: FieldType.radio,
              label: 'Gender',
              placeholder: '',
              required: true,
              properties: {
                'options': [
                  {'value': 'male', 'label': 'Male'},
                  {'value': 'female', 'label': 'Female'},
                  {'value': 'other', 'label': 'Other'},
                  {'value': 'prefer-not-to-say', 'label': 'Prefer not to say'},
                ],
              },
              validationRules: [],
            ),
            FormFieldConfig(
              fieldId: 'bio',
              type: FieldType.textarea,
              label: 'Bio',
              placeholder: 'Tell us about yourself...',
              required: false,
              properties: {
                'maxLines': 4,
              },
              validationRules: [
                ValidationRule(
                  type: 'maxLength',
                  value: 500,
                  message: 'Bio must not exceed 500 characters',
                ),
              ],
            ),
          ],
        ),
        
        // Step 3: Preferences and Files
        FormStep(
          id: 'preferences-files',
          title: 'Preferences',
          description: 'Your preferences and document uploads',
          fields: [
            FormFieldConfig(
              fieldId: 'interests',
              type: FieldType.checkbox,
              label: 'Interests',
              placeholder: '',
              required: false,
              properties: {
                'options': [
                  {'value': 'sports', 'label': 'Sports'},
                  {'value': 'music', 'label': 'Music'},
                  {'value': 'movies', 'label': 'Movies'},
                  {'value': 'reading', 'label': 'Reading'},
                  {'value': 'travel', 'label': 'Travel'},
                  {'value': 'technology', 'label': 'Technology'},
                ],
              },
              validationRules: [],
            ),
            FormFieldConfig(
              fieldId: 'newsletter',
              type: FieldType.checkbox,
              label: 'Subscribe to Newsletter',
              placeholder: '',
              required: false,
              properties: {},
              validationRules: [],
            ),
            FormFieldConfig(
              fieldId: 'profilePhoto',
              type: FieldType.file,
              label: 'Profile Photo',
              placeholder: 'Upload your profile photo',
              required: false,
              properties: {},
              validationRules: [],
            ),
            FormFieldConfig(
              fieldId: 'signature',
              type: FieldType.signature,
              label: 'Digital Signature',
              placeholder: 'Please sign here',
              required: true,
              properties: {},
              validationRules: [],
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleFormSubmission(BuildContext context, Map<String, dynamic> formData) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    if (!context.mounted) return;
    
    // Show success message and return to previous screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Form submitted successfully!\nData: ${formData.toString()}'),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.green,
      ),
    );
    
    context.pop();
  }
}