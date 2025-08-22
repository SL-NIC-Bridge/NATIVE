import 'package:json_annotation/json_annotation.dart';
import 'field_type.dart';
import 'field_dependency.dart';
import 'form_config_entry.dart';

part 'form_config_model.g.dart';

@JsonSerializable()
class ValidationRule {
  final String type;
  final dynamic value;
  final String message;

  ValidationRule({
    required this.type,
    required this.value,
    required this.message,
  });

  factory ValidationRule.fromJson(Map<String, dynamic> json) {
    return ValidationRule(
      type: json['type'] as String,
      value: json['value'],
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
      'message': message,
    };
  }
}

@JsonSerializable()
class FormField {
  final String fieldId;
  @JsonKey(fromJson: FormField._fieldTypeFromJson, toJson: FormField._fieldTypeToJson)
  final FieldType type;
  final String label;
  final List<FieldDependencyCondition>? dependencies;
  final Map<String, dynamic>? dataSource;

  static FieldType _fieldTypeFromJson(String value) {
    return FieldType.values.firstWhere(
      (type) => type.name == value.toLowerCase(),
      orElse: () => FieldType.text,
    );
  }

  static String _fieldTypeToJson(FieldType type) => type.name;
  final String placeholder;
  final bool required;
  final Map<String, dynamic> properties;
  final List<ValidationRule> validationRules;

  FormField({
    required this.fieldId,
    required this.type,
    required this.label,
    required this.placeholder,
    required this.required,
    required this.properties,
    required this.validationRules,
    this.dependencies,
    this.dataSource,
  });

  factory FormField.fromJson(Map<String, dynamic> json) => _$FormFieldFromJson(json);
  Map<String, dynamic> toJson() => _$FormFieldToJson(this);
}

@JsonSerializable()
class FormFieldVariation extends FormField {
  @JsonKey(name: 'extends')
  final String extendsField;

  FormFieldVariation({
    required String fieldId,
    required FieldType type,
    required String label,
    required String placeholder,
    required bool required,
    required Map<String, dynamic> properties,
    required List<ValidationRule> validationRules,
    required this.extendsField,
  }) : super(
          fieldId: fieldId,
          type: type,
          label: label,
          placeholder: placeholder,
          required: required,
          properties: properties,
          validationRules: validationRules,
        );

  factory FormFieldVariation.fromJson(Map<String, dynamic> json) => _$FormFieldVariationFromJson(json);
  Map<String, dynamic> toJson() => _$FormFieldVariationToJson(this);
}

@JsonSerializable()
class FormType {
  final String id;
  final String name;
  final String description;

  FormType({
    required this.id,
    required this.name,
    required this.description,
  });

  factory FormType.fromJson(Map<String, dynamic> json) => _$FormTypeFromJson(json);
  Map<String, dynamic> toJson() => _$FormTypeToJson(this);
}

@JsonSerializable()
class FormStep {
  final String id;
  final String title;
  final String description;
  final List<FormField> fields;

  FormStep({
    required this.id,
    required this.title,
    required this.description,
    required this.fields,
  });

  factory FormStep.fromJson(Map<String, dynamic> json) {
    return FormStep(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      fields: [],  // We'll resolve fields after the full config is loaded
    );
  }

  Map<String, dynamic> toJson() => _$FormStepToJson(this);
}

@JsonSerializable()
class FormConfig {
  final Map<String, FormField> commonFields;
  final Map<String, FormFieldVariation> fieldVariations;
  final List<FormType> formTypes;
  final Map<String, FormConfigEntry> formConfigs;

  FormConfig({
    required this.commonFields,
    required this.fieldVariations,
    required this.formTypes,
    required this.formConfigs,
  });

  factory FormConfig.fromJson(Map<String, dynamic> json) {
    // First, parse the common fields and variations
    final commonFields = (json['commonFields'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, FormField.fromJson(value as Map<String, dynamic>)),
    );
    
    final fieldVariations = (json['fieldVariations'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, FormFieldVariation.fromJson(value as Map<String, dynamic>)),
    );
    
    final formTypes = (json['formTypes'] as List)
        .map((typeJson) => FormType.fromJson(typeJson as Map<String, dynamic>))
        .toList();

    // Parse form configs and resolve field references
    final formConfigs = (json['formConfigs'] as Map<String, dynamic>).map((key, value) {
      final configJson = value as Map<String, dynamic>;
      final steps = (configJson['steps'] as List).map((stepJson) {
        final step = stepJson as Map<String, dynamic>;
        final fields = (step['fields'] as List).map((fieldJson) {
          if (fieldJson is Map<String, dynamic> && fieldJson.containsKey('\$ref')) {
            final ref = fieldJson['\$ref'] as String;
            // Parse the reference path
            final parts = ref.split('/');
            if (parts.length == 3 && parts[0] == '#') {
              final section = parts[1];
              final fieldKey = parts[2];
              if (section == 'commonFields' && commonFields.containsKey(fieldKey)) {
                return commonFields[fieldKey]!;
              } else if (section == 'fieldVariations' && fieldVariations.containsKey(fieldKey)) {
                return fieldVariations[fieldKey]!;
              }
            }
            throw Exception('Invalid field reference: $ref');
          } else {
            return FormField.fromJson(fieldJson as Map<String, dynamic>);
          }
        }).toList();

        return FormStep(
          id: step['id'] as String,
          title: step['title'] as String,
          description: step['description'] as String,
          fields: fields,
        );
      }).toList();

      return MapEntry(
        key,
        FormConfigEntry(
          id: configJson['id'] as String,
          title: configJson['title'] as String,
          description: configJson['description'] as String,
          steps: steps,
        ),
      );
    });

    return FormConfig(
      commonFields: commonFields,
      fieldVariations: fieldVariations,
      formTypes: formTypes,
      formConfigs: formConfigs,
    );
  }

  Map<String, dynamic> toJson() => _$FormConfigToJson(this);
}