import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'tflite_model.dart';
import 'services/disease_treatment_service.dart';
import 'services/diagnosis_storage_service.dart';
import 'services/enhanced_model_service.dart';
import 'models/diagnosis_model.dart';
import 'widgets/tomato_shower_animation.dart';
import 'widgets/app_bar_widget.dart';
import 'widgets/hero_section_widget.dart';
import 'widgets/image_section_widget.dart';
import 'widgets/action_buttons_widget.dart';
import 'widgets/disease_card_widget.dart';
import 'widgets/treatment_card_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CropFix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF111827),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: const DiseaseDetectionPage(),
    );
  }
}

class DiseaseDetectionPage extends StatefulWidget {
  const DiseaseDetectionPage({super.key});

  @override
  State<DiseaseDetectionPage> createState() => _DiseaseDetectionPageState();
}

class _DiseaseDetectionPageState extends State<DiseaseDetectionPage>
    with SingleTickerProviderStateMixin {
  final TFLiteModel _model = TFLiteModel();
  File? _image;
  Map<String, dynamic>? _prediction;
  EnhancedPredictionResult? _enhancedResult;
  bool _isLoading = false;
  String? _processingStatus;
  bool _modelLoaded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final List<OverlayEntry> _tomatoShowerOverlays = [];
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadTreatments();
    _loadEnhancedMappings();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadModel() async {
    setState(() {
      _isLoading = true;
    });
    await _model.loadModel();
    setState(() {
      _modelLoaded = _model.isLoaded;
      _isLoading = false;
    });
    if (!_modelLoaded) {
      _showErrorDialog('Failed to load the model. Please restart the app.');
    }
  }

  Future<void> _loadTreatments() async {
    await DiseaseTreatmentService.loadTreatments();
  }

  Future<void> _loadEnhancedMappings() async {
    await EnhancedModelService.loadMappings();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _prediction = null;
          _enhancedResult = null;
          _isLoading = true;
          _processingStatus = 'Preparing image...';
        });

        // Start timer for 5-second animation
        final animationStartTime = DateTime.now();

        // Delay to show initial status and let animation start smoothly
        await Future.delayed(const Duration(milliseconds: 800));

        setState(() {
          _processingStatus = 'Processing with AI model...';
        });

        // Run prediction
        final prediction = await _model.predictImage(_image!);

        if (prediction != null) {
          try {
            setState(() {
              _processingStatus = 'Analyzing results...';
            });

            // Process with enhanced model service
            final enhancedResult = EnhancedModelService.processPrediction(
              prediction,
            );

            // Calculate elapsed time and wait to complete 5 seconds total
            final elapsedTime = DateTime.now().difference(animationStartTime);
            final remainingTime = const Duration(seconds: 5) - elapsedTime;

            if (remainingTime.isNegative) {
              // If already past 5 seconds, show immediately
              setState(() {
                _prediction = prediction;
                _enhancedResult = enhancedResult;
                _isLoading = false;
                _processingStatus = null;
              });
            } else {
              // Show final status message if there's enough time
              if (remainingTime.inMilliseconds > 500) {
                setState(() {
                  _processingStatus = 'Finalizing results...';
                });
                // Wait for remaining time to complete 5 seconds
                await Future.delayed(remainingTime);
              } else {
                await Future.delayed(remainingTime);
              }

              setState(() {
                _prediction = prediction;
                _enhancedResult = enhancedResult;
                _isLoading = false;
                _processingStatus = null;
              });
            }

            _animationController.forward(from: 0);

            // Only save to history if it's a valid tomato (fruit or leaf)
            // Save in background to avoid blocking UI
            if (enhancedResult.isValid) {
              _saveDiagnosis(prediction).catchError((error) {
                print('Error saving diagnosis: $error');
              });
            }
          } catch (e) {
            print('Error processing prediction: $e');
            setState(() {
              _isLoading = false;
              _processingStatus = null;
            });
            _showErrorDialog('Error processing result: $e');
          }
        } else {
          setState(() {
            _isLoading = false;
            _processingStatus = null;
          });
          _showErrorDialog('Failed to analyze the image. Please try again.');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _processingStatus = null;
      });
      _showErrorDialog('Error picking image: $e');
    }
  }

  Future<void> _saveDiagnosis(Map<String, dynamic> prediction) async {
    try {
      // Save image file to app directory
      final savedImagePath = await DiagnosisStorageService.saveImageFile(
        _image!,
      );
      // Safely extract predictions (limit to top 5 to reduce storage size)
      final predictionsList = prediction['predictions'] as List?;
      List<Map<String, dynamic>> allPredictions = [];

      if (predictionsList != null) {
        // Limit to top 5 predictions to reduce JSON size
        final limitedList = predictionsList.take(5).toList();
        allPredictions = limitedList.map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          } else if (item is Map) {
            return Map<String, dynamic>.from(item);
          } else {
            return <String, dynamic>{'class': 'Unknown', 'score': 0.0};
          }
        }).toList();
      }

      // Create diagnosis model
      final diagnosis = DiagnosisModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        diseaseName: prediction['disease'] as String,
        confidence: prediction['confidence'] as double,
        imagePath: savedImagePath,
        timestamp: DateTime.now(),
        allPredictions: allPredictions,
      );

      // Save to storage (with timeout protection)
      try {
        await DiagnosisStorageService.saveDiagnosis(diagnosis).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException(
              'Save operation timed out',
              const Duration(seconds: 10),
            );
          },
        );
      } catch (e) {
        print('Error saving diagnosis: $e');
        // Don't rethrow - allow app to continue even if save fails
      }
    } catch (e) {
      print('Error in _saveDiagnosis: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTomatoShower() {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
    });

    late OverlayEntry overlay;
    overlay = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          ignoring: true,
          child: TomatoShowerAnimation(
            onComplete: () {
              overlay.remove();
              _tomatoShowerOverlays.remove(overlay);
              if (_tomatoShowerOverlays.isEmpty) {
                setState(() {
                  _isAnimating = false;
                });
              }
            },
          ),
        ),
      ),
    );

    _tomatoShowerOverlays.add(overlay);
    Overlay.of(context).insert(overlay);
  }

  @override
  void dispose() {
    for (var overlay in _tomatoShowerOverlays) {
      overlay.remove();
    }
    _tomatoShowerOverlays.clear();
    _model.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: CustomAppBar(
        modelLoaded: _modelLoaded,
        isAnimating: _isAnimating,
        onTomatoShower: _showTomatoShower,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeroSectionWidget(modelLoaded: _modelLoaded),
            const SizedBox(height: 32),
            ImageSectionWidget(
              image: _image,
              isLoading: _isLoading,
              processingStatus: _processingStatus,
            ),
            const SizedBox(height: 24),
            ActionButtonsWidget(
              modelLoaded: _modelLoaded,
              isLoading: _isLoading,
              onImagePicked: _pickImage,
            ),
            const SizedBox(height: 32),
            if (_prediction != null && !_isLoading) ...[
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    DiseaseCardWidget(enhancedResult: _enhancedResult),
                    const SizedBox(height: 20),
                    if (DiseaseTreatmentService.isLoaded)
                      TreatmentCardWidget(enhancedResult: _enhancedResult),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
