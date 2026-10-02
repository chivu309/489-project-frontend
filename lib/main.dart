import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/main_navigation.dart';
import 'screens/login_page.dart';
import 'services/api_service.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start waking the Render backend in the background (not awaited),
  // so it's ready by the time the user scans or chats
  ApiService.wakeUp();

  // Camera setup
  cameras = await availableCameras();

  // Initialize Supabase before the app starts
  await Supabase.initialize(
    url: 'https://wqoyhooqjvqjcxbyayyd.supabase.co',
    publishableKey: 'sb_publishable_EI1rtiTy5uMwOtheuhEs1w_NJrGQSK0',
  );

  runApp(const MyApp());
}

// Convenient shortcut used throughout the app to access Supabase
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFBCC2B6)),
        useMaterial3: true,
      ),
      // Show LoginPage if no session exists, otherwise go straight in
      home: supabase.auth.currentSession == null
          ? const LoginPage()
          : const MainNavigation(),
    );
  }
}