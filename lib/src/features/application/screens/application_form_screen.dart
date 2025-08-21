import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../providers/application_provider.dart';
import '../repositories/application_repository.dart';

class ApplicationFormScreen extends ConsumerStatefulWidget {
  const ApplicationFormScreen({super.key});

  @override
  ConsumerState<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends ConsumerState<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  final _nicController = TextEditingController();
  final _addressController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _birthplaceController = TextEditingController();

  @override
  void dispose() {
    _nicController.dispose();
    _addressController.dispose();
    _birthdayController.dispose();
    _birthplaceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      try {
        final repository = await ref.read(applicationRepositoryProvider.future);
        await repository.submitApplication(
          previousNicNumber: _nicController.text.isNotEmpty ? _nicController.text : null,
          permanentAddress: _addressController.text,
          dateOfBirth: DateTime.parse(_birthdayController.text),
          placeOfBirth: _birthplaceController.text,
        );
        
        if (!mounted) return;

        // Refresh the application status
        ref.invalidate(applicationStatusProvider);
        
        context.pop(); // Return to previous screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('NIC Application Form'),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CustomTextField(
                  controller: _nicController,
                  label: 'Previous NIC Number (if any)',
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _addressController,
                  label: 'Permanent Address',
                  maxLines: 3,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _birthdayController,
                  label: 'Date of Birth',
                  keyboardType: TextInputType.datetime,
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
                      lastDate: DateTime.now().subtract(const Duration(days: 365 * 15)),
                    );
                    if (date != null) {
                      _birthdayController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    }
                  },
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please select your date of birth';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _birthplaceController,
                  label: 'Place of Birth',
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your place of birth';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                CustomButton(
                  onPressed: _isLoading ? null : _submitForm,
                  text: 'Submit Application',
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          const LoadingOverlay(
            isLoading: true,
            child: SizedBox.expand(),
          ),
      ],
    );
  }
}