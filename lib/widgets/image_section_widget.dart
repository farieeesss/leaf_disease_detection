import 'dart:io';
import 'package:flutter/material.dart';

class ImageSectionWidget extends StatefulWidget {
  final File? image;
  final bool isLoading;
  final String? processingStatus;

  const ImageSectionWidget({
    super.key,
    required this.image,
    this.isLoading = false,
    this.processingStatus,
  });

  @override
  State<ImageSectionWidget> createState() => _ImageSectionWidgetState();
}

class _ImageSectionWidgetState extends State<ImageSectionWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.25, end: 0.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutCubic),
    );

    _scanController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOutCubic),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(ImageSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _fadeController.forward();
      _pulseController.repeat(reverse: true);
      _scanController.repeat(reverse: true);
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _fadeController.reverse();
      _pulseController.stop();
      _scanController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isLoading ? Colors.transparent : Colors.grey.shade200,
          width: widget.isLoading ? 0 : 1,
        ),
        color: Colors.white,
        boxShadow: widget.isLoading
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: widget.image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.file(
                    widget.image!,
                    height: 320,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: widget.isLoading
                        ? _buildProcessingOverlay()
                        : const SizedBox.shrink(),
                  ),
                ],
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

  Widget _buildProcessingOverlay() {
    return AnimatedBuilder(
      key: const ValueKey('processing'),
      animation: Listenable.merge([_pulseAnimation, _scanAnimation]),
      builder: (context, child) {
        // Calculate smooth scan position with easing
        final scanPosition = Curves.easeInOutCubic.transform(
          _scanAnimation.value,
        );

        return Container(
          height: 320,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(_pulseAnimation.value),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Green outline border that fits the image area
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF10B981),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              // Main scanning line with enhanced effect
              Positioned(
                top: scanPosition * 320 - 4,
                left: 0,
                right: 0,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: const [0.0, 0.2, 0.4, 0.5, 0.6, 0.8, 1.0],
                      colors: [
                        Colors.transparent,
                        const Color(0xFF10B981).withOpacity(0.2),
                        const Color(0xFF10B981).withOpacity(0.6),
                        const Color(0xFF10B981).withOpacity(1.0),
                        const Color(0xFF10B981).withOpacity(0.6),
                        const Color(0xFF10B981).withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.8),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              // Leading edge glow
              Positioned(
                top: scanPosition * 320 - 8,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: 0.5,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF10B981).withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Trailing edge glow
              Positioned(
                top: scanPosition * 320 + 4,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: 0.3,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF10B981).withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Processing indicator with smooth animation
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Outer glow ring
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    // Main progress indicator
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 0.1),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        widget.processingStatus ?? 'Analyzing image...',
                        key: ValueKey(widget.processingStatus),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Please wait',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        letterSpacing: 0.2,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
