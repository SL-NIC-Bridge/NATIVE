import 'package:json_annotation/json_annotation.dart';

part 'field_dependency.g.dart';

enum DependencyBehavior {
  hide,
  disable
}

@JsonSerializable()
class FieldDependencyCondition {
  final String field;
  final String condition;
  final dynamic value;
  @JsonKey(defaultValue: DependencyBehavior.hide)
  final DependencyBehavior behavior;

  FieldDependencyCondition({
    required this.field,
    required this.condition,
    required this.value,
    this.behavior = DependencyBehavior.hide,
  });

  factory FieldDependencyCondition.fromJson(Map<String, dynamic> json) =>
      _$FieldDependencyConditionFromJson(json);

  Map<String, dynamic> toJson() => _$FieldDependencyConditionToJson(this);

  bool evaluate(dynamic fieldValue) {
    switch (condition) {
      case 'equals':
        return fieldValue == value;
      case 'notEquals':
        return fieldValue != value;
      case 'in':
        if (value is List) {
          return value.contains(fieldValue);
        }
        return false;
      case 'notIn':
        if (value is List) {
          return !value.contains(fieldValue);
        }
        return true;
      case 'contains':
        if (fieldValue is String && value is String) {
          return fieldValue.contains(value);
        }
        return false;
      case 'notContains':
        if (fieldValue is String && value is String) {
          return !fieldValue.contains(value);
        }
        return true;
      case 'startsWith':
        if (fieldValue is String && value is String) {
          return fieldValue.startsWith(value);
        }
        return false;
      case 'endsWith':
        if (fieldValue is String && value is String) {
          return fieldValue.endsWith(value);
        }
        return false;
      case 'isTrue':
        return fieldValue == true;
      case 'isFalse':
        return fieldValue == false;
      case 'isNull':
        return fieldValue == null;
      case 'notNull':
        return fieldValue != null;
      default:
        return false;
    }
  }
}
