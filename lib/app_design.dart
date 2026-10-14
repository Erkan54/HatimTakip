import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppColors {
  static const background = Color(0xfff7f4ec);
  static const paper = Color(0xfffffdf8);
  static const green = Color(0xff194a3b);
  static const greenLight = Color(0xffe7eee7);
  static const gold = Color(0xffb79b60);
  static const ink = Color(0xff202b26);
  static const muted = Color(0xff657169);
  static const line = Color(0xffe2e4da);
  static const unread = Color(0xffc9ceca);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.green,
    primary: AppColors.green,
    surface: AppColors.paper,
    onSurface: AppColors.ink,
  );
  final base =
      ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Manrope');
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    textTheme: base.textTheme.copyWith(
      headlineLarge: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 34,
          height: 1.2,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -1.2),
      headlineMedium: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 28,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.8),
      titleLarge: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 22,
          height: 1.4,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.5),
      titleMedium: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 16,
          height: 1.45,
          fontWeight: FontWeight.w700,
          color: AppColors.ink),
      bodyLarge: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 17,
          height: 1.6,
          color: AppColors.ink),
      bodyMedium: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 14,
          height: 1.5,
          color: AppColors.muted),
      labelLarge: const TextStyle(
          fontFamily: 'Manrope', fontSize: 15, fontWeight: FontWeight.w700),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      titleTextStyle: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.ink),
      systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.dark),
    ),
    cardTheme: CardTheme(
        color: AppColors.paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: shape.copyWith(side: const BorderSide(color: AppColors.line))),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
      minimumSize: const Size(0, 56),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(
          fontFamily: 'Manrope', fontSize: 15, fontWeight: FontWeight.w700),
    )),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      side: const BorderSide(color: AppColors.line),
      shape: shape,
    )),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.paper,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.line)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.line)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
    dialogTheme: DialogTheme(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: shape),
    snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle: const TextStyle(
            fontFamily: 'Manrope',
            color: Colors.white,
            fontSize: 14,
            height: 1.5)),
    dividerTheme: const DividerThemeData(color: AppColors.line, space: 32),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.green, linearTrackColor: AppColors.greenLight),
  );
}

/// A static, inexpensive background. Content remains on opaque paper surfaces.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
              Color(0xffedeedf),
              AppColors.background,
              Color(0xfff9f6ef)
            ],
                stops: [
              0,
              0.45,
              1
            ])),
        child: Stack(children: [
          const Positioned(
              top: -42,
              right: -70,
              width: 270,
              height: 270,
              child: IgnorePointer(
                  child: ExcludeSemantics(
                      child: CustomPaint(painter: OrnamentPainter())))),
          child,
        ]),
      );
}

class OrnamentPainter extends CustomPainter {
  const OrnamentPainter({this.color = const Color(0x1882714b)});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final scale in [0.46, 0.34, 0.22]) {
      final radius = size.shortestSide * scale;
      for (var turn = 0; turn < 2; turn++) {
        final path = Path();
        for (var i = 0; i < 4; i++) {
          final angle = i * math.pi / 2 + turn * math.pi / 4;
          final point =
              center + Offset(math.cos(angle), math.sin(angle)) * radius;
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        canvas.drawPath(path..close(), paint);
      }
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(OrnamentPainter oldDelegate) => oldDelegate.color != color;
}

class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.child, this.maxWidth = 680});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth), child: child));
}

class PaperCard extends StatelessWidget {
  const PaperCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) =>
      Card(child: Padding(padding: padding, child: child));
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = AppColors.muted});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          height: 1.5,
          color: color));
}

class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.size = 48, this.dark = false});
  final IconData icon;
  final double size;
  final bool dark;
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: dark ? AppColors.green : AppColors.greenLight,
          borderRadius: BorderRadius.circular(size * 0.32)),
      child: Icon(icon,
          size: size * 0.46,
          color: dark ? const Color(0xffe1cf9d) : AppColors.green));
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction(
      {super.key,
      required this.label,
      required this.onPressed,
      this.busy = false,
      this.icon = Icons.arrow_forward_rounded});
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      child: FilledButton(
          onPressed: busy ? null : onPressed,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (busy)
              const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(icon, size: 20),
            const SizedBox(width: 10),
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ])));
}

class AppStatus extends StatelessWidget {
  const AppStatus(
      {super.key,
      required this.title,
      this.message,
      this.loading = false,
      this.onRetry,
      this.icon = Icons.spa_outlined});
  final String title;
  final String? message;
  final bool loading;
  final VoidCallback? onRetry;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
      child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (loading)
              const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              IconBadge(icon, size: 60),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!, textAlign: TextAlign.center)
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar dene'))
            ],
          ])));
}
