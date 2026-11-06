import 'package:flutter/material.dart';

/// Sweeps a highlight band across its child to signal loading.
///
/// Implemented with a single [ShaderMask] over whatever is passed in, so the
/// same widget works for skeleton bars, list tiles or text. The band is masked
/// with [BlendMode.srcATop], which means only pixels the child actually paints
/// are tinted — no rectangle glow around the content.
///
/// Honours the platform "reduce motion" setting by rendering the child
/// unanimated, so the effect never becomes a vestibular trigger.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.enabled = true,
    this.period = const Duration(milliseconds: 1400),
  });

  final Widget child;

  /// Set to false to freeze the sweep, e.g. once content has arrived.
  final bool enabled;

  final Duration period;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _controller.repeat();
  }

  @override
  void didUpdateWidget(Shimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }

    final base = scheme.surfaceContainerHighest;
    final highlight = Color.alphaBlend(
      scheme.surface.withValues(alpha: 0.7),
      scheme.surfaceContainerHighest,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [base, highlight, base],
          stops: const [0.1, 0.5, 0.9],
          transform: _SlidingGradient(_controller.value),
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Translates the gradient from fully off-screen left to fully off-screen
/// right as [progress] runs 0 → 1.
class _SlidingGradient extends GradientTransform {
  const _SlidingGradient(this.progress);

  final double progress;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final dx = bounds.width * (progress * 2 - 1) * 1.5;
    return Matrix4.translationValues(dx, 0, 0);
  }
}

/// A rounded placeholder bar, sized as a fraction of the available width.
///
/// Meant to be wrapped in a [Shimmer]; on its own it is a static grey bar.
class ShimmerBar extends StatelessWidget {
  const ShimmerBar({
    super.key,
    this.widthFactor = 1,
    this.height = 12,
    this.radius = 6,
  });

  final double widthFactor;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
