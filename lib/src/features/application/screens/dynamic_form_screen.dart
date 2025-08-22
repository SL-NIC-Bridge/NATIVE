import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sl_nic_bridge/src/core/config/form_config_provider.dart';
import 'package:sl_nic_bridge/src/core/constants/app_routes.dart';
import '../../../shared/widgets/dynamic_form/dynamic_multi_step_form.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../shared/utils/form_utils.dart';
import '../repositories/application_repository.dart';
import '../providers/application_provider.dart';

class DynamicFormScreen extends ConsumerWidget {
  final String formType;
  
  const DynamicFormScreen({
    super.key,
    required this.formType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfigAsync = ref.watch(formConfigProvider);
    
    return appConfigAsync.when(
      data: (appConfig) {
        final formConfig = appConfig;
            
        if (formConfig.formTypes.isEmpty) {

          return Scaffold(
            appBar: AppBar(
              title: const Text('Form Not Found'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Form configuration not found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The requested form type is not available.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Check if the form type exists in the configuration
        if (!formConfig.formConfigs.containsKey(formType)) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Invalid Form Type'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Invalid form type: $formType',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The requested form type does not exist.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        return DynamicMultiStepForm(
          formConfig: formConfig,
          formType: formType,
          onSubmit: (formData) async {
            await _handleFormSubmission(context, ref, formData, formType);
          },
          onCancel: () {
            context.go(AppRoutes.applicationForm);
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load form configuration',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Please try again later.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(appConfigProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleFormSubmission(
    BuildContext context, 
    WidgetRef ref, 
    Map<String, dynamic> formData,
    String formType,
  ) async {
    try {
      // Get app config to access form configuration
      final appConfig = await ref.read(formConfigProvider.future);
      final formConfig = appConfig;
      
      if (formConfig.formTypes.isEmpty) {
        throw Exception('Form configuration not found');
      }

      // Clean and prepare form data for submission
      final cleanedData = FormUtils.prepareFormDataForSubmission(
        formConfig,
        formType,
        formData,
      );

      // Get application repository and submit the form
      final repository = await ref.read(applicationRepositoryProvider.future);
      
      // Map the cleaned data to the repository method parameters
      // This mapping will depend on the form type
      await _submitFormData(repository, formType, cleanedData);

      // Refresh the application status after successful submission
      ref.invalidate(applicationStatusProvider);
      
      if (!context.mounted) return;

      // Navigate back and show success message
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit application: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitFormData(
    ApplicationRepository repository,
    String formType,
    Map<String, dynamic> cleanedData,
  ) async {
    switch (formType) {
      case 'new_nic':
        await repository.submitApplication(
          previousNicNumber: cleanedData['previousNicNumber'],
          permanentAddress: cleanedData['permanentAddress'] ?? '',
          dateOfBirth: cleanedData['dateOfBirth'] != null 
              ? DateTime.tryParse(cleanedData['dateOfBirth']) ?? DateTime.now()
              : DateTime.now(),
          placeOfBirth: cleanedData['placeOfBirth'] ?? '',
        );
        break;
        
      case 'replacement_nic':
        await repository.submitApplication(
          previousNicNumber: cleanedData['previousNicNumber'],
          permanentAddress: cleanedData['permanentAddress'] ?? '',
          dateOfBirth: DateTime.now(), // This would need proper handling
          placeOfBirth: cleanedData['placeOfBirth'] ?? '',
        );
        break;
        
      case 'nic_correction':
        await repository.submitApplication(
          previousNicNumber: cleanedData['currentNicNumber'],
          permanentAddress: cleanedData['correctAddress'] ?? cleanedData['permanentAddress'] ?? '',
          dateOfBirth: cleanedData['correctDateOfBirth'] != null
              ? DateTime.tryParse(cleanedData['correctDateOfBirth']) ?? DateTime.now()
              : DateTime.now(),
          placeOfBirth: cleanedData['placeOfBirth'] ?? '',
        );
        break;
        
      default:
        throw Exception('Unknown form type: $formType');
    }
  }
}