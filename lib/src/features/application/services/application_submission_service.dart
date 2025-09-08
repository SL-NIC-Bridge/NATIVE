import '../models/application_create_dto.dart';
import '../repositories/application_repository.dart';
import '../../../core/services/file_upload_service.dart';

/// Service to handle application submission with file uploads
class ApplicationSubmissionService {
  final ApplicationRepository _applicationRepository;
  final FileUploadService _fileUploadService;

  ApplicationSubmissionService({
    required ApplicationRepository applicationRepository,
    required FileUploadService fileUploadService,
  })  : _applicationRepository = applicationRepository,
        _fileUploadService = fileUploadService;

  /// Submits an application with form data and file attachments
  Future<ApplicationCreateResponse> submitApplication({
    required String formType,
    required Map<String, dynamic> formData,
  }) async {
    // 1. Create DTO to separate form data from file attachment info
    final dto = ApplicationCreateDto.fromDynamicFormData(formType, formData);

    // 2. Submit the initial application data (without files) to get an ID
    final initialResponseData = await _applicationRepository.submitApplication(
      formType: dto.formType,
      formData: dto.formData, // This now gets cleaned in the repository
    );

    final response = ApplicationCreateResponse.fromJson(initialResponseData);
    final applicationId = response.applicationId;

    // 3. If there are files, upload them with the new application ID
    if (dto.attachments.isNotEmpty) {
      final fileUploads = dto.attachments.map((attachment) {
        return _fileUploadService.uploadFile({
          'path': attachment.filePath,
          'name': attachment.fileName,
          'mimeType': attachment.mimeType,
          'size': attachment.fileSize,
          'fieldKey': attachment.fieldId,
          'applicationId': applicationId, // Pass the received ID to the upload service
        });
      }).toList();

      // Wait for all file uploads to complete
      final uploadResults = await Future.wait(fileUploads);

      // Check for any failed uploads
      final failedUploads = uploadResults.where((r) => r['success'] != true).toList();
      if (failedUploads.isNotEmpty) {
        final errors = failedUploads.map((e) => e['error'] ?? 'Unknown error').join(', ');
        throw Exception('One or more file uploads failed: $errors');
      }
    }

    // 4. Return the successful response from the initial submission
    return response;
  }
}

/// Example usage in your dynamic form submission
class ExampleUsage {
  static Future<void> handleFormSubmission(
    ApplicationSubmissionService submissionService,
    String formType,
    Map<String, dynamic> formData,
  ) async {
    try {
      // This is the form data coming from your DynamicMultiStepForm
      // It contains regular fields + file objects like:
      // {
      //   'familyName': 'SILVA',
      //   'name': 'JOHN',
      //   'applicantPhoto': {
      //     'path': '/storage/photo.jpg',
      //     'name': 'photo.jpg',
      //     'mimeType': 'image/jpeg',
      //     'size': 1024000
      //   },
      //   'birthCertUpload': {
      //     'path': '/storage/birth_cert.pdf',
      //     'name': 'birth_certificate.pdf',
      //     'mimeType': 'application/pdf',
      //     'size': 2048000
      //   },
      //   'declaration': true,
      //   'signature': 'base64_signature_data'
      // }

      final response = await submissionService.submitApplication(
        formType: formType,
        formData: formData,
      );

      print('Application submitted successfully!');
      print('Application ID: ${response.applicationId}');
      print('Status: ${response.status}');
      
    } catch (e) {
      print('Failed to submit application: $e');
      rethrow;
    }
  }
}
