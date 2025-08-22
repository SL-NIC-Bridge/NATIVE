import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio(BaseOptions(
    baseUrl: 'YOUR_API_BASE_URL',  // Replace with your actual API base URL
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<List<Map<String, dynamic>>> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
      );

      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [response.data as Map<String, dynamic>];
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
