import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/theme.dart';
import 'core/constants.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Immersive dark system UI overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: ViralyTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Supabase with 100% live connection
  await Supabase.initialize(
    url: ViralyConstants.supabaseUrl,
    anonKey: ViralyConstants.supabaseAnonKey,
  );

  // Initialize Sentry crash reporting for production monitoring
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://examplePublicKey@o0.ingest.sentry.io/0';
      options.environment = 'production';
      options.release = 'viraly@1.0.0+1';
      options.tracesSampleRate = 0.2;
      options.attachScreenshot = false;
      options.enableAutoSessionTracking = true;
    },
    appRunner: () => runApp(const ViralyApp()),
  );
}

class ViralyApp extends StatelessWidget {
  const ViralyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: ViralyConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ViralyTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
