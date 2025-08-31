import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/ocr_service.dart';

class OCRQuickScanButton extends StatefulWidget {
  final Function(Map<String, dynamic> extractedData) onDataExtracted;
  final String? label;
  final IconData? icon;
  final bool isCompact;

  const OCRQuickScanButton({
    super.key,
    required this.onDataExtracted,
    this.label,
    this.icon,
    this.isCompact = false,
  });

  @override
  State<OCRQuickScanButton> createState() => _OCRQuickScanButtonState();
}

class _OCRQuickScanButtonState extends State<OCRQuickScanButton> {
  bool _isScanning = false;

  Future<void> _showScanOptions() async {
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan Document',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera to capture document'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select existing photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (result != null) {
      await _scanDocument(result);
    }
  }

  Future<void> _scanDocument(ImageSource source) async {
    setState(() => _isScanning = true);

    try {
      final result = await OCRService.captureAndExtractText(source: source);
      
      if (result == null) {
        setState(() => _isScanning = false);
        return;
      }

      final extractedText = result['extractedText'] as String;
      final parsedData = OCRService.parseNICDocumentText(extractedText);
      
      if (parsedData.isNotEmpty) {
        widget.onDataExtracted(parsedData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully extracted ${parsedData.length} field(s)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No recognizable data found in document'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return IconButton(
        onPressed: _isScanning ? null : _showScanOptions,
        icon: _isScanning 
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : Icon(widget.icon ?? Icons.document_scanner),
        tooltip: 'Scan document',
      );
    }

    return ElevatedButton.icon(
      onPressed: _isScanning ? null : _showScanOptions,
      icon: _isScanning 
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : Icon(widget.icon ?? Icons.document_scanner),
      label: Text(widget.label ?? 'Scan Document'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
      ),
    );
  }
}
