import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class FileUploadService {
  final String baseUrl;
  
  FileUploadService({required this.baseUrl});

  Future<Map<String, dynamic>> uploadFile(Map<String, dynamic> fileData) async {
    final file = File(fileData['path']);
    final filename = fileData['name'] ?? path.basename(file.path);
    final mimeType = fileData['mimeType'] ?? 'application/octet-stream';

    // Create multipart request
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));

    // Add file
    final stream = http.ByteStream(file.openRead());
    final length = await file.length();

    final multipartFile = http.MultipartFile(
      'file',
      stream,
      length,
      filename: filename,
      contentType: MediaType.parse(mimeType),
    );

    request.files.add(multipartFile);

    // Add any additional metadata if needed
    request.fields['originalName'] = filename;
    request.fields['mimeType'] = mimeType;

    try {
      final response = await request.send();
      
      if (response.statusCode != 200) {
        throw Exception('Failed to upload file: ${response.statusCode}');
      }

      final responseData = await response.stream.bytesToString();
      return {
        'success': true,
        'data': responseData,
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
    final results = <Map<String, dynamic>>[];
    
    for (final fileData in filesData) {
      try {
        final result = await uploadFile(fileData);
        results.add(result);
      } catch (e) {
        results.add({
          'success': false,
          'error': e.toString(),
          'file': fileData['name'],
        });
      }
    }

    return results;
  }
}
