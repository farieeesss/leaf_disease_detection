import 'dart:convert';
import 'package:flutter/services.dart';

enum DetectionType { tomatoFruit, tomatoLeaf, otherCrop, nonCrop }

class EnhancedPredictionResult {
  final DetectionType type;
  final String className;
  final String displayName;
  final double confidence;
  final List<Map<String, dynamic>> allPredictions;
  final String? message;

  EnhancedPredictionResult({
    required this.type,
    required this.className,
    required this.displayName,
    required this.confidence,
    required this.allPredictions,
    this.message,
  });

  bool get isTomatoFruit => type == DetectionType.tomatoFruit;
  bool get isTomatoLeaf => type == DetectionType.tomatoLeaf;
  bool get isOtherCrop => type == DetectionType.otherCrop;
  bool get isNonCrop => type == DetectionType.nonCrop;
  bool get isValid => isTomatoFruit || isTomatoLeaf;

  bool get isRipe => className == 'tomato_fruit_ripe';
  bool get isUnripe => className == 'tomato_fruit_unripe';
  bool get isHealthy => className == 'tomato_leaf_healthy';
}

class EnhancedModelService {
  static Map<String, dynamic>? _classMapping;
  static bool _isLoaded = false;

  static Future<void> loadMappings() async {
    if (_isLoaded) return;

    try {
      // Load class mapping
      final mappingJson = await rootBundle.loadString(
        'assets/class_mapping_enhanced.json',
      );
      _classMapping = json.decode(mappingJson);

      _isLoaded = true;
    } catch (e) {
      print('Error loading enhanced model mappings: $e');
      rethrow;
    }
  }

  static EnhancedPredictionResult processPrediction(
    Map<String, dynamic> modelOutput,
  ) {
    if (!_isLoaded) {
      throw Exception('Mappings not loaded. Call loadMappings() first.');
    }

    final className = modelOutput['disease'] as String;
    final confidence = modelOutput['confidence'] as double;

    // Safely extract predictions list
    final predictionsList = modelOutput['predictions'] as List?;
    if (predictionsList == null) {
      throw Exception('Predictions list is null in model output');
    }

    // Convert to list of maps safely
    final predictions = predictionsList.map((item) {
      if (item is Map<String, dynamic>) {
        return item;
      } else if (item is Map) {
        return Map<String, dynamic>.from(item);
      } else {
        throw Exception('Invalid prediction item type: ${item.runtimeType}');
      }
    }).toList();

    // Determine detection type
    final categories = _classMapping!['categories'] as Map<String, dynamic>?;
    if (categories == null) {
      throw Exception('Class mapping categories not found');
    }

    final category = categories[className] as String?;
    DetectionType type;

    if (category == null) {
      print(
        '⚠️ Warning: Class name "$className" not found in mapping. Defaulting to nonCrop.',
      );
      type = DetectionType.nonCrop;
    } else {
      switch (category) {
        case 'tomato_fruit':
          type = DetectionType.tomatoFruit;
          break;
        case 'tomato_leaf':
          type = DetectionType.tomatoLeaf;
          break;
        case 'other_crop':
          type = DetectionType.otherCrop;
          break;
        case 'non_crop':
          type = DetectionType.nonCrop;
          break;
        default:
          type = DetectionType.nonCrop;
      }
    }

    // Get display name and message
    String displayName;
    String? message;

    switch (type) {
      case DetectionType.tomatoFruit:
        if (className == 'tomato_fruit_ripe') {
          displayName = 'Ripe Tomato';
          message = 'This tomato is ripe and ready for harvest!';
        } else {
          displayName = 'Unripe Tomato';
          message =
              'This tomato is still developing. Wait a bit longer for optimal ripeness.';
        }
        break;

      case DetectionType.tomatoLeaf:
        displayName = _formatLeafDiseaseName(className);
        if (className == 'tomato_leaf_healthy') {
          message = 'Your tomato plant looks healthy! Keep up the good care.';
        } else {
          message = 'Disease detected. Check treatment recommendations below.';
        }
        break;

      case DetectionType.otherCrop:
        displayName = 'Other Crop';
        message =
            'This model is specifically trained for tomato plants. Please upload a tomato leaf or fruit image.';
        break;

      case DetectionType.nonCrop:
        displayName = 'Not a Crop';
        message =
            'This doesn\'t look like a plant. Please upload an image of a tomato leaf or fruit.';
        break;
    }

    return EnhancedPredictionResult(
      type: type,
      className: className,
      displayName: displayName,
      confidence: confidence,
      allPredictions: predictions,
      message: message,
    );
  }

  static String _formatLeafDiseaseName(String className) {
    // Remove 'tomato_leaf_' prefix and format
    final name = className.replaceFirst('tomato_leaf_', '');

    if (name == 'healthy') {
      return 'Healthy Plant';
    }

    // Convert snake_case to Title Case
    return name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Format any class name to a user-friendly display name
  static String formatDiseaseName(String className) {
    // Handle tomato fruit
    if (className == 'tomato_fruit_ripe') {
      return 'Ripe Tomato';
    } else if (className == 'tomato_fruit_unripe') {
      return 'Unripe Tomato';
    }

    // Handle tomato leaf diseases
    if (className.startsWith('tomato_leaf_')) {
      return _formatLeafDiseaseName(className);
    }

    // Handle other cases
    if (className == 'other_crop') {
      return 'Other Crop';
    } else if (className == 'non_crop') {
      return 'Not a Crop';
    }

    // Fallback: format as title case
    return className
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  static String getDiseaseTreatmentKey(String className) {
    // Convert enhanced class name to original treatment key
    if (className == 'tomato_leaf_healthy') {
      return 'healthy';
    }

    final diseaseName = className.replaceFirst('tomato_leaf_', '');

    // Map to original disease names in disease_treatments.json
    final mapping = {
      'bacterial_spot': 'Bacterial Spot',
      'early_blight': 'Early Blight',
      'late_blight': 'Late Blight',
      'leaf_mold': 'Leaf Mold',
      'mosaic_virus': 'Mosaic Virus',
      'septoria_leaf_spot': 'Septoria Leaf Spot',
      'spider_mites': 'Spider Mites',
      'target_spot': 'Target Spot',
      'yellow_leaf_curl_virus': 'Yellow Leaf Curl Virus',
    };

    return mapping[diseaseName] ?? diseaseName;
  }

  static bool get isLoaded => _isLoaded;
}
