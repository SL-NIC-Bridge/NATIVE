import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_config.dart';

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  try {
    developer.log('Loading app configuration...', name: 'AppConfig');
    final configString = await rootBundle.loadString('assets/config/app_config.json');
    developer.log('Configuration file loaded successfully', name: 'AppConfig');
    
    final configJson = json.decode(configString) as Map<String, dynamic>;
    developer.log('Configuration JSON parsed successfully', name: 'AppConfig');
    
    final config = AppConfig.fromJson(configJson);
    developer.log('Configuration model created successfully', name: 'AppConfig');
    
    return config;
  } catch (e, stackTrace) {
    developer.log('Error loading configuration: $e', name: 'AppConfig', error: e, stackTrace: stackTrace);
    throw Exception('Failed to load app configuration: $e');
  }
});