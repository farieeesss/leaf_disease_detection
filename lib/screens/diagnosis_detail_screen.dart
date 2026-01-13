import 'dart:io';
import 'package:flutter/material.dart';
import '../models/diagnosis_model.dart';
import '../services/disease_treatment_service.dart';
import '../services/enhanced_model_service.dart';
import '../widgets/treatment_card_widget.dart';

class DiagnosisDetailScreen extends StatelessWidget {
  final DiagnosisModel diagnosis;

  const DiagnosisDetailScreen({super.key, required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    // Convert disease name to treatment key
    final treatmentKey = EnhancedModelService.getDiseaseTreatmentKey(
      diagnosis.diseaseName,
    );
    final treatment = DiseaseTreatmentService.getTreatment(treatmentKey);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Diagnosis Details',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(diagnosis.imagePath),
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 300,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 64),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Date and Time
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${diagnosis.timestamp.day}/${diagnosis.timestamp.month}/${diagnosis.timestamp.year} at ${diagnosis.timestamp.hour}:${diagnosis.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Disease Card
            _buildDiseaseCard(),
            const SizedBox(height: 20),
            // Treatment Card - only show for diseased tomato leaves
            if (treatment != null && !diagnosis.isHealthy)
              TreatmentCardWidget(treatment: treatment),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseCard() {
    final isHealthy = diagnosis.isHealthy;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isHealthy
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                (isHealthy ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                    .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isHealthy
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHealthy ? 'Healthy Plant!' : 'Disease Detected',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      EnhancedModelService.formatDiseaseName(
                        diagnosis.diseaseName,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Confidence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${diagnosis.confidence.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
