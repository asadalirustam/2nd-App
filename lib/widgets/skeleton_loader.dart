import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({super.key});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _gradientPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _gradientPosition = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Placeholder
            _buildShimmerBlock(
              height: 180,
              width: double.infinity,
              borderRadius: 24,
              baseColor: baseColor,
              highlightColor: highlightColor,
            ),
            const SizedBox(height: 24),
            // Row Overview blocks
            Row(
              children: [
                Expanded(
                  child: _buildShimmerBlock(
                    height: 80,
                    width: double.infinity,
                    borderRadius: 16,
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildShimmerBlock(
                    height: 80,
                    width: double.infinity,
                    borderRadius: 16,
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Title block
            _buildShimmerBlock(
              height: 20,
              width: 150,
              borderRadius: 4,
              baseColor: baseColor,
              highlightColor: highlightColor,
            ),
            const SizedBox(height: 16),
            // List item builders
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      _buildShimmerBlock(
                        height: 50,
                        width: 50,
                        borderRadius: 25,
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildShimmerBlock(
                              height: 16,
                              width: double.infinity,
                              borderRadius: 4,
                              baseColor: baseColor,
                              highlightColor: highlightColor,
                            ),
                            const SizedBox(height: 8),
                            _buildShimmerBlock(
                              height: 10,
                              width: 120,
                              borderRadius: 4,
                              baseColor: baseColor,
                              highlightColor: highlightColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildShimmerBlock(
                        height: 16,
                        width: 60,
                        borderRadius: 4,
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmerBlock({
    required double height,
    required double width,
    required double borderRadius,
    required Color baseColor,
    required Color highlightColor,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(_gradientPosition.value, -0.3),
          end: Alignment(-_gradientPosition.value, 0.3),
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
        ),
      ),
    );
  }
}
