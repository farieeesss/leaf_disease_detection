import 'package:flutter/material.dart';
import '../screens/diagnosis_history_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool modelLoaded;
  final bool isAnimating;
  final VoidCallback onTomatoShower;

  const CustomAppBar({
    super.key,
    required this.modelLoaded,
    required this.isAnimating,
    required this.onTomatoShower,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTomatoShower,
              borderRadius: BorderRadius.circular(20),
              splashColor: const Color(0xFF10B981).withOpacity(0.2),
              highlightColor: const Color(0xFF10B981).withOpacity(0.1),
              child: AnimatedScale(
                scale: isAnimating ? 0.9 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF10B981),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ClipOval(
                      child: modelLoaded
                          ? Image.asset(
                              'assets/pic/tomato.png',
                              fit: BoxFit.cover,
                            )
                          : const SizedBox(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'CropFix',
            style: TextStyle(
              fontFamily: 'YatraOne',
              fontSize: 24,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history, color: Color(0xFF111827)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DiagnosisHistoryScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}
