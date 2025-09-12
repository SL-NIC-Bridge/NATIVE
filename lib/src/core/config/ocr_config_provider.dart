import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ocr_config_model.dart';

final ocrConfigProvider = FutureProvider<Map<String, OCRConfiguration>>((ref) async {
  try {
    developer.log('Loading OCR configuration...', name: 'OCRConfig');
    final configString = await rootBundle.loadString('assets/config/form_config_new.json', cache: false);
    developer.log('Configuration file loaded successfully', name: 'OCRConfig');

    final configJson = json.decode(configString) as Map<String, dynamic>;
    developer.log('Configuration JSON parsed successfully', name: 'OCRConfig');

    // Extract ocrConfigurations section
    final ocrConfigsJson = configJson['ocrConfigurations'] as Map<String, dynamic>?;
    if (ocrConfigsJson == null) {
      developer.log('No OCR configurations found in config file', name: 'OCRConfig');
      return <String, OCRConfiguration>{};
    }

    // Parse each OCR configuration
    final ocrConfigs = <String, OCRConfiguration>{};
    for (final entry in ocrConfigsJson.entries) {
      try {
        final config = OCRConfiguration.fromJson(entry.value as Map<String, dynamic>);
        ocrConfigs[entry.key] = config;
        developer.log('Loaded OCR config for: ${entry.key}', name: 'OCRConfig');
      } catch (e) {
        developer.log('Error parsing OCR config for ${entry.key}: $e', name: 'OCRConfig');
      }
    }

    developer.log('OCR configurations loaded successfully: ${ocrConfigs.keys}', name: 'OCRConfig');
    return ocrConfigs;
  } catch (e, stackTrace) {
    developer.log('Error loading OCR configuration: $e', name: 'OCRConfig', error: e, stackTrace: stackTrace);
    throw Exception('Failed to load OCR configuration: $e');
  }
});

/// Provider to get OCR configuration for a specific form type
final ocrConfigForFormProvider = Provider.family<OCRConfiguration?, String>((ref, formType) {
  final ocrConfigsAsync = ref.watch(ocrConfigProvider);
  return ocrConfigsAsync.maybeWhen(
    data: (configs) => configs[formType],
    orElse: () => null,
  );
});
