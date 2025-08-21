import 'package:json_annotation/json_annotation.dart';

part 'form_config_model.g.dart';

@JsonSerializable()
class FormConfig {
  final String id;
  final String title;
  final String description;
  final List<FormStep> steps;

  const FormConfig({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
  });

  factory FormConfig.fromJson(Map<String, dynamic> json) =>
      _$FormConfigFromJson(json);

  Map<String, dynamic> toJson() => _$FormConfigToJson(this);
}

@JsonSerializable()
class FormStep {
  final String id;
  final String title;
  final String description;
  final List<FormFieldConfig> fields;

  const FormStep({
    required this.id,
    required this.title,
    required this.description,
    required this.fields,
  });

  factory FormStep.fromJson(Map<String, dynamic> json) =>
      _$FormStepFromJson(json);

  Map<String, dynamic> toJson() => _$FormStepToJson(this);
}

@JsonSerializable()
class FormFieldConfig {
  final String fieldId;
  final FieldType type;
  final String label;
  final String? placeholder;
  final Map<String, dynamic> properties;
  final List<ValidationRule> validationRules;
  final bool required;

  const FormFieldConfig({
    required this.fieldId,
    required this.type,
    required this.label,
    this.placeholder,
    required this.properties,
    required this.validationRules,
    this.required = false,
  });

  factory FormFieldConfig.fromJson(Map<String, dynamic> json) =>
      _$FormFieldConfigFromJson(json);

  Map<String, dynamic> toJson() => _$FormFieldConfigToJson(this);
}

@JsonSerializable()
class ValidationRule {
  final String type;
  final dynamic value;
  final String message;

  const ValidationRule({
    required this.type,
    required this.value,
    required this.message,
  });

  factory ValidationRule.fromJson(Map<String, dynamic> json) =>
      _$ValidationRuleFromJson(json);

  Map<String, dynamic> toJson() => _$ValidationRuleToJson(this);
}

enum FieldType {
  @JsonValue('text')
  text,
  @JsonValue('number')
  number,
  @JsonValue('email')
  email,
  @JsonValue('phone')
  phone,
  @JsonValue('date')
  date,
  @JsonValue('checkbox')
  checkbox,
  @JsonValue('radio')
  radio,
  @JsonValue('select')
  select,
  @JsonValue('file')
  file,
  @JsonValue('signature')
  signature,
  @JsonValue('textarea')
  textarea,
}