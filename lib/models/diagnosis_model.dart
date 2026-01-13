class DiagnosisModel {
  final String id;
  final String diseaseName;
  final double confidence;
  final String imagePath;
  final DateTime timestamp;
  final List<Map<String, dynamic>> allPredictions;

  DiagnosisModel({
    required this.id,
    required this.diseaseName,
    required this.confidence,
    required this.imagePath,
    required this.timestamp,
    required this.allPredictions,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'diseaseName': diseaseName,
      'confidence': confidence,
      'imagePath': imagePath,
      'timestamp': timestamp.toIso8601String(),
      'allPredictions': allPredictions,
    };
  }

  // Create from JSON
  factory DiagnosisModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisModel(
      id: json['id'] as String,
      diseaseName: json['diseaseName'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      imagePath: json['imagePath'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      allPredictions: List<Map<String, dynamic>>.from(
        json['allPredictions'] as List,
      ),
    );
  }

  // Check if plant is healthy
  bool get isHealthy => 
      diseaseName.toLowerCase() == 'healthy' ||
      diseaseName.toLowerCase() == 'tomato_leaf_healthy';

  // Get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
