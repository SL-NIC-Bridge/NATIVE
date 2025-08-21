import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mocks/mock_data.dart';
import '../../features/application/models/application_model.dart';
import '../../features/auth/models/user_model.dart';

// Provider for mock service
final mockServiceProvider = Provider<MockApiService>((ref) {
  return MockApiService();
});

class MockApiService {
  // Simulate network delay
  static const mockDelay = Duration(milliseconds: 800);
  
  // Simulate API success rate
  static const successRate = 0.9; // 90% success rate

  // Store submitted applications
  final List<Application> _applications = [...MockData.mockApplications];
  User _currentUser = MockData.mockUser;

  // Get all applications for the current user
  Future<List<Application>> getApplications() async {
    await _simulateNetworkDelay();
    await _simulateRandomFailure();
    
    return _applications
        .where((app) => app.userId == _currentUser.id)
        .toList();
  }

  // Get application by ID
  Future<Application> getApplicationById(String id) async {
    await _simulateNetworkDelay();
    await _simulateRandomFailure();
    
    final application = _applications.firstWhere(
      (app) => app.id == id,
      orElse: () => throw Exception('Application not found'),
    );
    
    if (application.userId != _currentUser.id) {
      throw Exception('Unauthorized access');
    }
    
    return application;
  }

  // Submit new application
  Future<Application> submitApplication({
    required String formId,
    required Map<String, dynamic> formData,
  }) async {
    await _simulateNetworkDelay();
    await _simulateRandomFailure();
    
    final now = DateTime.now();
    final newApplication = Application(
      id: 'app_${_applications.length + 1}',
      userId: _currentUser.id,
      formId: formId,
      status: ApplicationStatus.submitted,
      formData: formData,
      createdAt: now,
      updatedAt: now,
      workflowSteps: [
        WorkflowStep(
          id: 'step1',
          title: 'Document Submission',
          description: 'Submit required documents',
          status: WorkflowStepStatus.completed,
          completedAt: now,
          order: 1,
        ),
        WorkflowStep(
          id: 'step2',
          title: 'Document Verification',
          description: 'Verify submitted documents',
          status: WorkflowStepStatus.pending,
          order: 2,
        ),
      ],
      submittedAt: now,
    );
    
    _applications.add(newApplication);
    return newApplication;
  }

  // Update application status
  Future<Application> updateApplicationStatus(
    String id,
    ApplicationStatus newStatus, {
    String? rejectionReason,
  }) async {
    await _simulateNetworkDelay();
    await _simulateRandomFailure();
    
    final index = _applications.indexWhere((app) => app.id == id);
    if (index == -1) {
      throw Exception('Application not found');
    }
    
    final application = _applications[index];
    if (application.userId != _currentUser.id) {
      throw Exception('Unauthorized access');
    }
    
    final now = DateTime.now();
    final updatedSteps = [...application.workflowSteps];
    
    // Update workflow steps based on status
    if (newStatus == ApplicationStatus.approved) {
      for (var i = 0; i < updatedSteps.length; i++) {
        updatedSteps[i] = WorkflowStep(
          id: updatedSteps[i].id,
          title: updatedSteps[i].title,
          description: updatedSteps[i].description,
          status: WorkflowStepStatus.completed,
          completedAt: now,
          order: updatedSteps[i].order,
        );
      }
    }
    
    final updatedApplication = Application(
      id: application.id,
      userId: application.userId,
      formId: application.formId,
      status: newStatus,
      formData: application.formData,
      createdAt: application.createdAt,
      updatedAt: now,
      workflowSteps: updatedSteps,
      rejectionReason: rejectionReason,
      submittedAt: application.submittedAt,
      comments: application.comments,
    );
    
    _applications[index] = updatedApplication;
    return updatedApplication;
  }

  // Get current user
  Future<User> getCurrentUser() async {
    await _simulateNetworkDelay();
    await _simulateRandomFailure();
    return _currentUser;
  }

  // Update user profile
  Future<User> updateUserProfile({
    String? fullName,
    String? email,
    String? gramaNiladariDivisionNo,
  }) async {
    await _simulateNetworkDelay();
    await _simulateRandomFailure();
    
    _currentUser = User(
      id: _currentUser.id,
      fullName: fullName ?? _currentUser.fullName,
      email: email ?? _currentUser.email,
      gramaNiladariDivisionNo: gramaNiladariDivisionNo ?? _currentUser.gramaNiladariDivisionNo,
      createdAt: _currentUser.createdAt,
      updatedAt: DateTime.now(),
    );
    
    return _currentUser;
  }

  // Helper method to simulate network delay
  Future<void> _simulateNetworkDelay() async {
    await Future.delayed(mockDelay);
  }

  // Helper method to simulate random failures
  Future<void> _simulateRandomFailure() async {
    if (DateTime.now().millisecond / 1000 > successRate) {
      throw Exception('Random network error occurred');
    }
  }
}
