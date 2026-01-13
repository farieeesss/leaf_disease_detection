import 'package:flutter/material.dart';
import '../services/enhanced_model_service.dart';
import '../services/disease_treatment_service.dart';

class TreatmentCardWidget extends StatelessWidget {
  final EnhancedPredictionResult? enhancedResult;
  final DiseaseTreatment? treatment;

  const TreatmentCardWidget({
    super.key,
    this.enhancedResult,
    this.treatment,
  }) : assert(
          enhancedResult != null || treatment != null,
          'Either enhancedResult or treatment must be provided',
        );

  @override
  Widget build(BuildContext context) {
    DiseaseTreatment? finalTreatment = treatment;

    // If treatment is not directly provided, get it from enhancedResult
    if (finalTreatment == null && enhancedResult != null) {
      // Only show treatment for tomato leaves with diseases
      if (!enhancedResult!.isTomatoLeaf) {
        return const SizedBox.shrink();
      }

      // Don't show treatment for healthy plants or invalid images
      if (enhancedResult!.isHealthy || !enhancedResult!.isValid) {
        return const SizedBox.shrink();
      }

      // Get treatment using the mapped disease key
      final treatmentKey = EnhancedModelService.getDiseaseTreatmentKey(
        enhancedResult!.className,
      );
      finalTreatment = DiseaseTreatmentService.getTreatment(treatmentKey);
    }

    if (finalTreatment == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Treatment Guide',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            finalTreatment.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _TreatmentSection(
            title: 'Treatment Steps',
            items: finalTreatment.treatments,
            icon: Icons.local_hospital_outlined,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 20),
          _TreatmentSection(
            title: 'Prevention Tips',
            items: finalTreatment.prevention,
            icon: Icons.shield_outlined,
            color: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }
}

class _TreatmentSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  const _TreatmentSection({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      title == 'Treatment Steps' ? '${entry.key + 1}' : '✓',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
