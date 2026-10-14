import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_design.dart';
import 'motion.dart';

export 'settings_screen.dart' show SettingsScreen;

/// Device-local preferences. Nothing here touches Firestore.
class AppSettings extends ChangeNotifier {
  AppSettings({SharedPreferences? prefs}) : _prefs = prefs {
    final p = _prefs;
    if (p == null) return;
    // Preserve an explicitly chosen dark theme; migrate old system preferences
    // (and missing/invalid values) to light without following the device theme.
    _theme = p.getInt(_kTheme) == ThemeMode.dark.index
        ? ThemeMode.dark
        : ThemeMode.light;
    _arabicScale = (p.getDouble(_kScale) ?? 1).clamp(minScale, maxScale);
    _showTranslation = p.getBool(_kMeal) ?? false;
    _haptics = p.getBool(_kHaptics) ?? true;
  }

  static const minScale = 0.8, maxScale = 1.6;
  static const _kTheme = 'theme', _kScale = 'arabicScale';
  static const _kMeal = 'showTranslation', _kHaptics = 'haptics';

  static Future<AppSettings> load() async {
    try {
      return AppSettings(prefs: await SharedPreferences.getInstance());
    } catch (_) {
      return AppSettings();
    }
  }

  /// Falls back to in-memory defaults when no [SettingsScope] is present.
  static AppSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()?.notifier ??
      _fallback;
  static final _fallback = AppSettings();

  final SharedPreferences? _prefs;
  ThemeMode _theme = ThemeMode.light;
  double _arabicScale = 1;
  bool _showTranslation = false;
  bool _haptics = true;

  ThemeMode get theme => _theme;
  double get arabicScale => _arabicScale;
  bool get showTranslation => _showTranslation;
  bool get haptics => _haptics;

  set theme(ThemeMode value) {
    final selected = value == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
    if (selected == _theme) return;
    _theme = selected;
    _prefs?.setInt(_kTheme, selected.index);
    notifyListeners();
  }

  set arabicScale(double value) {
    final v = (value.clamp(minScale, maxScale) * 10).round() / 10;
    if (v == _arabicScale) return;
    _arabicScale = v;
    _prefs?.setDouble(_kScale, v);
    notifyListeners();
  }

  set showTranslation(bool value) {
    if (value == _showTranslation) return;
    _showTranslation = value;
    _prefs?.setBool(_kMeal, value);
    notifyListeners();
  }

  set haptics(bool value) {
    if (value == _haptics) return;
    _haptics = value;
    _prefs?.setBool(_kHaptics, value);
    notifyListeners();
  }

  void tap() {
    if (_haptics) HapticFeedback.lightImpact();
  }

  void success() {
    if (_haptics) HapticFeedback.mediumImpact();
  }
}

class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope(
      {super.key, required AppSettings settings, required super.child})
      : super(notifier: settings);
}

/// Arabic text size slider with a live preview. Used in settings and reader.
class ArabicSizeControl extends StatelessWidget {
  const ArabicSizeControl({super.key, required this.settings});
  final AppSettings settings;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListenableBuilder(
        listenable: settings,
        builder: (context, _) =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                      color: p.background,
                      borderRadius: BorderRadius.circular(AppRadius.field)),
                  child: AnimatedDefaultTextStyle(
                      duration: Motion.of(context, Motion.fast),
                      style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 30 * settings.arabicScale,
                          height: 1.9,
                          color: p.ink),
                      child: const Text(
                          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl))),
              const SizedBox(height: 8),
              Row(children: [
                IconButton(
                    tooltip: 'Yazıyı küçült',
                    onPressed: settings.arabicScale > AppSettings.minScale
                        ? () => settings.arabicScale -= 0.1
                        : null,
                    icon: const Icon(Icons.text_decrease_rounded)),
                Expanded(
                    child: Slider(
                        value: settings.arabicScale,
                        min: AppSettings.minScale,
                        max: AppSettings.maxScale,
                        divisions: 8,
                        label: '%${(settings.arabicScale * 100).round()}',
                        semanticFormatterCallback: (v) =>
                            'Arapça yazı boyutu yüzde ${(v * 100).round()}',
                        onChanged: (v) => settings.arabicScale = v)),
                IconButton(
                    tooltip: 'Yazıyı büyüt',
                    onPressed: settings.arabicScale < AppSettings.maxScale
                        ? () => settings.arabicScale += 0.1
                        : null,
                    icon: const Icon(Icons.text_increase_rounded)),
              ]),
            ]));
  }
}
