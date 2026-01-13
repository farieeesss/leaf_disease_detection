import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';

class TFLiteModel {
  Interpreter? _interpreter;
  List<String> _classNames = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> loadModel() async {
    try {
      // Load enhanced class names
      final String classNamesJson = await rootBundle.loadString(
        'assets/class_names_enhanced.json',
      );
      final List<dynamic> classNamesList = json.decode(classNamesJson);
      _classNames = classNamesList.cast<String>();

      // Load TFLite model
      _interpreter = await Interpreter.fromAsset(
        'assets/model.tflite/model_float32.tflite',
      );
      _isLoaded = true;
    } catch (e) {
      print('Error loading model: $e');
      _isLoaded = false;
    }
  }

  Future<Map<String, dynamic>?> predictImage(File imageFile) async {
    if (!_isLoaded || _interpreter == null) {
      return null;
    }

    try {
      // Read and preprocess image
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        return null;
      }

      // Resize image to 224x224 (common input size for image classification models)
      final img.Image resizedImage = img.copyResize(
        image,
        width: 224,
        height: 224,
      );

      // Get model input and output shapes
      final inputTensor = _interpreter!.getInputTensor(0);
      final inputShape = inputTensor.shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      print('Input shape: $inputShape');
      print('Output shape: $outputShape');
      print('Input type: ${inputTensor.type}');

      // Check input type and prepare accordingly
      final isUint8Input = inputTensor.type.toString().contains('uint8');

      dynamic reshapedInput;
      if (isUint8Input) {
        // For uint8 models, use raw pixel values (0-255)
        final inputBuffer = _imageToByteListUint8(resizedImage, 224, 3);
        reshapedInput = _reshapeTo4DUint8(inputBuffer, inputShape);
      } else {
        // For float32 models, normalize to 0.0-1.0
        final input = _imageToByteListFloat32(resizedImage, 224, 3);
        final inputBuffer = input.buffer.asFloat32List();
        reshapedInput = _reshapeTo4D(inputBuffer, inputShape);
      }

      // Prepare output buffer - must match the exact output shape
      final outputTensor = _interpreter!.getOutputTensor(0);
      final isUint8Output = outputTensor.type.toString().contains('uint8');

      // Reshape output buffer to match output shape [1, 10]
      final outputBuffer = _createOutputBuffer(outputShape, isUint8Output);

      // Run inference
      _interpreter!.run(reshapedInput, outputBuffer);

      // Extract predictions from reshaped output buffer
      List<double> predictions;
      if (isUint8Output) {
        // Convert uint8 output to double (0-255 range)
        // For classification, these are typically already normalized or can be used directly
        final flatOutput = _flattenOutput(outputBuffer);
        predictions = flatOutput
            .map((value) => (value as int).toDouble() / 255.0)
            .toList();
      } else {
        final flatOutput = _flattenOutput(outputBuffer);
        predictions = flatOutput.cast<double>();
      }

      // Apply softmax if needed (check if values are logits)
      final isLogits = predictions.any((p) => p < 0 || p > 1);
      final normalizedPredictions = isLogits
          ? _softmax(predictions)
          : predictions;

      // Find the class with highest probability
      double maxScore = normalizedPredictions[0];
      int maxIndex = 0;
      for (int i = 0; i < normalizedPredictions.length; i++) {
        if (normalizedPredictions[i] > maxScore) {
          maxScore = normalizedPredictions[i];
          maxIndex = i;
        }
      }

      // Convert score to percentage
      final confidence = (maxScore * 100).clamp(0.0, 100.0);

      // Ensure we don't access out of bounds
      final numClasses = normalizedPredictions.length;
      final numClassNames = _classNames.length;

      // Use the minimum to avoid index out of bounds
      final validLength = numClasses < numClassNames
          ? numClasses
          : numClassNames;

      // Ensure maxIndex is within bounds
      if (maxIndex >= validLength) {
        maxIndex = validLength - 1;
        maxScore = normalizedPredictions[maxIndex];
      }

      return {
        'disease': _classNames[maxIndex],
        'confidence': confidence,
        'predictions': normalizedPredictions
            .asMap()
            .entries
            .where((e) => e.key < validLength) // Only include valid indices
            .map((e) => {'class': _classNames[e.key], 'score': e.value})
            .toList(),
      };
    } catch (e, stackTrace) {
      print('❌ Error predicting image: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Uint8List _imageToByteListFloat32(
    img.Image image,
    int inputSize,
    int numChannels,
  ) {
    final convertedBytes = Float32List(1 * inputSize * inputSize * numChannels);
    final buffer = Float32List.view(convertedBytes.buffer);

    int pixelIndex = 0;
    for (int i = 0; i < inputSize; i++) {
      for (int j = 0; j < inputSize; j++) {
        final pixel = image.getPixel(j, i);
        // Extract RGB channels from pixel using image package methods
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        buffer[pixelIndex++] = (r / 255.0);
        if (numChannels > 1) {
          buffer[pixelIndex++] = (g / 255.0);
        }
        if (numChannels > 2) {
          buffer[pixelIndex++] = (b / 255.0);
        }
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  List<int> _imageToByteListUint8(
    img.Image image,
    int inputSize,
    int numChannels,
  ) {
    final convertedBytes = Uint8List(1 * inputSize * inputSize * numChannels);

    int pixelIndex = 0;
    for (int i = 0; i < inputSize; i++) {
      for (int j = 0; j < inputSize; j++) {
        final pixel = image.getPixel(j, i);
        // Extract RGB channels from pixel
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        convertedBytes[pixelIndex++] = r;
        if (numChannels > 1) {
          convertedBytes[pixelIndex++] = g;
        }
        if (numChannels > 2) {
          convertedBytes[pixelIndex++] = b;
        }
      }
    }
    return convertedBytes.toList();
  }

  List _reshapeTo4D(Float32List input, List<int> shape) {
    if (shape.length == 4) {
      // Reshape to [batch, height, width, channels]
      final batch = shape[0];
      final height = shape[1];
      final width = shape[2];
      final channels = shape[3];

      final reshaped = <List<List<List<double>>>>[];
      for (int b = 0; b < batch; b++) {
        final batchData = <List<List<double>>>[];
        for (int h = 0; h < height; h++) {
          final rowData = <List<double>>[];
          for (int w = 0; w < width; w++) {
            final pixelData = <double>[];
            for (int c = 0; c < channels; c++) {
              final index =
                  b * height * width * channels +
                  h * width * channels +
                  w * channels +
                  c;
              pixelData.add(input[index]);
            }
            rowData.add(pixelData);
          }
          batchData.add(rowData);
        }
        reshaped.add(batchData);
      }
      return reshaped;
    }
    // If shape is not 4D, return as nested list matching the shape
    return [input];
  }

  List _reshapeTo4DUint8(List<int> input, List<int> shape) {
    if (shape.length == 4) {
      // Reshape to [batch, height, width, channels]
      final batch = shape[0];
      final height = shape[1];
      final width = shape[2];
      final channels = shape[3];

      final reshaped = <List<List<List<int>>>>[];
      for (int b = 0; b < batch; b++) {
        final batchData = <List<List<int>>>[];
        for (int h = 0; h < height; h++) {
          final rowData = <List<int>>[];
          for (int w = 0; w < width; w++) {
            final pixelData = <int>[];
            for (int c = 0; c < channels; c++) {
              final index =
                  b * height * width * channels +
                  h * width * channels +
                  w * channels +
                  c;
              pixelData.add(input[index]);
            }
            rowData.add(pixelData);
          }
          batchData.add(rowData);
        }
        reshaped.add(batchData);
      }
      return reshaped;
    }
    // If shape is not 4D, return as nested list matching the shape
    return [input];
  }

  List<double> _softmax(List<double> values) {
    // Find max value for numerical stability
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    // Compute exp(x - max) for each value
    final expValues = values.map((v) {
      final shifted = v - maxVal;
      final clamped = shifted > 20 ? 20 : (shifted < -20 ? -20 : shifted);
      return math.exp(clamped);
    }).toList();

    // Sum of exponentials
    final sum = expValues.reduce((a, b) => a + b);

    // Normalize
    return expValues.map((v) => v / sum).toList();
  }

  dynamic _createOutputBuffer(List<int> shape, bool isUint8) {
    if (shape.length == 1) {
      // Simple 1D output
      return List.filled(shape[0], isUint8 ? 0 : 0.0);
    } else if (shape.length == 2) {
      // 2D output like [1, 10]
      final batch = shape[0];
      final size = shape[1];
      final result = <List>[];
      for (int b = 0; b < batch; b++) {
        result.add(List.filled(size, isUint8 ? 0 : 0.0));
      }
      return result;
    } else {
      // For higher dimensions, create nested lists
      return _createNestedList(shape, isUint8);
    }
  }

  dynamic _createNestedList(List<int> shape, bool isUint8) {
    if (shape.isEmpty) {
      return isUint8 ? 0 : 0.0;
    }
    if (shape.length == 1) {
      return List.filled(shape[0], isUint8 ? 0 : 0.0);
    }
    final result = <dynamic>[];
    final firstDim = shape[0];
    final remainingShape = shape.sublist(1);
    for (int i = 0; i < firstDim; i++) {
      result.add(_createNestedList(remainingShape, isUint8));
    }
    return result;
  }

  List _flattenOutput(dynamic output) {
    if (output is List) {
      final result = <dynamic>[];
      for (final item in output) {
        if (item is List) {
          result.addAll(_flattenOutput(item));
        } else {
          result.add(item);
        }
      }
      return result;
    }
    return [output];
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}
