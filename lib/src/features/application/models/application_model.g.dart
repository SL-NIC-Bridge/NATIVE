// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Application _$ApplicationFromJson(Map<String, dynamic> json) => Application(
  id: json['id'] as String,
  userId: json['userId'] as String,
  formId: json['formId'] as String,
  status: $enumDecode(_$ApplicationStatusEnumMap, json['status']),
  formData: json['formData'] as Map<String, dynamic>,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  rejectionReason: json['rejectionReason'] as String?,
  workflowSteps: (json['workflowSteps'] as List<dynamic>)
      .map((e) => WorkflowStep.fromJson(e as Map<String, dynamic>))
      .toList(),
  submittedAt: json['submittedAt'] == null
      ? null
      : DateTime.parse(json['submittedAt'] as String),
  comments: json['comments'] as String?,
);

Map<String, dynamic> _$ApplicationToJson(Application instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'formId': instance.formId,
      'status': _$ApplicationStatusEnumMap[instance.status]!,
      'formData': instance.formData,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'rejectionReason': ?instance.rejectionReason,
      'workflowSteps': instance.workflowSteps.map((e) => e.toJson()).toList(),
      'submittedAt': ?instance.submittedAt?.toIso8601String(),
      'comments': ?instance.comments,
    };

const _$ApplicationStatusEnumMap = {
  ApplicationStatus.completed: 'SENT_TO_DRP',
  ApplicationStatus.pending: 'SUBMITTED',
  ApplicationStatus.underReview: 'APPROVED_BY_GN',
  ApplicationStatus.onHold: 'ON_HOLD_BY_DS',
  ApplicationStatus.rejected: 'REJECTED_BY_GN',
};

WorkflowStep _$WorkflowStepFromJson(Map<String, dynamic> json) => WorkflowStep(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  status: $enumDecode(_$WorkflowStepStatusEnumMap, json['status']),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  order: (json['order'] as num).toInt(),
);

Map<String, dynamic> _$WorkflowStepToJson(WorkflowStep instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'status': _$WorkflowStepStatusEnumMap[instance.status]!,
      'completedAt': ?instance.completedAt?.toIso8601String(),
      'order': instance.order,
    };

const _$WorkflowStepStatusEnumMap = {
  WorkflowStepStatus.pending: 'pending',
  WorkflowStepStatus.inProgress: 'in_progress',
  WorkflowStepStatus.completed: 'completed',
  WorkflowStepStatus.skipped: 'skipped',
};
