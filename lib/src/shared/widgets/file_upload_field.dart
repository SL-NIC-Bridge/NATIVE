import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class FileUploadField extends StatefulWidget {
  final String label;
  final String? placeholder;
  final Function(Map<String, dynamic> fileData) onFileSelected;
  final Function() onFileCleared;
  final Map<String, dynamic>? initialValue;
  final Map<String, dynamic> properties;

  const FileUploadField({
    super.key,
    required this.label,
    this.placeholder,
    required this.onFileSelected,
    required this.onFileCleared,
    this.initialValue,
    required this.properties,
  });

  @override
  State<FileUploadField> createState() => _FileUploadFieldState();
}

class _FileUploadFieldState extends State<FileUploadField> {
  XFile? _selectedFile;
  bool _isImage = false;
  String? _previewUrl;
  bool _isLoading = false;

  Widget _buildPreview() {
    if (_isImage) {
      if (_previewUrl!.startsWith('http')) {
        return Image.network(
          _previewUrl!,
          fit: BoxFit.cover,
        );
      } else {
        return Image.file(
          File(_previewUrl!),
          fit: BoxFit.cover,
        );
      }
    } else {
      final extension = _selectedFile != null 
          ? path.extension(_selectedFile!.path).toLowerCase()
          : '';
          
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              extension == '.pdf' 
                  ? Icons.picture_as_pdf 
                  : Icons.insert_drive_file,
              size: 48,
              color: extension == '.pdf' 
                  ? Colors.red 
                  : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFile?.path != null 
                  ? path.basename(_selectedFile!.path)
                  : 'File selected',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeFromValue();
  }

  void _initializeFromValue() {
    if (widget.initialValue != null) {
      _previewUrl = widget.initialValue!['previewUrl'] as String?;
      _isImage = widget.initialValue!['mimeType']?.toString().startsWith('image/') ?? false;
    }
  }

  Future<void> _pickFile() async {
    setState(() => _isLoading = true);
    try {
      final allowedTypes = List<String>.from(widget.properties['allowedTypes'] ?? ['*/*']);
      final maxSize = widget.properties['maxSize'] as int? ?? 10485760; // 10MB default
      
      if (allowedTypes.any((type) => type.startsWith('image/')) && 
          !allowedTypes.any((type) => !type.startsWith('image/'))) {
        // Use image picker for images only
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          // FIX: Safely convert numbers (int or double) from config to double.
          maxWidth: (widget.properties['maxWidth'] as num?)?.toDouble(),
          maxHeight: (widget.properties['maxHeight'] as num?)?.toDouble(),
        );

        if (image != null) {
          // Check file size
          final fileSize = await image.length();
          if (fileSize > maxSize) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('File size must not exceed ${maxSize ~/ 1048576}MB')),
              );
            }
            return;
          }

          final extension = path.extension(image.path).toLowerCase().replaceFirst('.', '');
          setState(() {
            _selectedFile = image;
            _isImage = true;
            _previewUrl = image.path;
          });

          widget.onFileSelected({
            'path': image.path,
            'name': path.basename(image.path),
            'mimeType': 'image/$extension',
            'size': fileSize,
            'previewUrl': image.path,
          });
        }
      } else {
        // Use file picker for other files or mixed types
        final allowedExtensions = allowedTypes.expand((type) {
          if (type == '*/*') return <String>[];
          if (type.startsWith('image/')) {
            final ext = type.substring(6);
            if (ext == 'jpeg') return ['jpg', 'jpeg'];
            return [ext];
          }
          if (type.startsWith('application/')) {
            final ext = type.substring(12);
            if (ext == 'pdf') return ['pdf'];
            return [ext];
          }
          return [type.split('/').last];
        }).toList();

        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: allowedExtensions.isEmpty ? FileType.any : FileType.custom,
          allowedExtensions: allowedExtensions.isEmpty ? null : allowedExtensions,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          final filePath = file.path;
          
          if (filePath == null) {
            throw Exception('File path is null');
          }

          // Check file size
          if (file.size > maxSize) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('File size must not exceed ${maxSize ~/ 1048576}MB')),
              );
            }
            return;
          }

          final extension = path.extension(filePath).toLowerCase().replaceFirst('.', '');
          final isImageFile = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp']
              .contains(extension);

          setState(() {
            _selectedFile = XFile(filePath);
            _isImage = isImageFile;
            _previewUrl = isImageFile ? filePath : null;
          });

          String mimeType;
          if (isImageFile) {
            mimeType = 'image/$extension';
          } else if (extension == 'pdf') {
            mimeType = 'application/pdf';
          } else {
            mimeType = 'application/octet-stream';
          }

          widget.onFileSelected({
            'path': filePath,
            'name': file.name,
            'mimeType': mimeType,
            'size': file.size,
            'previewUrl': isImageFile ? filePath : null,
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearFile() {
    setState(() {
      _selectedFile = null;
      _isImage = false;
      _previewUrl = null;
    });
    widget.onFileCleared();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedFile != null || _previewUrl != null)
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildPreview(),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _clearFile,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.close, size: 16),
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : InkWell(
                    onTap: _pickFile,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.upload_file, size: 40, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          widget.placeholder ?? 'Click to upload file',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
          ),
      ],
    );
  }
}
