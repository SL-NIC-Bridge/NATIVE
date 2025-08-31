import 'dart:developer' as developer;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class OCRService {
  static final TextRecognizer _textRecognizer = TextRecognizer();
  
  /// Extract text from image using ML Kit
  static Future<String> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      developer.log('OCR extracted text: ${recognizedText.text}', name: 'OCRService');
      return recognizedText.text;
    } catch (e) {
      developer.log('Error extracting text: $e', name: 'OCRService');
      rethrow;
    }
  }
  
  /// Pick image from camera or gallery and extract text
  static Future<Map<String, dynamic>?> captureAndExtractText({
    required ImageSource source,
  }) async {
    try {
      // Check permissions
      if (source == ImageSource.camera) {
        final permission = await Permission.camera.request();
        if (!permission.isGranted) {
          throw Exception('Camera permission denied');
        }
      }
      
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80, // Optimize for OCR
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (image == null) return null;
      
      final extractedText = await extractTextFromImage(image.path);
      
      return {
        'imagePath': image.path,
        'extractedText': extractedText,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      developer.log('Error in captureAndExtractText: $e', name: 'OCRService');
      rethrow;
    }
  }
  
  /// Parse extracted text to form data based on Sri Lankan NIC document patterns
  static Map<String, dynamic> parseNICDocumentText(String extractedText) {
    final Map<String, dynamic> parsedData = {};
    
    try {
      // Clean and normalize text
      final cleanText = extractedText.replaceAll('\n', ' ').trim();
      final lines = extractedText.split('\n').map((line) => line.trim()).toList();
      
      // Define regex patterns for Sri Lankan document formats
      final patterns = {
        // NIC number patterns (old: 123456789V, new: 123456789012)
        'nicNumber': RegExp(r'\b\d{9}[VvXx]\b|\b\d{12}\b'),
        
        // Birth certificate number
        'birthCertificateNo': RegExp(r'(?:birth.*?certificate.*?no|bc.*?no)[:\s]*([A-Z0-9]+)', caseSensitive: false),
        
        // Date patterns (DD/MM/YYYY, DD-MM-YYYY, etc.)
        'dateOfBirth': RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{4}\b'),
        
        // Name patterns (look for uppercase sequences)
        'name': RegExp(r'\b[A-Z]{2,}(?:\s+[A-Z]{2,})*\b'),
        
        // Address patterns
        'address': RegExp(r'(?:address|addr)[:\s]*(.+?)(?:\n|$)', caseSensitive: false),
        
        // Postal code (5 digits)
        'postalCode': RegExp(r'\b\d{5}\b'),
        
        // Gender
        'sex': RegExp(r'\b(male|female|m|f)\b', caseSensitive: false),
      };
      
      // Extract NIC number
      final nicMatch = patterns['nicNumber']!.firstMatch(cleanText);
      if (nicMatch != null) {
        parsedData['existingNicNumber'] = nicMatch.group(0)?.toUpperCase();
      }
      
      // Extract birth certificate number
      final bcMatch = patterns['birthCertificateNo']!.firstMatch(cleanText);
      if (bcMatch != null) {
        parsedData['birthCertificateNo'] = bcMatch.group(1)?.toUpperCase();
      }
      
      // Extract date of birth
      final dobMatch = patterns['dateOfBirth']!.firstMatch(cleanText);
      if (dobMatch != null) {
        parsedData['dateOfBirth'] = _parseDate(dobMatch.group(0)!);
      }
      
      // Extract names (look for sequences of uppercase words)
      final nameMatches = patterns['name']!.allMatches(cleanText).toList();
      if (nameMatches.isNotEmpty) {
        final names = nameMatches.map((m) => m.group(0)!).toList();
        
        // Heuristic: longest name sequence is likely the full name
        names.sort((a, b) => b.length.compareTo(a.length));
        final fullName = names.first.split(' ');
        
        if (fullName.isNotEmpty) {
          parsedData['familyName'] = fullName.first;
          if (fullName.length > 1) {
            parsedData['name'] = fullName.sublist(1, fullName.length - 1).join(' ');
          }
          if (fullName.length > 2) {
            parsedData['surname'] = fullName.last;
          }
        }
      }
      
      // Extract postal code
      final postalMatch = patterns['postalCode']!.firstMatch(cleanText);
      if (postalMatch != null) {
        parsedData['postalCode'] = postalMatch.group(0);
      }
      
      // Extract gender
      final genderMatch = patterns['sex']!.firstMatch(cleanText);
      if (genderMatch != null) {
        final gender = genderMatch.group(0)!.toLowerCase();
        parsedData['sex'] = (gender.startsWith('m')) ? 'male' : 'female';
      }
      
      // Try to extract address from lines
      _extractAddressComponents(lines, parsedData);
      
      developer.log('Parsed OCR data: $parsedData', name: 'OCRService');
      
    } catch (e) {
      developer.log('Error parsing OCR text: $e', name: 'OCRService');
    }
    
    return parsedData;
  }
  
  /// Helper method to parse dates
  static String? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split(RegExp(r'[/-]'));
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        
        // Return in ISO format for form compatibility
        return '$year-$month-$day';
      }
    } catch (e) {
      developer.log('Error parsing date: $e', name: 'OCRService');
    }
    return null;
  }
  
  /// Helper method to extract address components
  static void _extractAddressComponents(List<String> lines, Map<String, dynamic> parsedData) {
    // Look for address-like patterns in lines
    for (final line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.isEmpty) continue;
      
      // House number pattern (numbers + optional letters at start of line)
      if (RegExp(r'^\d+[A-Z]?\s').hasMatch(cleanLine)) {
        final parts = cleanLine.split(' ');
        parsedData['houseNumber'] = parts.first;
        if (parts.length > 1) {
          parsedData['street'] = parts.sublist(1).join(' ');
        }
        continue;
      }
      
      // Look for city/village patterns (often end with common suffixes)
      if (RegExp(r'\b(town|city|village|grama|watta)\b', caseSensitive: false).hasMatch(cleanLine)) {
        parsedData['city'] = cleanLine;
        continue;
      }
    }
  }
  
  /// Dispose resources
  static Future<void> dispose() async {
    await _textRecognizer.close();
  }
}
