import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'quran.dart';
import 'repositories.dart';
import 'screens.dart';
import 'firebase_options.dart';
import 'app_design.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final font in ['Amiri', 'Manrope']) {
      yield LicenseEntryWithLineBreaks(
          [font], await rootBundle.loadString('assets/fonts/$font-OFL.txt'));
    }
  });
  final quran = await Quran.load();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
    const emulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
    if (emulator) {
      final host = defaultTargetPlatform == TargetPlatform.android
          ? '10.0.2.2'
          : 'localhost';
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    } else if (!kDebugMode) {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidPlayIntegrityProvider(),
        providerApple: const AppleAppAttestProvider(),
      );
    }
    runApp(HatimApp(
        repo: HatimRepository(
            FirebaseFirestore.instance, FirebaseAuth.instance, quran),
        quran: quran));
  } catch (_) {
    runApp(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const Scaffold(
            body: AppBackground(
                child: SafeArea(
                    child: AppStatus(
          title: 'Bağlantı kurulamadı',
          message: 'İnternet bağlantınızı kontrol edip yeniden deneyin.',
          icon: Icons.wifi_off_rounded,
          onRetry: main,
        ))))));
  }
}

class HatimApp extends StatelessWidget {
  const HatimApp({super.key, required this.repo, required this.quran});
  final HatimRepository repo;
  final Quran quran;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Hatim Halkası',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: HomeScreen(repo: repo, quran: quran),
      );
}
