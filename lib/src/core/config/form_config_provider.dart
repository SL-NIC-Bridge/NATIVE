import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'form_config_model.dart';

final formConfigProvider = FutureProvider<FormConfig>((ref) async {
  try {
    developer.log('Loading form configuration...', name: 'FormConfig');
    final configString = await rootBundle.loadString('assets/config/form_config_new.json');
    developer.log('Configuration file loaded successfully', name: 'FormConfig');

    final configJson = json.decode(configString) as Map<String, dynamic>;
    developer.log('Configuration JSON parsed successfully', name: 'FormConfig');

    final config = FormConfig.fromJson(configJson);
    developer.log('Configuration model created successfully', name: 'FormConfig');

    return config;
  } catch (e, stackTrace) {
    developer.log('Error loading configuration: $e', name: 'FormConfig', error: e, stackTrace: stackTrace);
    throw Exception('Failed to load form configuration: $e');
  }
});