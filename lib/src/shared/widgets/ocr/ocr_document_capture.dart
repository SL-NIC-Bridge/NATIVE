import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/config/ocr_config_model.dart';
import '../custom_button.dart';

class OCRDocumentCapture extends StatefulWidget {
  final String title;
  final String description;
  final Function(Map<String, dynamic> extractedData) onDataExtracted;
  final VoidCallback? onSkip;
  final bool isOptional;
  final OCRConfiguration? ocrConfig;

  const OCRDocumentCapture({
    super.key,
    required this.title,
    required this.description,
    required this.onDataExtracted,
    this.onSkip,
    this.isOptional = false,
    this.ocrConfig,
  });

  @override
  State<OCRDocumentCapture> createState() => _OCRDocumentCaptureState();
}

class _OCRDocumentCaptureState extends State<OCRDocumentCapture> {
  bool _isProcessing = false;
  Map<String, dynamic>? _parsedData;

  Future<void> _captureDocument(ImageSource source) async {
    setState(() {
      _isProcessing = true;
      _parsedData = null;
    });

    try {
      final result = await OCRService.captureAndExtractText(source: source);
      
      if (result == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final extractedText = result['extractedText'] as String;
      
      // Use configuration-based parsing if available, otherwise fallback to hardcoded
      final parsedData = OCRService.parseDocumentTextWithConfig(extractedText, widget.ocrConfig);
      
      setState(() {
        _parsedData = parsedData;
        _isProcessing = false;
      });

    } catch (e) {
      setState(() => _isProcessing = false);
      
      if (mounted) {
        // Try to get a more specific error message from config
        String errorMessage = 'Error processing document: $e';
        
        if (widget.ocrConfig != null) {
          final troubleshooting = widget.ocrConfig!.userGuidance.troubleshooting;
          
          // Check for specific error types and provide helpful messages
          if (e.toString().toLowerCase().contains('quality') || 
              e.toString().toLowerCase().contains('blur')) {
            errorMessage = troubleshooting['poorQuality'] ?? errorMessage;
          } else if (e.toString().toLowerCase().contains('text') || 
                     e.toString().toLowerCase().contains('empty')) {
            errorMessage = troubleshooting['noTextFound'] ?? errorMessage;
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmExtractedData() {
    if (_parsedData != null) {
      widget.onDataExtracted(_parsedData!);
    }
  }

  void _retryCapture() {
    setState(() {
      _parsedData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: widget.onSkip != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onSkip,
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.document_scanner,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Document Capture',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    
                    // Show capture instructions from config if available
                    if (widget.ocrConfig?.userGuidance.captureInstructions.isNotEmpty ?? false) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Capture Tips:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...widget.ocrConfig!.userGuidance.captureInstructions.map((instruction) =>
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  instruction,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (_isProcessing)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing document...'),
                    ],
                  ),
                ),
              )
            else if (_parsedData != null)
              Expanded(
                child: _buildExtractedDataView(),
              )
            else
              Expanded(
                child: _buildCaptureButtons(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt_outlined,
          size: 80,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
        const SizedBox(height: 24),
        
        Text(
          'Capture your document to auto-fill form fields',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        CustomButton(
          onPressed: () => _captureDocument(ImageSource.camera),
          text: 'Take Photo',
          icon: Icons.camera_alt,
        ),
        
        const SizedBox(height: 16),
        
        CustomButton(
          onPressed: () => _captureDocument(ImageSource.gallery),
          text: 'Choose from Gallery',
          icon: Icons.photo_library,
          type: ButtonType.secondary,
        ),
        
        if (widget.isOptional) ...[
          const SizedBox(height: 24),
          TextButton(
            onPressed: widget.onSkip,
            child: const Text('Skip for now'),
          ),
        ],
      ],
    );
  }

  Widget _buildExtractedDataView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Document processed successfully!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Text(
          'Extracted Information:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  ..._parsedData!.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              _formatFieldName(entry.key),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value?.toString() ?? '',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  if (_parsedData!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Text(
                            'No recognizable data found. You can retry or proceed to fill the form manually.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          // Show troubleshooting tips if available in config
                          if (widget.ocrConfig?.userGuidance.troubleshooting.isNotEmpty ?? false) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              'Troubleshooting Tips:',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...widget.ocrConfig!.userGuidance.troubleshooting.entries.map((entry) =>
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Flexible(
              child: CustomButton(
                onPressed: _retryCapture,
                text: 'Retry',
                type: ButtonType.secondary,
                icon: Icons.refresh,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: CustomButton(
                onPressed: _confirmExtractedData,
                text: 'Use This Data',
                icon: Icons.check,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatFieldName(String fieldName) {
    // Convert camelCase to readable format
    final formatted = fieldName
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim();
    return formatted.isEmpty ? fieldName : formatted[0].toUpperCase() + formatted.substring(1);
  }
}
