import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/application_model.dart';
import '../repositories/application_repository.dart';
import '../repositories/mock_application_repository.dart';
import '../../../core/config/app_service_config.dart';

// Repository provider that switches between mock and real repository
final currentApplicationRepositoryProvider = Provider<FutureOr<dynamic>>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockServices) {
    return ref.watch(mockApplicationRepositoryProvider);
  } else {
    return ref.watch(applicationRepositoryProvider.future);
  }
});

final applicationStatusProvider = FutureProvider<Application?>((ref) async {
  final repository = await ref.watch(currentApplicationRepositoryProvider);
  return repository.getCurrentApplication();
});

final applicationHistoryProvider = FutureProvider<List<Application>>((ref) async {
  final repository = await ref.watch(currentApplicationRepositoryProvider);
  return repository.getApplicationHistory();
});