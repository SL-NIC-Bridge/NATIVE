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

  factory FormConfigEntry.fromJson(Map<String, dynamic> json) => _$FormConfigEntryFromJson(json);
  Map<String, dynamic> toJson() => _$FormConfigEntryToJson(this);
}
