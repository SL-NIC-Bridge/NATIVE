// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ocr_config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OCRConfiguration _$OCRConfigurationFromJson(Map<String, dynamic> json) =>
    OCRConfiguration(
      enabled: json['enabled'] as bool,
      title: json['title'] as String,
      description: json['description'] as String,
      documentTypes: (json['documentTypes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      extractionRules: (json['extractionRules'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, ExtractionRule.fromJson(e as Map<String, dynamic>)),
      ),
      imageProcessing: ImageProcessingConfig.fromJson(
        json['imageProcessing'] as Map<String, dynamic>,
      ),
      userGuidance: UserGuidanceConfig.fromJson(
        json['userGuidance'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$OCRConfigurationToJson(OCRConfiguration instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'title': instance.title,
      'description': instance.description,
      'documentTypes': instance.documentTypes,
      'extractionRules': instance.extractionRules.map(
        (k, e) => MapEntry(k, e.toJson()),
      ),
      'imageProcessing': instance.imageProcessing.toJson(),
      'userGuidance': instance.userGuidance.toJson(),
    };

ExtractionRule _$ExtractionRuleFromJson(Map<String, dynamic> json) =>
    ExtractionRule(
      patterns: (json['patterns'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      priority: (json['priority'] as num).toInt(),
      fieldMapping: json['fieldMapping'] as String,
      validation: json['validation'] as String,
      processingHints: (json['processingHints'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ExtractionRuleToJson(ExtractionRule instance) =>
    <String, dynamic>{
      'patterns': instance.patterns,
      'priority': instance.priority,
      'fieldMapping': instance.fieldMapping,
      'validation': instance.validation,
      'processingHints': instance.processingHints,
    };

ImageProcessingConfig _$ImageProcessingConfigFromJson(
  Map<String, dynamic> json,
) => ImageProcessingConfig(
  maxSize: (json['maxSize'] as num).toInt(),
  quality: (json['quality'] as num).toInt(),
  allowedFormats: (json['allowedFormats'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  preprocessingSteps: (json['preprocessingSteps'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ImageProcessingConfigToJson(
  ImageProcessingConfig instance,
) => <String, dynamic>{
  'maxSize': instance.maxSize,
  'quality': instance.quality,
  'allowedFormats': instance.allowedFormats,
  'preprocessingSteps': instance.preprocessingSteps,
};

UserGuidanceConfig _$UserGuidanceConfigFromJson(Map<String, dynamic> json) =>
    UserGuidanceConfig(
      captureInstructions: (json['captureInstructions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      troubleshooting: Map<String, String>.from(json['troubleshooting'] as Map),
    );

Map<String, dynamic> _$UserGuidanceConfigToJson(UserGuidanceConfig instance) =>
    <String, dynamic>{
      'captureInstructions': instance.captureInstructions,
      'troubleshooting': instance.troubleshooting,
    };

OCRFieldMapping _$OCRFieldMappingFromJson(Map<String, dynamic> json) =>
    OCRFieldMapping(
      sourceField: json['sourceField'] as String,
      targetField: json['targetField'] as String,
      transformation: json['transformation'] as String?,
      transformationParams:
          json['transformationParams'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$OCRFieldMappingToJson(OCRFieldMapping instance) =>
    <String, dynamic>{
      'sourceField': instance.sourceField,
      'targetField': instance.targetField,
      'transformation': ?instance.transformation,
      'transformationParams': ?instance.transformationParams,
    };
