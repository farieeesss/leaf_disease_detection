import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/diagnosis_model.dart';

class DiagnosisStorageService {
  static const String _diagnosisKey = 'diagnosis_history';
  static const int _maxHistoryItems = 50;

  /// Save a new diagnosis to history
  static Future<void> saveDiagnosis(DiagnosisModel diagnosis) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<DiagnosisModel> history = await getHistory();

      // Add new diagnosis at the beginning
      history.insert(0, diagnosis);

      // Keep only the latest items
      if (history.length > _maxHistoryItems) {
        // Delete old image files before removing from history
        for (int i = _maxHistoryItems; i < history.length; i++) {
          await _deleteImageFile(history[i].imagePath);
        }
        history.removeRange(_maxHistoryItems, history.length);
      }

      // Convert to JSON and save
      final jsonList = history.map((d) => d.toJson()).toList();
      await prefs.setString(_diagnosisKey, json.encode(jsonList));
    } catch (e) {
      print('Error saving diagnosis: $e');
    }
  }

  /// Get all diagnosis history
  static Future<List<DiagnosisModel>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_diagnosisKey);

      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => DiagnosisModel.fromJson(json)).toList();
    } catch (e) {
      print('Error loading history: $e');
      return [];
    }
  }

  /// Delete a diagnosis from history
  static Future<void> deleteDiagnosis(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<DiagnosisModel> history = await getHistory();

      // Find and remove the diagnosis
      final index = history.indexWhere((d) => d.id == id);
      if (index != -1) {
        await _deleteImageFile(history[index].imagePath);
        history.removeAt(index);

        // Save updated history
        final jsonList = history.map((d) => d.toJson()).toList();
        await prefs.setString(_diagnosisKey, json.encode(jsonList));
      }
    } catch (e) {
      print('Error deleting diagnosis: $e');
    }
  }

  /// Clear all history
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<DiagnosisModel> history = await getHistory();

      // Delete all image files
      for (final diagnosis in history) {
        await _deleteImageFile(diagnosis.imagePath);
      }

      await prefs.remove(_diagnosisKey);
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  /// Save image file to app directory
  static Future<String> saveImageFile(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName =
          'diagnosis_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '${directory.path}/$fileName';

      final File newFile = await imageFile.copy(filePath);
      return newFile.path;
    } catch (e) {
      print('Error saving image file: $e');
      return imageFile.path;
    }
  }

  /// Delete image file
  static Future<void> _deleteImageFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting image file: $e');
    }
  }

  /// Get total number of diagnoses
  static Future<int> getHistoryCount() async {
    final history = await getHistory();
    return history.length;
  }

  /// Get statistics
  static Future<Map<String, int>> getStatistics() async {
    final history = await getHistory();
    final Map<String, int> stats = {};

    for (final diagnosis in history) {
      final disease = diagnosis.diseaseName;
      stats[disease] = (stats[disease] ?? 0) + 1;
    }

    return stats;
  }
}
