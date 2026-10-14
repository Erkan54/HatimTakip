import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'motion.dart';

/// Light palette constants. Prefer [AppPalette] via `context.palette` in
/// widgets so that dark mode is respected.
abstract final class AppColors {
  static const background = Color(0xfff7f4ec);
  static const paper = Color(0xfffffdf8);
  static const green = Color(0xff194a3b);
  static const greenLight = Color(0xffe7eee7);
  static const gold = Color(0xffb79b60);
  static const ink = Color(0xff202b26);
  static const muted = Color(0xff657169);
  static const line = Color(0xffe2e4da);
  static const unread = Color(0xffe4dfd2);
}

/// Spacing scale.
abstract final class AppSpace {
  static const s4 = 4.0, s8 = 8.0, s12 = 12.0, s16 = 16.0, s20 = 20.0;
  static const s24 = 24.0, s28 = 28.0, s32 = 32.0;
}

/// Corner radius scale.
abstract final class AppRadius {
  static const chip = 30.0, field = 16.0, card = 18.0, hero = 24.0;
  static const sheet = 28.0;
}

/// Every color used by the UI. Screens read it with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.paper,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.accent,
    required this.gold,
    required this.goldSoft,
    required this.ink,
    required this.muted,
    required this.line,
    required this.unread,
    required this.partial,
    required this.done,
    required this.hero,
    required this.heroMuted,
    required this.heroGold,
    required this.heroBar,
    required this.badgeGold,
    required this.ornament,
    required this.heroOrnament,
  });

  final Color background, backgroundStart, backgroundEnd, paper;
  final Color primary, onPrimary, primarySoft, accent;
  final Color gold, goldSoft, ink, muted, line;
  final Color unread, partial, done;
  final Color hero, heroMuted, heroGold, heroBar, badgeGold;
  final Color ornament, heroOrnament;

  static const light = AppPalette(
    background: AppColors.background,
    backgroundStart: Color(0xffedeedf),
    backgroundEnd: Color(0xfff9f6ef),
    paper: AppColors.paper,
    primary: AppColors.green,
    onPrimary: Colors.white,
    primarySoft: AppColors.greenLight,
    accent: AppColors.green,
    gold: AppColors.gold,
    goldSoft: Color(0xfff1e8d0),
    ink: AppColors.ink,
    muted: AppColors.muted,
    line: AppColors.line,
    unread: AppColors.unread,
    partial: Color(0xffd8bd7f),
    done: AppColors.green,
    hero: AppColors.green,
    heroMuted: Color(0xffd4dfce),
    heroGold: Color(0xffe5d6af),
    heroBar: Color(0xffdbc58d),
    badgeGold: Color(0xffe1cf9d),
    ornament: Color(0x1882714b),
    heroOrnament: Color(0x25e4cd93),
  );

  static const dark = AppPalette(
    background: Color(0xff0f1714),
    backgroundStart: Color(0xff14221c),
    backgroundEnd: Color(0xff0d1411),
    paper: Color(0xff17231e),
    primary: Color(0xff2c6a55),
    onPrimary: Color(0xfff4f1e8),
    primarySoft: Color(0xff1f3229),
    accent: Color(0xff9fd0b6),
    gold: Color(0xffc9ad70),
    goldSoft: Color(0xff352e20),
    ink: Color(0xffece7da),
    muted: Color(0xff9aa79f),
    line: Color(0xff26352e),
    unread: Color(0xff25322c),
    partial: Color(0xffa88a4f),
    done: Color(0xff4f9c7f),
    hero: Color(0xff1c4538),
    heroMuted: Color(0xffb9c8b7),
    heroGold: Color(0xffe5d6af),
    heroBar: Color(0xffdbc58d),
    badgeGold: Color(0xffe1cf9d),
    ornament: Color(0x1cc9ad70),
    heroOrnament: Color(0x25e4cd93),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: l(background, other.background),
      backgroundStart: l(backgroundStart, other.backgroundStart),
      backgroundEnd: l(backgroundEnd, other.backgroundEnd),
      paper: l(paper, other.paper),
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      primarySoft: l(primarySoft, other.primarySoft),
      accent: l(accent, other.accent),
      gold: l(gold, other.gold),
      goldSoft: l(goldSoft, other.goldSoft),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      line: l(line, other.line),
      unread: l(unread, other.unread),
      partial: l(partial, other.partial),
      done: l(done, other.done),
      hero: l(hero, other.hero),
      heroMuted: l(heroMuted, other.heroMuted),
      heroGold: l(heroGold, other.heroGold),
      heroBar: l(heroBar, other.heroBar),
      badgeGold: l(badgeGold, other.badgeGold),
      ornament: l(ornament, other.ornament),
      heroOrnament: l(heroOrnament, other.heroOrnament),
    );
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
  TextTheme get text => Theme.of(this).textTheme;
}

/// A soft fade + small upward slide for page routes.
class SoftPageTransitionsBuilder extends PageTransitionsBuilder {
  const SoftPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    if (!Motion.enabled(context)) return child;
    final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic);
    return FadeTransition(
        opacity: curved,
        child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.025), end: Offset.zero)
                .animate(curved),
            child: child));
  }
}

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.green,
    brightness: brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    secondaryContainer: p.primarySoft,
    onSecondaryContainer: p.accent,
    surface: p.paper,
    onSurface: p.ink,
    onSurfaceVariant: p.muted,
    outline: p.line,
    outlineVariant: p.line,
  );
  final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Manrope');
  final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card));
  TextStyle t(double size, double height,
          {FontWeight weight = FontWeight.w400,
          Color? color,
          double spacing = 0}) =>
      TextStyle(
          fontFamily: 'Manrope',
          fontSize: size,
          height: height,
          fontWeight: weight,
          color: color ?? p.ink,
          letterSpacing: spacing);
  final dark = brightness == Brightness.dark;
  return base.copyWith(
    extensions: [p],
    scaffoldBackgroundColor: p.background,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: SoftPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: SoftPageTransitionsBuilder(),
      TargetPlatform.linux: SoftPageTransitionsBuilder(),
      TargetPlatform.macOS: SoftPageTransitionsBuilder(),
    }),
    textTheme: base.textTheme.copyWith(
      headlineLarge: t(34, 1.2, weight: FontWeight.w700, spacing: -1.2),
      headlineMedium: t(28, 1.3, weight: FontWeight.w700, spacing: -0.8),
      titleLarge: t(22, 1.4, weight: FontWeight.w700, spacing: -0.5),
      titleMedium: t(16, 1.45, weight: FontWeight.w700),
      bodyLarge: t(17, 1.6),
      bodyMedium: t(14, 1.5, color: p.muted),
      bodySmall: t(12, 1.5, color: p.muted),
      labelLarge: t(15, 1.3, weight: FontWeight.w700),
    ),
    iconTheme: IconThemeData(color: p.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      titleTextStyle: t(18, 1.3, weight: FontWeight.w700),
      systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: dark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: p.background,
          systemNavigationBarIconBrightness:
              dark ? Brightness.light : Brightness.dark),
    ),
    cardTheme: CardTheme(
        color: p.paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: shape.copyWith(side: BorderSide(color: p.line))),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
      backgroundColor: p.primary,
      foregroundColor: p.onPrimary,
      disabledBackgroundColor: p.primary.withOpacity(0.55),
      disabledForegroundColor: p.onPrimary.withOpacity(0.85),
      minimumSize: const Size(0, 56),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field)),
      textStyle: t(15, 1.3, weight: FontWeight.w700),
    )),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
      foregroundColor: p.accent,
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      side: BorderSide(color: p.line),
      shape: shape,
      textStyle: t(15, 1.3, weight: FontWeight.w700),
    )),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            foregroundColor: p.accent, minimumSize: const Size(48, 48))),
    iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: p.ink)),
    segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
      side: WidgetStatePropertyAll(BorderSide(color: p.line)),
      backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primarySoft : p.paper),
      foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.ink),
    )),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.paper,
      contentPadding: const EdgeInsets.all(18),
      labelStyle: TextStyle(color: p.muted),
      hintStyle: TextStyle(color: p.muted.withOpacity(0.7)),
      prefixIconColor: p.muted,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: p.line)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: p.line)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: p.accent, width: 1.5)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.paper,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.line,
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)))),
    dialogTheme: DialogTheme(
        backgroundColor: p.paper,
        surfaceTintColor: Colors.transparent,
        shape: shape),
    snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? const Color(0xff24352d) : AppColors.green,
        actionTextColor: p.heroBar,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle: const TextStyle(
            fontFamily: 'Manrope',
            color: Colors.white,
            fontSize: 14,
            height: 1.5)),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.onPrimary : p.muted),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : p.primarySoft),
    ),
    sliderTheme: SliderThemeData(
        activeTrackColor: p.primary,
        inactiveTrackColor: p.primarySoft,
        thumbColor: p.primary,
        overlayColor: p.primary.withOpacity(0.12)),
    listTileTheme: ListTileThemeData(iconColor: p.accent, textColor: p.ink),
    radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.accent : p.muted)),
    dividerTheme: DividerThemeData(color: p.line, space: 32),
    progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent, linearTrackColor: p.primarySoft),
  );
}

/// A static, inexpensive background. Content remains on opaque paper surfaces.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.backgroundStart, p.background, p.backgroundEnd],
              stops: const [0, 0.45, 1])),
      child: Stack(children: [
        Positioned(
            top: -42,
            right: -70,
            width: 270,
            height: 270,
            child: IgnorePointer(
                child: ExcludeSemantics(
                    child: RepaintBoundary(
                        child: CustomPaint(
                            painter: OrnamentPainter(color: p.ornament)))))),
        child,
      ]),
    );
  }
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
      this.padding = const EdgeInsets.all(20),
      this.onTap});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    if (onTap == null) return Card(child: content);
    return SoftPressable(
        child: Card(child: InkWell(onTap: onTap, child: content)));
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          height: 1.5,
          color: color ?? context.palette.muted));
}

class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.size = 48, this.dark = false});
  final IconData icon;
  final double size;
  final bool dark;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedContainer(
        duration: Motion.of(context, Motion.medium),
        curve: Motion.curve,
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: dark ? p.primary : p.primarySoft,
            borderRadius: BorderRadius.circular(size * 0.32)),
        child: Icon(icon,
            size: size * 0.46, color: dark ? p.badgeGold : p.accent));
  }
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
  Widget build(BuildContext context) => SoftPressable(
      enabled: !busy && onPressed != null,
      child: SizedBox(
          width: double.infinity,
          child: FilledButton(
              onPressed: busy ? null : onPressed,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedSwitcher(
                    duration: Motion.of(context, Motion.fast),
                    transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child)),
                    child: busy
                        ? SizedBox(
                            key: const ValueKey('busy'),
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.palette.onPrimary))
                        : Icon(icon, key: ValueKey(icon), size: 20)),
                const SizedBox(width: 10),
                Flexible(child: Text(label, textAlign: TextAlign.center)),
              ]))));
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
          child: FadeSlideIn(
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
                textAlign: TextAlign.center, style: context.text.titleLarge),
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
          ]))));
}

/// Small rounded pill label.
class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key, this.icon});
  final String label;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: p.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.chip)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: p.accent),
            const SizedBox(width: 5),
          ],
          Flexible(
              child: Text(label,
                  style: TextStyle(
                      color: p.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600))),
        ]));
  }
}

/// Colored square + label used in map legends.
class LegendDot extends StatelessWidget {
  const LegendDot({super.key, required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(fontSize: 12, color: context.palette.muted)),
      ]);
}
