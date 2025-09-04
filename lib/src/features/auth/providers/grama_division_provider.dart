import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/grama_division_model.dart';
import '../repositories/grama_division_repository.dart';

final gramaDivisionProvider = FutureProvider<List<GramaDivision>>((ref) async {
  final repository = ref.watch(gramaDivisionRepositoryProvider);
  return repository.getGramaDivisions();
});
