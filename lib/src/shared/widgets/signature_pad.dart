import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignaturePad extends StatefulWidget {
  final String label;
  final String? placeholder;
  final Function(Uint8List) onSigned;
  final VoidCallback onClear;
  final Color backgroundColor;
  final Color penColor;
  final double strokeWidth;

  const SignaturePad({
    super.key,
    required this.label,
    this.placeholder,
    required this.onSigned,
    required this.onClear,
    this.backgroundColor = Colors.white,
    this.penColor = Colors.black,
    this.strokeWidth = 2.0,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  late SignatureController _controller;
  bool _hasSignature = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: widget.strokeWidth,
      penColor: widget.penColor,
      exportBackgroundColor: widget.backgroundColor,
    );

    _controller.addListener(() {
      if (mounted) {
        final hasSignature = _controller.isNotEmpty;
        if (hasSignature != _hasSignature) {
          setState(() => _hasSignature = hasSignature);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_controller.isNotEmpty) {
      final data = await _controller.toPngBytes();
      if (data != null) {
        widget.onSigned(data);
      }
    }
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
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Signature canvas
                Signature(
                  controller: _controller,
                  backgroundColor: widget.backgroundColor,
                ),
                
                // Placeholder text when empty
                if (!_hasSignature && widget.placeholder != null)
                  Center(
                    child: Text(
                      widget.placeholder!,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: _controller.isNotEmpty ? () {
                _controller.clear();
                widget.onClear();
              } : null,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _controller.isNotEmpty ? _handleSave : null,
              icon: const Icon(Icons.check),
              label: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}
