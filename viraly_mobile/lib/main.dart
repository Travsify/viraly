import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'core/constants.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set immersive dark system UI overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: ViralyTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Supabase with 100% Live Connection
  await Supabase.initialize(
    url: ViralyConstants.supabaseUrl,
    anonKey: ViralyConstants.supabaseAnonKey,
  );

  runApp(const ViralyApp());
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
