// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingsModel _$SettingsModelFromJson(Map<String, dynamic> json) =>
    SettingsModel(
      useBiometrics: json['useBiometrics'] as bool? ?? false,
      locale: json['locale'] as String? ?? 'en',
      darkMode: json['darkMode'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    );

Map<String, dynamic> _$SettingsModelToJson(SettingsModel instance) =>
    <String, dynamic>{
      'useBiometrics': instance.useBiometrics,
      'locale': instance.locale,
      'darkMode': instance.darkMode,
      'notificationsEnabled': instance.notificationsEnabled,
    };
