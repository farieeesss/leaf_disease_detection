import 'dart:convert';
import 'package:flutter/services.dart';

class DiseaseTreatment {
  final String name;
  final String description;
  final List<String> treatments;
  final List<String> prevention;

  DiseaseTreatment({
    required this.name,
    required this.description,
    required this.treatments,
    required this.prevention,
  });

  factory DiseaseTreatment.fromJson(Map<String, dynamic> json) {
    return DiseaseTreatment(
      name: json['name'] as String,
      description: json['description'] as String,
      treatments: List<String>.from(json['treatments'] as List),
      prevention: List<String>.from(json['prevention'] as List),
    );
  }
}

class DiseaseTreatmentService {
  static Map<String, DiseaseTreatment>? _treatments;
  static bool _isLoaded = false;

  /// Load treatments from JSON file
  static Future<void> loadTreatments() async {
    if (_isLoaded) return;

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/disease_treatments.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      _treatments = {};
      jsonData.forEach((key, value) {
        _treatments![key] = DiseaseTreatment.fromJson(value);
      });

      _isLoaded = true;
    } catch (e) {
      print('Error loading treatments: $e');
      _isLoaded = false;
    }
  }

  /// Get treatment for a specific disease
  static DiseaseTreatment? getTreatment(String diseaseName) {
    if (!_isLoaded || _treatments == null) {
      return null;
    }
    return _treatments![diseaseName];
  }

  /// Check if treatments are loaded
  static bool get isLoaded => _isLoaded;

  /// Get all available disease names
  static List<String> getAvailableDiseases() {
    if (!_isLoaded || _treatments == null) {
      return [];
    }
    return _treatments!.keys.toList();
  }
}
