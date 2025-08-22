import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class FieldDataNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final ApiService _apiService;

  FieldDataNotifier(this._apiService) : super(const AsyncValue.loading());

  Future<void> loadData(String endpoint, {Map<String, dynamic>? params}) async {
    try {
      state = const AsyncValue.loading();
      final data = await _apiService.get(endpoint, queryParams: params);
      state = AsyncValue.data(List<Map<String, dynamic>>.from(data));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final fieldDataProvider = StateNotifierProvider.family<FieldDataNotifier, AsyncValue<List<Map<String, dynamic>>>, String>(
  (ref, fieldId) => FieldDataNotifier(ref.watch(apiServiceProvider)),
);
