import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import './custom_button.dart';

class SignaturePad extends StatefulWidget {
  final Uint8List? initialValue;
  final Function(Uint8List? data) onChanged;
  final String? errorText;

  const SignaturePad({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.transparent,
      // TODO: If you store signature points, you can load them here.
      // points: _controller.fromPoints(widget.initialValue),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearSignature() {
    _controller.clear();
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // THE FIX:
        // The Signature widget must have a bounded height when inside a vertically
        // scrolling view. We wrap it in an AspectRatio to give it a fixed shape.
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border.all(
                color: widget.errorText != null
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.outline,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Signature(
              controller: _controller,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              widget.errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CustomButton(
              onPressed: _clearSignature,
              text: 'Clear',
              type: ButtonType.text,
            ),
          ],
        ),
      ],
    );
  }
}

