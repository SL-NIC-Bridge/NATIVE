import 'package:sl_nic_bridge/src/features/application/models/application_model.dart';
import 'package:sl_nic_bridge/src/features/auth/models/user_model.dart';

class MockData {
  static final List<Application> mockApplications = [
    Application(
      id: '1',
      userId: 'user123',
      formId: 'new_nic',
      status: ApplicationStatus.rejected,
      formData: {
        'previousNicNumber': '',
        'permanentAddress': '123 Main St, Colombo',
        'dateOfBirth': '1990-05-15',
        'placeOfBirth': 'Colombo',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now(),
      workflowSteps: [
        WorkflowStep(
          id: 'step1',
          title: 'Document Submission',
          description: 'Submit required documents',
          status: WorkflowStepStatus.completed,
          completedAt: DateTime.now().subtract(const Duration(days: 4)),
          order: 1,
        ),
        WorkflowStep(
          id: 'step2',
          title: 'Document Verification',
          description: 'Verify submitted documents',
          status: WorkflowStepStatus.inProgress,
          order: 2,
        ),
      ],
      submittedAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    Application(
      id: '2',
      userId: 'user123',
      formId: 'replacement_nic',
      status: ApplicationStatus.approved,
      formData: {
        'previousNicNumber': '199012345V',
        'permanentAddress': '456 Park Road, Kandy',
        'dateOfBirth': '1990-08-22',
        'placeOfBirth': 'Kandy',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      workflowSteps: [
        WorkflowStep(
          id: 'step1',
          title: 'Document Submission',
          description: 'Submit required documents',
          status: WorkflowStepStatus.completed,
          completedAt: DateTime.now().subtract(const Duration(days: 29)),
          order: 1,
        ),
        WorkflowStep(
          id: 'step2',
          title: 'Document Verification',
          description: 'Verify submitted documents',
          status: WorkflowStepStatus.completed,
          completedAt: DateTime.now().subtract(const Duration(days: 25)),
          order: 2,
        ),
      ],
      submittedAt: DateTime.now().subtract(const Duration(days: 29)),
    ),
    Application(
      id: '3',
      userId: 'user123',
      formId: 'nic_correction',
      status: ApplicationStatus.rejected,
      formData: {
        'previousNicNumber': '199087654V',
        'permanentAddress': '789 Lake View, Galle',
        'dateOfBirth': '1990-03-10',
        'placeOfBirth': 'Galle',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      workflowSteps: [
        WorkflowStep(
          id: 'step1',
          title: 'Document Submission',
          description: 'Submit required documents',
          status: WorkflowStepStatus.completed,
          completedAt: DateTime.now().subtract(const Duration(days: 14)),
          order: 1,
        ),
        WorkflowStep(
          id: 'step2',
          title: 'Document Verification',
          description: 'Verify submitted documents',
          status: WorkflowStepStatus.completed,
          completedAt: DateTime.now().subtract(const Duration(days: 1)),
          order: 2,
        ),
      ],
      rejectionReason: 'Incomplete documentation',
      submittedAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
  ];

  static final User mockUser = User(
    id: 'user123',
    fullName: 'John Doe',
    email: 'test@example.com',
    gramaNiladariDivisionNo: 'GN123',
    createdAt: DateTime.now().subtract(const Duration(days: 90)),
    updatedAt: DateTime.now(),
  );

  static Map<String, dynamic> getMockApiResponse({
    bool success = true,
    String? error,
    dynamic data,
  }) {
    return {
      'success': success,
      'error': error,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
