import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sl_nic_bridge/src/core/networking/api_client.dart';
import '../services/file_upload_service.dart';

final fileUploadServiceProvider = Provider((ref) async {
  return FileUploadService(
    await ref.watch(apiClientProvider.future),
  );
});

class FormSubmissionNotifier extends StateNotifier<AsyncValue<void>> {
  final FileUploadService _fileUploadService;
  
  FormSubmissionNotifier({
    required FileUploadService fileUploadService,
  }) : _fileUploadService = fileUploadService,
       super(const AsyncValue.data(null));

  Future<bool> submitForm(Map<String, dynamic> formData) async {
    state = const AsyncValue.loading();

    try {
      // Extract file fields that need to be uploaded
      final fileFields = formData.entries
          .where((entry) => entry.value is Map && 
                entry.value['path'] != null &&
                entry.value['mimeType'] != null)
          .toList();

      // Upload files first if there are any
      if (fileFields.isNotEmpty) {
        final uploadResults = await _fileUploadService.uploadMultipleFiles(
          fileFields.map((e) => e.value as Map<String, dynamic>).toList(),
        );

        // Check if all uploads were successful
        final failedUploads = uploadResults
            .where((result) => result['success'] != true)
            .toList();

        if (failedUploads.isNotEmpty) {
          throw Exception(
            'Failed to upload files: ${failedUploads.map((e) => e['file']).join(', ')}'
          );
        }

        // Replace file data with uploaded file URLs/IDs in form data
        for (var i = 0; i < fileFields.length; i++) {
          final field = fileFields[i];
          formData[field.key] = uploadResults[i]['data'];
        }
      }

      // Now submit the form data with file references
      // TODO: Implement your form submission logic here
      // final response = await _apiService.submitForm(formData);

      state = const AsyncValue.data(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}
