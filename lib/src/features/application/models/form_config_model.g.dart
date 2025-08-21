// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FormConfig _$FormConfigFromJson(Map<String, dynamic> json) => FormConfig(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      steps: (json['steps'] as List<dynamic>)
          .map((e) => FormStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FormConfigToJson(FormConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'steps': instance.steps,
    };

FormStep _$FormStepFromJson(Map<String, dynamic> json) => FormStep(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      fields: (json['fields'] as List<dynamic>)
          .map((e) => FormFieldConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FormStepToJson(FormStep instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'fields': instance.fields,
    };

FormFieldConfig _$FormFieldConfigFromJson(Map<String, dynamic> json) =>
    FormFieldConfig(
      fieldId: json['fieldId'] as String,
      type: $enumDecode(_$FieldTypeEnumMap, json['type']),
      label: json['label'] as String,
      placeholder: json['placeholder'] as String?,
      properties: json['properties'] as Map<String, dynamic>,
      validationRules: (json['validationRules'] as List<dynamic>)
          .map((e) => ValidationRule.fromJson(e as Map<String, dynamic>))
          .toList(),
      required: json['required'] as bool? ?? false,
    );

Map<String, dynamic> _$FormFieldConfigToJson(FormFieldConfig instance) =>
    <String, dynamic>{
      'fieldId': instance.fieldId,
      'type': _$FieldTypeEnumMap[instance.type]!,
      'label': instance.label,
      'placeholder': instance.placeholder,
      'properties': instance.properties,
      'validationRules': instance.validationRules,
      'required': instance.required,
    };

const _$FieldTypeEnumMap = {
  FieldType.text: 'text',
  FieldType.email: 'email',
  FieldType.phone: 'phone',
  FieldType.date: 'date',
  FieldType.checkbox: 'checkbox',
  FieldType.radio: 'radio',
  FieldType.select: 'select',
  FieldType.file: 'file',
  FieldType.signature: 'signature',
  FieldType.textarea: 'textarea',
};

ValidationRule _$ValidationRuleFromJson(Map<String, dynamic> json) =>
    ValidationRule(
      type: json['type'] as String,
      value: json['value'],
      message: json['message'] as String,
    );

Map<String, dynamic> _$ValidationRuleToJson(ValidationRule instance) =>
    <String, dynamic>{
      'type': instance.type,
      'value': instance.value,
      'message': instance.message,
    };
