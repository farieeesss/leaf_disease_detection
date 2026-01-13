import 'dart:io';
import 'package:flutter/material.dart';

class ImageSectionWidget extends StatelessWidget {
  final File? image;

  const ImageSectionWidget({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        color: Colors.white,
      ),
      child: image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                image!,
                height: 320,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          : Container(
              height: 320,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No image selected',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Capture or select a leaf image',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                ],
              ),
            ),
    );
  }
}
