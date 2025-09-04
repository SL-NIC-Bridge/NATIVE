import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/networking/api_client.dart';
import '../models/grama_division_model.dart';
import '../../../core/constants/api_endpoints.dart';

final gramaDivisionRepositoryProvider = Provider<GramaDivisionRepository>((ref) {
  final dio = ref.watch(apiClientProvider).value;
  if (dio == null) {
    throw Exception('API client not initialized');
  }
  return GramaDivisionRepository(dio);
});

class GramaDivisionRepository {
  final Dio _dio;

  GramaDivisionRepository(this._dio);

  Future<List<GramaDivision>> getGramaDivisions() async {
    try {
      final response = await _dio.get(ApiEndpoints.divisions);
      final List<dynamic> data = response.data['data'];
      return data.map((json) => GramaDivision.fromJson(json)).toList();
    } on DioException catch (e) {
      // Handle Dio-specific errors
      throw Exception('Failed to fetch Grama Divisions: ${e.message}');
    } catch (e) {
      // Handle other errors
      throw Exception('An unknown error occurred: $e');
    }
  }
}
