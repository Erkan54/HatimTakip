import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shared motion tokens. All animations are short, eased and one-shot, and
/// collapse to zero when the system asks for reduced motion.
abstract final class Motion {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 650);
  static const reveal = Duration(milliseconds: 1100);
  static const curve = Curves.easeOutCubic;

  static bool enabled(BuildContext context) =>
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  static Duration of(BuildContext context, Duration duration) =>
      enabled(context) ? duration : Duration.zero;
}

/// Fades a child in while it rises a few pixels. [index] staggers siblings.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn(
      {super.key, required this.child, this.index = 0, this.offset = 14});
  final Widget child;
  final int index;
  final double offset;
  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  static const _step = 55, _base = 420;
  late final AnimationController controller;
  late final Animation<double> curve;

  @override
  void initState() {
    super.initState();
    final delay = math.min(widget.index, 8) * _step;
    controller = AnimationController(
        vsync: this, duration: Duration(milliseconds: _base + delay));
    curve = CurvedAnimation(
        parent: controller,
        curve: Interval(delay / (_base + delay), 1, curve: Motion.curve));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (controller.status == AnimationStatus.dismissed) {
      if (Motion.enabled(context)) {
        controller.forward();
      } else {
        controller.value = 1;
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: curve,
      child: widget.child,
      builder: (context, child) => Opacity(
          opacity: curve.value,
          child: Transform.translate(
              offset: Offset(0, (1 - curve.value) * widget.offset),
              child: child)));
}

/// Gently scales its child down while a pointer is pressed. It listens to raw
/// pointer events, so it does not compete with buttons or ink wells.
class SoftPressable extends StatefulWidget {
  const SoftPressable(
      {super.key,
      required this.child,
      this.scale = 0.975,
      this.enabled = true});
  final Widget child;
  final double scale;
  final bool enabled;
  @override
  State<SoftPressable> createState() => _SoftPressableState();
}

class _SoftPressableState extends State<SoftPressable> {
  bool pressed = false;
  void set(bool value) {
    if (pressed != value && mounted) setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
      onPointerDown: widget.enabled ? (_) => set(true) : null,
      onPointerUp: (_) => set(false),
      onPointerCancel: (_) => set(false),
      child: AnimatedScale(
          scale: pressed && widget.enabled ? widget.scale : 1,
          duration: Motion.of(context, const Duration(milliseconds: 140)),
          curve: Curves.easeOut,
          child: widget.child));
}

/// Animates a number from its previous value (or zero) to [value].
class CountUpText extends StatelessWidget {
  const CountUpText(this.value,
      {super.key,
      this.style,
      this.format,
      this.duration = Motion.slow,
      this.textAlign});
  final num value;
  final TextStyle? style;
  final String Function(double value)? format;
  final Duration duration;
  final TextAlign? textAlign;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: Motion.of(context, duration),
      curve: Motion.curve,
      builder: (context, v, _) => Text(format?.call(v) ?? v.round().toString(),
          style: style, textAlign: textAlign));
}

/// A circular progress ring that eases to [value] (0..1).
class ProgressRing extends StatelessWidget {
  const ProgressRing(
      {super.key,
      required this.value,
      required this.color,
      required this.trackColor,
      this.size = 96,
      this.stroke = 8,
      this.child});
  final double? value;
  final Color color, trackColor;
  final double size, stroke;
  final Widget? child;
  @override
  Widget build(BuildContext context) => SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: (value ?? 0).clamp(0, 1).toDouble()),
          duration: Motion.of(context, Motion.reveal),
          curve: Motion.curve,
          builder: (context, v, child) => CustomPaint(
              painter: _RingPainter(v, color, trackColor, stroke),
              child: Center(child: child)),
          child: child));
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color, this.track, this.stroke);
  final double value, stroke;
  final Color color, track;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, base..color = track);
    if (value <= 0) return;
    // Very small values are still visible as a dot.
    final sweep = math.max(value * math.pi * 2, 0.02);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, base..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// A row of segments that fill one by one, e.g. confirmed verses of a session.
class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress(
      {super.key,
      required this.total,
      required this.done,
      required this.color,
      required this.trackColor,
      this.current});
  final int total, done;
  final int? current;
  final Color color, trackColor;
  @override
  Widget build(BuildContext context) => Semantics(
      label: 'Okuma ilerlemesi',
      value: '$done / $total ayet',
      child: ExcludeSemantics(
          child: Row(children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
              child: AnimatedContainer(
                  duration: Motion.of(context, Motion.medium),
                  curve: Motion.curve,
                  height: 6,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: i < done
                          ? color
                          : i == (current ?? done)
                              ? color.withOpacity(0.35)
                              : trackColor))),
        ]
      ])));
}

/// A one-shot soft glow with drifting golden particles. Plays once on build
/// (or when [trigger] changes) and then stays still.
class SoftCelebration extends StatefulWidget {
  const SoftCelebration(
      {super.key,
      required this.color,
      this.trigger = 0,
      this.child,
      this.enabled = true});
  final Color color;
  final Object trigger;
  final Widget? child;
  final bool enabled;
  @override
  State<SoftCelebration> createState() => _SoftCelebrationState();
}

class _SoftCelebrationState extends State<SoftCelebration>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (controller.status == AnimationStatus.dismissed) play();
  }

  @override
  void didUpdateWidget(SoftCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) play();
  }

  void play() {
    if (widget.enabled && Motion.enabled(context)) {
      controller.forward(from: 0);
    } else {
      controller.value = 1;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
      foregroundPainter: _CelebrationPainter(controller, widget.color),
      child: widget.child);
}

class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter(this.animation, this.color) : super(repaint: animation);
  final Animation<double> animation;
  final Color color;
  static final _seeds = List.generate(18, (i) {
    final r = math.Random(i * 7919 + 13);
    return (r.nextDouble(), r.nextDouble(), r.nextDouble(), r.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t <= 0 || t >= 1) return;
    final fade = math.sin(t * math.pi);
    final glow = Paint()
      ..shader = RadialGradient(colors: [
        color.withOpacity(0.22 * fade),
        color.withOpacity(0),
      ]).createShader(Rect.fromCircle(
          center: size.center(Offset.zero), radius: size.longestSide * 0.6));
    canvas.drawRect(Offset.zero & size, glow);
    final dot = Paint();
    for (final (x, delay, speed, radius) in _seeds) {
      final local = ((t - delay * 0.35) / 0.65).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final ease = Curves.easeOutCubic.transform(local);
      final dx = size.width * (0.1 + x * 0.8) +
          math.sin((local + x) * math.pi * 2) * 6;
      final dy = size.height * (0.9 - ease * (0.55 + speed * 0.4));
      dot.color = color.withOpacity(0.75 * math.sin(local * math.pi));
      canvas.drawCircle(Offset(dx, dy), 1.6 + radius * 2.4, dot);
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter old) => old.color != color;
}
