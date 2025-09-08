import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import '../constants/api_endpoints.dart';

class FileUploadService {
  final Dio _dio;
  
  FileUploadService(this._dio);

  Future<Map<String, dynamic>> uploadFile(Map<String, dynamic> fileData) async {
    final file = File(fileData['path']);
    final filename = fileData['name'] ?? path.basename(file.path);
    final fieldKey = fileData['fieldKey'] as String?; // Get the fieldKey from the map
    final applicationId = fileData['applicationId'] as String?; // Get applicationId

    // Create FormData for Dio multipart upload
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: filename,
      ),
      'originalName': filename,
      'attachmentType': 'APPLICATION_ATTACHMENT', // Add static attachmentType
      if (fieldKey != null) 'fieldKey': fieldKey, // Add the dynamic fieldKey
      if (applicationId != null) 'applicationId': applicationId, // Add applicationId
    });

    try {
      final response = await _dio.post(
        ApiEndpoints.uploadDocument,
        data: formData,
      );
      
      return {
        'success': true,
        'data': response.data,
        'url': response.data['url'] ?? response.data['id'], // Backend should return file URL or ID
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': 'Upload failed: ${e.message}',
        'statusCode': e.response?.statusCode,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<List<Map<String, dynamic>>> uploadMultipleFiles(
    List<Map<String, dynamic>> filesData
  ) async {
    print('FileUploadService - Uploading ${filesData.length} files');
    final results = <Map<String, dynamic>>[];
    
    for (int i = 0; i < filesData.length; i++) {
      final fileData = filesData[i];
      try {
        print('FileUploadService - Uploading file ${i + 1}/${filesData.length}: ${fileData['name']}');
        final result = await uploadFile(fileData);
        results.add(result);
        
        // If upload failed, log it
        if (result['success'] != true) {
          print('FileUploadService - File ${i + 1} upload failed: ${result['error']}');
        } else {
          print('FileUploadService - File ${i + 1} upload succeeded');
        }
      } catch (e) {
        print('FileUploadService - File ${i + 1} upload exception: $e');
        results.add({
          'success': false,
          'error': e.toString(),
          'file': fileData['name'],
        });
      }
    }

    print('FileUploadService - Multiple upload completed. Successful: ${results.where((r) => r['success'] == true).length}/${results.length}');
    return results;
  }
}
