import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ActionButtonsWidget extends StatelessWidget {
  final bool modelLoaded;
  final bool isLoading;
  final Function(ImageSource) onImagePicked;

  const ActionButtonsWidget({
    super.key,
    required this.modelLoaded,
    required this.isLoading,
    required this.onImagePicked,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: modelLoaded && !isLoading
                ? () => onImagePicked(ImageSource.camera)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF111827),
              side: BorderSide(color: Colors.grey.shade300, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, size: 20),
                SizedBox(width: 8),
                Text('Camera'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: modelLoaded && !isLoading
                ? () => onImagePicked(ImageSource.gallery)
                : null,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined, size: 20),
                SizedBox(width: 8),
                Text('Gallery'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

