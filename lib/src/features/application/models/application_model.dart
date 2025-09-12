import 'package:json_annotation/json_annotation.dart';

part 'application_model.g.dart';

@JsonSerializable()
class Application {
  final String id;
  final String userId;
  final String formId;
  final ApplicationStatus status;
  final Map<String, dynamic> formData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? rejectionReason;
  final List<WorkflowStep> workflowSteps;
  final DateTime? submittedAt;
  final String? comments;

  Application({
    required this.id,
    required this.userId,
    required this.formId,
    required this.status,
    required this.formData,
    required this.createdAt,
    required this.updatedAt,
    this.rejectionReason,
    required this.workflowSteps,
    this.submittedAt,
    this.comments,
  });

  factory Application.fromJson(Map<String, dynamic> json) =>
      _$ApplicationFromJson(json);

  Map<String, dynamic> toJson() => _$ApplicationToJson(this);
}

@JsonSerializable()
class WorkflowStep {
  final String id;
  final String title;
  final String description;
  final WorkflowStepStatus status;
  final DateTime? completedAt;
  final int order;

  const WorkflowStep({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.completedAt,
    required this.order,
  });

  factory WorkflowStep.fromJson(Map<String, dynamic> json) =>
      _$WorkflowStepFromJson(json);

  Map<String, dynamic> toJson() => _$WorkflowStepToJson(this);
}

enum ApplicationStatus {
  @JsonValue('SENT_TO_DRP')
  completed,
  @JsonValue('SUBMITTED')
  pending,
  @JsonValue('APPROVED_BY_GN')
  underReview,
  @JsonValue('ON_HOLD_BY_DS')
  onHold,
  @JsonValue('REJECTED_BY_GN')
  rejected,
}

enum WorkflowStepStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('skipped')
  skipped,
}
