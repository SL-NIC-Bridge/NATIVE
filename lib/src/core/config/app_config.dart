import 'package:json_annotation/json_annotation.dart';

part 'app_config.g.dart';

@JsonSerializable()
class AppConfig {
  final String apiBaseUrl;
  final String jwtStorageKey;
  final ThemeConfig theme;
  final String appVersion;
  final String supportEmail;
  final String privacyPolicyUrl;
  final String termsOfServiceUrl;

  const AppConfig({
    required this.apiBaseUrl,
    required this.jwtStorageKey,
    required this.theme,
    required this.appVersion,
    required this.supportEmail,
    required this.privacyPolicyUrl,
    required this.termsOfServiceUrl,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AppConfigToJson(this);
}

@JsonSerializable()
class ThemeConfig {
  final String seedColorLight;
  final String seedColorDark;

  const ThemeConfig({
    required this.seedColorLight,
    required this.seedColorDark,
  });

  factory ThemeConfig.fromJson(Map<String, dynamic> json) =>
      _$ThemeConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ThemeConfigToJson(this);
}