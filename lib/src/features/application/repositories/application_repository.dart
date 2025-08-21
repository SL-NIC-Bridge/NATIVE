import '../models/application_model.dart';
import '../../../core/networking/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

final applicationRepositoryProvider = FutureProvider<ApplicationRepository>((ref) async {
  final dio = await ref.watch(apiClientProvider.future);
  return ApplicationRepository(dio);
});

class ApplicationRepository {
  final Dio _dio;
  static const _baseUrl = '/applications';

  ApplicationRepository(this._dio);

  Future<Application?> getCurrentApplication() async {
    try {
      final response = await _dio.get('$_baseUrl/current');
      if (response.statusCode == 404) {
        return null;
      }
      return Application.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<List<Application>> getApplicationHistory() async {
    final response = await _dio.get('$_baseUrl/history');
    final List<dynamic> data = response.data;
    return data.map((json) => Application.fromJson(json)).toList();
  }

  Future<Application> submitApplication({
    required String? previousNicNumber,
    required String permanentAddress,
    required DateTime dateOfBirth,
    required String placeOfBirth,
  }) async {
    final response = await _dio.post(_baseUrl, data: {
      'previousNicNumber': previousNicNumber,
      'permanentAddress': permanentAddress,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'placeOfBirth': placeOfBirth,
    });
    return Application.fromJson(response.data);
  }

  Future<void> cancelApplication(String id) async {
    await _dio.delete('$_baseUrl/$id');
  }
}
