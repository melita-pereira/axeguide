import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:axeguide/utils/user_box_helper.dart';

import 'screens/welcome_screen.dart';
import 'screens/dynamic_home_screen.dart';
import 'screens/walkthrough/walkthrough_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  //Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  await Hive.initFlutter();
  await Hive.openBox('locationCache');
  await Hive.openBox('userBox');

  await UserBoxHelper.updateLastActive();

  // Decide start screen defensively. If any error occurs while reading
  // user preferences, fall back to the welcome screen so the app doesn't
  // crash at startup.
  Widget startScreen;
  try {
    if (!UserBoxHelper.hasSeenWelcome) {
      startScreen = const WelcomeScreen();
    } else if (UserBoxHelper.skippedPersonalization) {
      // User chose to skip personalization, never show walkthrough
      startScreen = const DynamicHomeScreen();
    } else if (UserBoxHelper.hasWalkthroughCheckpoint) {
      // Checkpoint exists = resume walkthrough
      startScreen = const WalkthroughScreen();
    } else {
      // No checkpoint = walkthrough completed, go to home
      startScreen = const DynamicHomeScreen();
    }
  } catch (e) {
    startScreen = const WelcomeScreen();
  }

  runApp(MyApp(startScreen: startScreen));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;
  const MyApp({super.key, required this.startScreen});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The AxeGuide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF013A6E),
          primary: const Color(0xFF013A6E),
          secondary: const Color(0xFF025A9E),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        
        // AppBar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF013A6E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        
        // Card theme
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        
        // Elevated button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF013A6E),
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: const Color(0xFF013A6E).withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        // Text button theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF013A6E),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF013A6E), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        
        // Text theme
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A202C),
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A202C),
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A202C),
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A202C),
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A202C),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF2D3748),
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            color: Color(0xFF2D3748),
            height: 1.5,
          ),
        ),
      ),
      home: startScreen,
      routes: {
        "/genericHome": (context) => const DynamicHomeScreen(),
      },
    );
  }
}
