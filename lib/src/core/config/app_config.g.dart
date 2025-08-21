// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppConfig _$AppConfigFromJson(Map<String, dynamic> json) => AppConfig(
  apiBaseUrl: json['apiBaseUrl'] as String,
  jwtStorageKey: json['jwtStorageKey'] as String,
  theme: ThemeConfig.fromJson(json['theme'] as Map<String, dynamic>),
  appVersion: json['appVersion'] as String,
  supportEmail: json['supportEmail'] as String,
  privacyPolicyUrl: json['privacyPolicyUrl'] as String,
  termsOfServiceUrl: json['termsOfServiceUrl'] as String,
);

Map<String, dynamic> _$AppConfigToJson(AppConfig instance) => <String, dynamic>{
  'apiBaseUrl': instance.apiBaseUrl,
  'jwtStorageKey': instance.jwtStorageKey,
  'theme': instance.theme.toJson(),
  'appVersion': instance.appVersion,
  'supportEmail': instance.supportEmail,
  'privacyPolicyUrl': instance.privacyPolicyUrl,
  'termsOfServiceUrl': instance.termsOfServiceUrl,
};

ThemeConfig _$ThemeConfigFromJson(Map<String, dynamic> json) => ThemeConfig(
  seedColorLight: json['seedColorLight'] as String,
  seedColorDark: json['seedColorDark'] as String,
);

Map<String, dynamic> _$ThemeConfigToJson(ThemeConfig instance) =>
    <String, dynamic>{
      'seedColorLight': instance.seedColorLight,
      'seedColorDark': instance.seedColorDark,
    };
