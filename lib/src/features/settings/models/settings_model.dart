import 'package:json_annotation/json_annotation.dart';

part 'settings_model.g.dart';

@JsonSerializable()
class SettingsModel {
  final bool useBiometrics;
  final String locale;
  final bool darkMode;
  final bool notificationsEnabled;

  SettingsModel({
    this.useBiometrics = false,
    this.locale = 'en',
    this.darkMode = false,
    this.notificationsEnabled = true,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) =>
      _$SettingsModelFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsModelToJson(this);

  SettingsModel copyWith({
    bool? useBiometrics,
    String? locale,
    bool? darkMode,
    bool? notificationsEnabled,
  }) {
    return SettingsModel(
      useBiometrics: useBiometrics ?? this.useBiometrics,
      locale: locale ?? this.locale,
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
