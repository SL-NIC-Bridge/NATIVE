import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../../shared/widgets/ocr/ocr_document_capture.dart';

class OCRPreFormScreen extends ConsumerStatefulWidget {
  final String formType;
  
  const OCRPreFormScreen({
    super.key,
    required this.formType,
  });

  @override
  ConsumerState<OCRPreFormScreen> createState() => _OCRPreFormScreenState();
}

class _OCRPreFormScreenState extends ConsumerState<OCRPreFormScreen> {
  
  void _handleOCRDataExtracted(Map<String, dynamic> extractedData) {
    // Navigate to the form with pre-filled data
    context.go(
      AppRoutes.dynamicFormWithType(widget.formType),
      extra: {'ocrData': extractedData},
    );
  }
  
  void _skipOCR() {
    // Navigate to the form without pre-filled data
    context.go(AppRoutes.dynamicFormWithType(widget.formType));
  }
  
  String _getDocumentTypeDescription() {
    switch (widget.formType) {
      case 'new_nic':
        return 'Take a photo of your birth certificate or identity document to automatically extract and fill basic information like your name, date of birth, and place of birth.';
      case 'replace_nic':
        return 'Take a photo of your existing NIC (if available) or birth certificate to automatically extract your personal information.';
      case 'correct_nic':
        return 'Take a photo of your current NIC and any supporting documents to extract the information that needs to be corrected.';
      default:
        return 'Take a photo of your identity document to automatically extract and fill basic information.';
    }
  }
  
  String _getDocumentTitle() {
    switch (widget.formType) {
      case 'new_nic':
        return 'Scan Birth Certificate';
      case 'replace_nic':
        return 'Scan Identity Document';
      case 'correct_nic':
        return 'Scan Current NIC';
      default:
        return 'Scan Document';
    }
  }

  @override
  Widget build(BuildContext context) {
    return OCRDocumentCapture(
      title: _getDocumentTitle(),
      description: _getDocumentTypeDescription(),
      onDataExtracted: _handleOCRDataExtracted,
      onSkip: _skipOCR,
      isOptional: true,
    );
  }
}
