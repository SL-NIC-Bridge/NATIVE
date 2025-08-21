// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_config_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FormConfigEntry _$FormConfigEntryFromJson(Map<String, dynamic> json) =>
    FormConfigEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      steps: (json['steps'] as List<dynamic>)
          .map((e) => FormStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FormConfigEntryToJson(FormConfigEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'steps': instance.steps.map((e) => e.toJson()).toList(),
    };
