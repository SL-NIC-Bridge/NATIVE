import 'dart:developer' as developer;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/ocr_config_model.dart';

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
  
  
  /// Parse extracted text to form data based on configured extraction rules
  static Map<String, dynamic> parseDocumentTextWithConfig(
    String extractedText, 
    OCRConfiguration? config
  ) {
    if (config == null) {
      // Fallback to the hardcoded parsing if no config is available
      return parseNICDocumentText(extractedText);
    }

    final Map<String, dynamic> parsedData = {};
    
    try {
      // Clean and normalize text
      final cleanText = extractedText.replaceAll('\n', ' ').trim();
      final lines = extractedText.split('\n').map((line) => line.trim()).toList();
      
      // Sort extraction rules by priority (lower number = higher priority)
      final sortedRules = config.extractionRules.entries.toList()
        ..sort((a, b) => a.value.priority.compareTo(b.value.priority));
      
      for (final ruleEntry in sortedRules) {
        final fieldName = ruleEntry.key;
        final rule = ruleEntry.value;
        
        // Try each pattern for this field
        String? extractedValue;
        for (final patternStr in rule.patterns) {
          try {
            final pattern = RegExp(patternStr, caseSensitive: false);
            final match = pattern.firstMatch(cleanText);
            
            if (match != null) {
              // Use the first capture group if available, otherwise the full match
              extractedValue = match.groupCount > 0 ? match.group(1) : match.group(0);
              if (extractedValue != null && extractedValue.trim().isNotEmpty) {
                break;
              }
            }
          } catch (e) {
            developer.log('Error processing pattern "$patternStr" for field $fieldName: $e', name: 'OCRService');
          }
        }
        
        if (extractedValue != null && extractedValue.trim().isNotEmpty) {
          // Apply processing hints
          extractedValue = _applyProcessingHints(extractedValue, rule.processingHints, fieldName);
          
          // Store the extracted value using the field mapping
          parsedData[rule.fieldMapping] = extractedValue;
          
          developer.log('Extracted $fieldName: $extractedValue', name: 'OCRService');
        }
      }
      
      // Additional processing for complex fields like addresses
      if (config.extractionRules.containsKey('address') || 
          config.extractionRules.containsKey('houseNumber') ||
          config.extractionRules.containsKey('street')) {
        _extractAddressComponentsWithConfig(lines, parsedData, config);
      }
      
      developer.log('Parsed OCR data with config: $parsedData', name: 'OCRService');
      
    } catch (e) {
      developer.log('Error parsing OCR text with config: $e', name: 'OCRService');
    }
    
    return parsedData;
  }

  /// Apply processing hints to extracted values
  static String _applyProcessingHints(String value, List<String> hints, String fieldName) {
    String processedValue = value.trim();
    
    for (final hint in hints) {
      switch (hint) {
        case 'uppercase_transformation':
          processedValue = processedValue.toUpperCase();
          break;
        case 'title_case_transformation':
          processedValue = _toTitleCase(processedValue);
          break;
        case 'remove_spaces':
          processedValue = processedValue.replaceAll(' ', '');
          break;
        case 'normalize_gender':
          if (fieldName == 'sex') {
            final normalized = processedValue.toLowerCase();
            processedValue = (normalized.startsWith('m')) ? 'male' : 'female';
          }
          break;
        case 'convert_to_iso_format':
          if (fieldName.contains('date') || fieldName.contains('birth')) {
            final parsedDate = _parseDate(processedValue);
            if (parsedDate != null) {
              processedValue = parsedDate;
            }
          }
          break;
        case 'validate_nic_checksum':
          // Could add NIC validation here
          break;
        case 'first_uppercase_sequence':
        case 'middle_name_parts':
        case 'last_uppercase_sequence':
        case 'longest_name_part':
          // These are handled during name extraction
          break;
      }
    }
    
    return processedValue;
  }

  /// Convert string to title case
  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Extract address components using configuration rules
  static void _extractAddressComponentsWithConfig(
    List<String> lines, 
    Map<String, dynamic> parsedData, 
    OCRConfiguration config
  ) {
    // If specific address extraction wasn't already done by patterns, try heuristic approach
    for (final line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.isEmpty) continue;
      
      // House number pattern (numbers + optional letters at start of line)
      if (RegExp(r'^\d+[A-Z]?\s').hasMatch(cleanLine) && !parsedData.containsKey('houseNumber')) {
        final parts = cleanLine.split(' ');
        parsedData['houseNumber'] = parts.first;
        if (parts.length > 1 && !parsedData.containsKey('street')) {
          parsedData['street'] = parts.sublist(1).join(' ');
        }
        continue;
      }
      
      // Look for city/village patterns (often end with common suffixes)
      if (RegExp(r'\b(town|city|village|grama|watta)\b', caseSensitive: false).hasMatch(cleanLine) && 
          !parsedData.containsKey('city')) {
        parsedData['city'] = cleanLine;
        continue;
      }
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
