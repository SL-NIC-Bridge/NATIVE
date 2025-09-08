import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sl_nic_bridge/src/core/config/form_config_provider.dart';
import 'package:sl_nic_bridge/src/core/constants/app_routes.dart';
import '../../../shared/widgets/dynamic_form/dynamic_multi_step_form.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../shared/widgets/dynamic_form/error_display.dart';
import '../../../shared/utils/form_utils.dart';
import '../repositories/application_repository.dart';
import '../providers/application_provider.dart';
import '../providers/application_submission_provider.dart';


class DynamicFormScreen extends ConsumerWidget {
  final String formType;
  
  const DynamicFormScreen({
    super.key,
    required this.formType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfigAsync = ref.watch(formConfigProvider);
    
    // Get OCR data from route extra if available
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final ocrData = extra?['ocrData'] as Map<String, dynamic>?;
    
    return appConfigAsync.when(
      data: (appConfig) {
        final formConfig = appConfig;

        if (formConfig.formTypes.isEmpty) {
          return _buildFormNotFound(context, 'Form configuration not found');
        }

        if (!formConfig.formConfigs.containsKey(formType)) {
          return _buildFormNotFound(context, 'Invalid form type: $formType\nThe requested form type does not exist.');
        }

        return DynamicMultiStepForm(
          formConfig: formConfig,
          formType: formType,
          ocrData: ocrData, // Pass OCR data to the form
          onSubmit: (formData) async {
            await _handleFormSubmission(context, ref, formData, formType);
          },
          onCancel: () {
            context.go(AppRoutes.dashboard);
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: ErrorDisplay(message: 'Failed to load form configuration: $error', onRetry: () => ref.invalidate(appConfigProvider)),
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
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Submitting application...'),
            ],
          ),
          duration: Duration(seconds: 30), // Longer duration for file uploads
        ),
      );

      // Check if form data contains file fields
      final hasFiles = formData.values.any((value) => 
        value is Map<String, dynamic> &&
        value.containsKey('path') &&
        value.containsKey('mimeType')
      );

      if (hasFiles) {
        // Use ApplicationSubmissionService for forms with file uploads
        final submissionService = await ref.read(applicationSubmissionServiceProvider.future);
        
        final response = await submissionService.submitApplication(
          formType: formType,
          formData: formData, // Raw form data with files
        );

        if (!context.mounted) return;
        
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application submitted successfully! ID: ${response.applicationId}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        context.pop();
      } else {
        // Use direct repository submission for forms without files
        final appConfig = await ref.read(formConfigProvider.future);
        final formConfig = appConfig;
        
        if (formConfig.formTypes.isEmpty) {
          throw Exception('Form configuration not found');
        }

        // Clean and prepare form data for submission using existing FormUtils
        final cleanedData = FormUtils.prepareFormDataForSubmission(
          formConfig,
          formType,
          formData,
        );

        // Add metadata to identify source and timestamp
        cleanedData['formSource'] = 'dynamic_form';
        cleanedData['submittedAt'] = DateTime.now().toIso8601String();

        // Get application repository and submit using new API structure
        final repository = await ref.read(applicationRepositoryProvider.future);
        
        await repository.submitApplication(
          formType: formType,
          formData: cleanedData,
        );

        if (!context.mounted) return;
        
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh the application status after successful submission
      ref.invalidate(applicationStatusProvider);
      
      if (!context.mounted) return;

      // Navigate back to dashboard
      context.pop();
      
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit application: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Widget _buildFormNotFound(BuildContext context, String message) {
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
              message,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => context.pop(), child: const Text('Go Back')),
          ],
        ),
      ),
    );
  }
}