import 'package:sl_nic_bridge/src/core/constants/api_endpoints.dart';
import '../models/application_model.dart';
import '../../../core/networking/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

final applicationRepositoryProvider = FutureProvider<ApplicationRepository>((ref) async {
  final dio = await ref.watch(apiClientProvider.future);
  return ApplicationRepository(dio);
});

class ApplicationRepository {
  final Dio _dio;
  static const _baseUrl = '/applications';

  ApplicationRepository(this._dio);

  Future<Application?> getCurrentApplication() async {
    try {
      final response = await _dio.get(ApiEndpoints.getCurrentApplication);
      if (response.statusCode == 404) {
        return null;
      }
      
      // Handle the nested response structure from backend
      final responseData = response.data;
      if (responseData is Map<String, dynamic> && responseData['success'] == true) {
        final applicationData = responseData['data'] as Map<String, dynamic>;
        
        // Transform the backend response to match our model structure
        final transformedData = {
          'id': applicationData['id'],
          'userId': applicationData['userId'],
          'formId': applicationData['applicationType'], // Map applicationType to formId
          'status': applicationData['currentStatus'] ?? '', // Map currentStatus to status
          'formData': applicationData['applicationData'] ?? {},
          'createdAt': applicationData['createdAt'],
          'updatedAt': applicationData['updatedAt'],
          'rejectionReason': applicationData['rejectionReason'],
          'workflowSteps': [], // Default empty array since backend doesn't return this yet
          'submittedAt': applicationData['createdAt'], // Use createdAt as submittedAt for now
          'comments': applicationData['comments'],
        };
        
        return Application.fromJson(transformedData);
      }
      
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<List<Application>> getApplicationHistory() async {
    final response = await _dio.get('$_baseUrl/history');
    final List<dynamic> data = response.data;
    return data.map((json) => Application.fromJson(json)).toList();
  }


  /// New method to submit application with complete form data
  /// This handles the dynamic form submissions with all field data
  Future<Map<String, dynamic>> submitApplication({
    required String formType,
    required Map<String, dynamic> formData,
  }) async {
    // Remove file references from form data before submission
    final dataForSubmission = Map<String, dynamic>.from(formData)
      ..removeWhere((key, value) =>
          value is Map<String, dynamic> && value['type'] == 'file_reference');

    final response = await _dio.post(ApiEndpoints.submitApplication, data: {
      'applicationType': formType,
      'applicationData': dataForSubmission,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> cancelApplication(String id) async {
    await _dio.delete('$_baseUrl/$id');
  }
}
