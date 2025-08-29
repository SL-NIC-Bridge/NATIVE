import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'form_config_model.dart';

final formConfigProvider = FutureProvider<FormConfig>((ref) async {
  try {
    developer.log('Loading form configuration...', name: 'FormConfig');
    // Use the new config file
    final configString = await rootBundle.loadString('assets/config/form_config_new.json', cache:false);
    developer.log('Configuration file loaded successfully', name: 'FormConfig');

    final configJson = json.decode(configString) as Map<String, dynamic>;
    developer.log('Configuration JSON parsed successfully', name: 'FormConfig');

    // Pre-process JSON to resolve $ref before passing to the model
    final resolvedJson = _resolveJsonReferences(configJson);
    final config = FormConfig.fromJson(resolvedJson);
    developer.log('Configuration model created successfully', name: 'FormConfig');

    return config;
  } catch (e, stackTrace) {
    developer.log('Error loading configuration: $e', name: 'FormConfig', error: e, stackTrace: stackTrace);
    throw Exception('Failed to load form configuration: $e');
  }
});

/// Resolves '$ref' pointers in the form configuration JSON.
Map<String, dynamic> _resolveJsonReferences(Map<String, dynamic> root) {
  final commonFields = root['commonFields'] as Map<String, dynamic>? ?? {};

  final formConfigs = root['formConfigs'] as Map<String, dynamic>?;
  if (formConfigs == null) return root;

  final newFormConfigs = <String, dynamic>{};

  for (var entry in formConfigs.entries) {
    final formConfig = entry.value as Map<String, dynamic>;
    final steps = formConfig['steps'] as List<dynamic>?;
    if (steps == null) {
      newFormConfigs[entry.key] = formConfig;
      continue;
    }

    final newSteps = <Map<String, dynamic>>[];
    for (var step in steps) {
      final stepMap = step as Map<String, dynamic>;
      final fields = stepMap['fields'] as List<dynamic>?;
      if (fields == null) {
        newSteps.add(stepMap);
        continue;
      }

      final newFields = <Map<String, dynamic>>[];
      for (var field in fields) {
        final fieldMap = field as Map<String, dynamic>;
        if (fieldMap.containsKey('\$ref')) {
          final refPath = fieldMap['\$ref'] as String;
          // Assuming path like #/commonFields/fieldName
          final parts = refPath.split('/');
          if (parts.length == 3 && parts[0] == '#' && parts[1] == 'commonFields') {
            final fieldName = parts[2];
            if (commonFields.containsKey(fieldName)) {
              newFields.add(commonFields[fieldName] as Map<String, dynamic>);
            }
          }
        } else {
          newFields.add(fieldMap);
        }
      }
      newSteps.add({...stepMap, 'fields': newFields});
    }
    newFormConfigs[entry.key] = {...formConfig, 'steps': newSteps};
  }

  return {
    ...root,
    'formConfigs': newFormConfigs,
  };
}
