import 'package:flutter/material.dart';

class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isRectangle;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.isRectangle = true,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFF222222),
                Color(0xFF333333),
                Color(0xFF444444),
                Color(0xFF333333),
                Color(0xFF222222),
              ],
              stops: [
                0.0,
                0.25 + (_animation.value + 2) / 4 * 0.25,
                0.5,
                0.75 - (_animation.value + 2) / 4 * 0.25,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShimmerContainer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerContainer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

class ShimmerPosterImage extends StatelessWidget {
  final double width;
  final double height;
  final double aspectRatio;

  const ShimmerPosterImage({
    super.key,
    this.width = 120.0,
    this.height = 180.0,
    this.aspectRatio = 2 / 3,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      width: width,
      height: height,
      borderRadius: 8.0,
    );
  }
}

class ShimmerGrid extends StatelessWidget {
  final int itemCount;
  final double itemWidth;
  final double itemHeight;
  final double spacing;
  final int crossAxisCount;

  const ShimmerGrid({
    super.key,
    required this.itemCount,
    this.itemWidth = 120.0,
    this.itemHeight = 180.0,
    this.spacing = 10.0,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: itemWidth / itemHeight,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ShimmerPosterImage(
          width: itemWidth,
          height: itemHeight,
        );
      },
    );
  }
}
