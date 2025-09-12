// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidationRule _$ValidationRuleFromJson(Map<String, dynamic> json) =>
    ValidationRule(
      type: json['type'] as String,
      value: json['value'],
      message: json['message'] as String,
    );

Map<String, dynamic> _$ValidationRuleToJson(ValidationRule instance) =>
    <String, dynamic>{
      'type': instance.type,
      'value': ?instance.value,
      'message': instance.message,
    };

FormField _$FormFieldFromJson(Map<String, dynamic> json) => FormField(
  fieldId: json['fieldId'] as String,
  type: FormField._fieldTypeFromJson(json['type'] as String),
  label: json['label'] as String,
  placeholder: json['placeholder'] as String?,
  required: json['required'] as bool,
  properties: json['properties'] as Map<String, dynamic>,
  validationRules: (json['validationRules'] as List<dynamic>)
      .map((e) => ValidationRule.fromJson(e as Map<String, dynamic>))
      .toList(),
  dependencies: (json['dependencies'] as List<dynamic>?)
      ?.map((e) => FieldDependencyCondition.fromJson(e as Map<String, dynamic>))
      .toList(),
  dataSource: json['dataSource'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$FormFieldToJson(FormField instance) => <String, dynamic>{
  'fieldId': instance.fieldId,
  'type': FormField._fieldTypeToJson(instance.type),
  'label': instance.label,
  'dependencies': ?instance.dependencies?.map((e) => e.toJson()).toList(),
  'dataSource': ?instance.dataSource,
  'placeholder': ?instance.placeholder,
  'required': instance.required,
  'properties': instance.properties,
  'validationRules': instance.validationRules.map((e) => e.toJson()).toList(),
};

FormFieldVariation _$FormFieldVariationFromJson(Map<String, dynamic> json) =>
    FormFieldVariation(
      fieldId: json['fieldId'] as String,
      type: FormField._fieldTypeFromJson(json['type'] as String),
      label: json['label'] as String,
      placeholder: json['placeholder'] as String?,
      required: json['required'] as bool,
      properties: json['properties'] as Map<String, dynamic>,
      validationRules: (json['validationRules'] as List<dynamic>)
          .map((e) => ValidationRule.fromJson(e as Map<String, dynamic>))
          .toList(),
      extendsField: json['extends'] as String,
    );

Map<String, dynamic> _$FormFieldVariationToJson(
  FormFieldVariation instance,
) => <String, dynamic>{
  'fieldId': instance.fieldId,
  'type': FormField._fieldTypeToJson(instance.type),
  'label': instance.label,
  'placeholder': ?instance.placeholder,
  'required': instance.required,
  'properties': instance.properties,
  'validationRules': instance.validationRules.map((e) => e.toJson()).toList(),
  'extends': instance.extendsField,
};

FormType _$FormTypeFromJson(Map<String, dynamic> json) => FormType(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
);

Map<String, dynamic> _$FormTypeToJson(FormType instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
};

FormStep _$FormStepFromJson(Map<String, dynamic> json) => FormStep(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  fields: (json['fields'] as List<dynamic>)
      .map((e) => FormField.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$FormStepToJson(FormStep instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'fields': instance.fields.map((e) => e.toJson()).toList(),
};

FormConfig _$FormConfigFromJson(Map<String, dynamic> json) => FormConfig(
  commonFields: (json['commonFields'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, FormField.fromJson(e as Map<String, dynamic>)),
  ),
  fieldVariations: (json['fieldVariations'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry(k, FormFieldVariation.fromJson(e as Map<String, dynamic>)),
  ),
  formTypes: (json['formTypes'] as List<dynamic>)
      .map((e) => FormType.fromJson(e as Map<String, dynamic>))
      .toList(),
  formConfigs: (json['formConfigs'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, FormConfigEntry.fromJson(e as Map<String, dynamic>)),
  ),
  ocrConfigurations:
      (json['ocrConfigurations'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, OCRConfiguration.fromJson(e as Map<String, dynamic>)),
      ) ??
      const {},
);

Map<String, dynamic> _$FormConfigToJson(
  FormConfig instance,
) => <String, dynamic>{
  'commonFields': instance.commonFields.map((k, e) => MapEntry(k, e.toJson())),
  'fieldVariations': instance.fieldVariations.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
  'formTypes': instance.formTypes.map((e) => e.toJson()).toList(),
  'formConfigs': instance.formConfigs.map((k, e) => MapEntry(k, e.toJson())),
  'ocrConfigurations': instance.ocrConfigurations.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
};
