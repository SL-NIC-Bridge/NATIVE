import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import './custom_button.dart';

class SignaturePad extends StatefulWidget {
  final Function(Map<String, dynamic>? data) onChanged;
  final String? errorText;
  
  const SignaturePad({
    super.key,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final SignatureController _drawController = SignatureController(
    penStrokeWidth: 3,
    penColor: const Color.fromARGB(255, 7, 49, 85),
    exportBackgroundColor: Colors.white,
  );

  // State to hold the final signature data, whether drawn or uploaded
  Uint8List? _signatureBytes;
  String _signatureSource = 'none'; // 'drawn' or 'uploaded'

  @override
  void initState() {
    super.initState();
    _drawController.onDrawEnd = _onDrawEnd;
  }

  @override
  void dispose() {
    _drawController.dispose();
    super.dispose();
  }

  // Called when user finishes drawing
  Future<void> _onDrawEnd() async {
    if (_drawController.isNotEmpty) {
      final data = await _drawController.toPngBytes();
      if (data != null && mounted) {
        setState(() {
          _signatureBytes = data;
          _signatureSource = 'drawn';
        });
        await _notifyParent();
      }
    }
  }

  // Called when user clicks "Upload"
  Future<void> _uploadSignature() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (mounted) {
          setState(() {
            _signatureBytes = bytes;
            _signatureSource = 'uploaded';
            _drawController.clear(); // Clear canvas if image is uploaded
          });
          await _notifyParent();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  // Called when user clicks "Clear"
  void _clearSignature() {
    setState(() {
      _signatureBytes = null;
      _signatureSource = 'none';
      _drawController.clear();
    });
    widget.onChanged(null);
  }

  // Central place to notify the parent form
  Future<void> _notifyParent() async {
    if (_signatureBytes == null) {
      widget.onChanged(null);
    } else {
      try {
        // Save signature to temporary file
        final tempDir = await getTemporaryDirectory();
        final fileName = 'signature_${DateTime.now().millisecondsSinceEpoch}.png';
        final filePath = '${tempDir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(_signatureBytes!);

        // Return file map like other file uploads
        widget.onChanged({
          'path': filePath,
          'name': fileName,
          'mimeType': 'image/png',
          'size': _signatureBytes!.length,
          'source': _signatureSource,
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save signature: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final theme = Theme.of(context);
    final bool hasSignature = _signatureBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(
                color: hasError ? theme.colorScheme.error : theme.colorScheme.outline,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              // Show uploaded image if it exists, otherwise show the drawing canvas
              child: _signatureSource == 'uploaded' && _signatureBytes != null
                  ? Image.memory(_signatureBytes!, fit: BoxFit.contain)
                  : Signature(
                      controller: _drawController,
                      backgroundColor: Colors.white70,
                    ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              widget.errorText!,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CustomButton(
              onPressed: _uploadSignature,
              text: 'Upload',
              type: ButtonType.text,
              // icon: Icons.upload_file,
            ),
            const SizedBox(width: 8),
            CustomButton(
              onPressed: hasSignature ? _clearSignature : null,
              text: 'Clear',
              type: ButtonType.text,
              // icon: Icons.delete_outline,
            ),
          ],
        ),
      ],
    );
  }
}
