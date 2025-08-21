import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sl_nic_bridge/src/core/services/mock_api_service.dart';
import '../../../core/errors/app_error.dart';
import '../models/application_model.dart';

// Mock repository provider that overrides the real repository
final mockApplicationRepositoryProvider = Provider<MockApplicationRepository>((ref) {
  final mockService = ref.watch(mockServiceProvider);
  return MockApplicationRepository(mockService);
});

class MockApplicationRepository {
  final MockApiService _mockService;
  
  MockApplicationRepository(this._mockService);

  Future<Application?> getCurrentApplication() async {
    try {
      final applications = await _mockService.getApplications();
      return applications.isNotEmpty 
          ? applications.reduce((a, b) => 
              a.submittedAt?.isAfter(b.submittedAt ?? DateTime(0)) ?? false ? a : b)
          : null;
    } catch (e, stack) {
      throw AppError.handle(e, stack);
    }
  }

  Future<List<Application>> getApplicationHistory() async {
    try {
      return await _mockService.getApplications();
    } catch (e, stack) {
      throw AppError.handle(e, stack);
    }
  }

  Future<Application> submitApplication({
    required String? previousNicNumber,
    required String permanentAddress,
    required DateTime dateOfBirth,
    required String placeOfBirth,
  }) async {
    try {
      return await _mockService.submitApplication(
        formId: previousNicNumber == null ? 'new_nic' : 'replacement_nic',
        formData: {
          'previousNicNumber': previousNicNumber ?? '',
          'permanentAddress': permanentAddress,
          'dateOfBirth': dateOfBirth.toIso8601String(),
          'placeOfBirth': placeOfBirth,
        },
      );
    } catch (e, stack) {
      throw AppError.handle(e, stack);
    }
  }

  Future<Application> updateApplicationStatus(String id, ApplicationStatus status) async {
    try {
      return await _mockService.updateApplicationStatus(id, status);
    } catch (e, stack) {
      throw AppError.handle(e, stack);
    }
  }

  Future<void> cancelApplication(String id) async {
    try {
      await _mockService.updateApplicationStatus(
        id, 
        ApplicationStatus.rejected,
        rejectionReason: 'Cancelled by user',
      );
    } catch (e, stack) {
      throw AppError.handle(e, stack);
    }
  }
}
