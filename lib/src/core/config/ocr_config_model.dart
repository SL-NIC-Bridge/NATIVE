import 'package:json_annotation/json_annotation.dart';

part 'ocr_config_model.g.dart';

@JsonSerializable()
class OCRConfiguration {
  final bool enabled;
  final String title;
  final String description;
  final List<String> documentTypes;
  final Map<String, ExtractionRule> extractionRules;
  final ImageProcessingConfig imageProcessing;
  final UserGuidanceConfig userGuidance;

  const OCRConfiguration({
    required this.enabled,
    required this.title,
    required this.description,
    required this.documentTypes,
    required this.extractionRules,
    required this.imageProcessing,
    required this.userGuidance,
  });

  factory OCRConfiguration.fromJson(Map<String, dynamic> json) =>
      _$OCRConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$OCRConfigurationToJson(this);
}

@JsonSerializable()
class ExtractionRule {
  final List<String> patterns;
  final int priority;
  final String fieldMapping;
  final String validation;
  final List<String> processingHints;

  const ExtractionRule({
    required this.patterns,
    required this.priority,
    required this.fieldMapping,
    required this.validation,
    required this.processingHints,
  });

  factory ExtractionRule.fromJson(Map<String, dynamic> json) =>
      _$ExtractionRuleFromJson(json);

  Map<String, dynamic> toJson() => _$ExtractionRuleToJson(this);
}

@JsonSerializable()
class ImageProcessingConfig {
  final int maxSize;
  final int quality;
  final List<String> allowedFormats;
  final List<String> preprocessingSteps;

  const ImageProcessingConfig({
    required this.maxSize,
    required this.quality,
    required this.allowedFormats,
    required this.preprocessingSteps,
  });

  factory ImageProcessingConfig.fromJson(Map<String, dynamic> json) =>
      _$ImageProcessingConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ImageProcessingConfigToJson(this);
}

@JsonSerializable()
class UserGuidanceConfig {
  final List<String> captureInstructions;
  final Map<String, String> troubleshooting;

  const UserGuidanceConfig({
    required this.captureInstructions,
    required this.troubleshooting,
  });

  factory UserGuidanceConfig.fromJson(Map<String, dynamic> json) =>
      _$UserGuidanceConfigFromJson(json);

  Map<String, dynamic> toJson() => _$UserGuidanceConfigToJson(this);
}

@JsonSerializable()
class OCRFieldMapping {
  final String sourceField;
  final String targetField;
  final String? transformation;
  final Map<String, dynamic>? transformationParams;

  const OCRFieldMapping({
    required this.sourceField,
    required this.targetField,
    this.transformation,
    this.transformationParams,
  });

  factory OCRFieldMapping.fromJson(Map<String, dynamic> json) =>
      _$OCRFieldMappingFromJson(json);

  Map<String, dynamic> toJson() => _$OCRFieldMappingToJson(this);
}
