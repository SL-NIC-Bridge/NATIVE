import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/application_model.dart';
import '../repositories/application_repository.dart';

// Applications provider using real repository
final applicationsProvider = FutureProvider<List<Application>>((ref) async {
  final repository = await ref.watch(applicationRepositoryProvider.future);
  return repository.getApplicationHistory();
});

final applicationStatusProvider = FutureProvider<Application?>((ref) async {
  final repository = await ref.watch(applicationRepositoryProvider.future);
  return repository.getCurrentApplication();
});

final applicationHistoryProvider = FutureProvider<List<Application>>((ref) async {
  final repository = await ref.watch(applicationRepositoryProvider.future);
  return repository.getApplicationHistory();
});