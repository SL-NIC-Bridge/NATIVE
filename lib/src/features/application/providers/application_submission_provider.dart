import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/application_repository.dart';
import '../services/application_submission_service.dart';
import '../../../core/services/file_upload_service.dart';
import '../../../core/networking/api_client.dart';

// Provider for file upload service using the configured Dio client
final fileUploadServiceProvider = FutureProvider<FileUploadService>((ref) async {
  final dio = await ref.watch(apiClientProvider.future);
  return FileUploadService(dio);
});

// Provider for application submission service
final applicationSubmissionServiceProvider = FutureProvider<ApplicationSubmissionService>((ref) async {
  try {
    final applicationRepository = await ref.watch(applicationRepositoryProvider.future);
    final fileUploadService = await ref.watch(fileUploadServiceProvider.future);
    
    return ApplicationSubmissionService(
      applicationRepository: applicationRepository,
      fileUploadService: fileUploadService,
    );
  } catch (e) {
    // Add debug logging to see what's failing
    print('Error creating ApplicationSubmissionService: $e');
    rethrow;
  }
});
