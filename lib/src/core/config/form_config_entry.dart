import 'package:json_annotation/json_annotation.dart';
import 'form_config_model.dart';

part 'form_config_entry.g.dart';

@JsonSerializable()
class FormConfigEntry {
  final String id;
  final String title;
  final String description;
  final List<FormStep> steps;

  FormConfigEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
  });

  // Using direct construction instead of generated fromJson since we handle parsing in FormConfig
  factory FormConfigEntry.fromJson(Map<String, dynamic> json) {
    return FormConfigEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      steps: (json['steps'] as List).map((step) => FormStep.fromJson(step as Map<String, dynamic>)).toList(),
    );
  }
  Map<String, dynamic> toJson() => _$FormConfigEntryToJson(this);
}
