import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:axeguide/utils/user_box_helper.dart';

import 'screens/welcome_screen.dart';
import 'screens/personalization/personalization_loc_screen.dart';
import 'screens/home_screen.dart';
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
    } else if (UserBoxHelper.needsPersonalization) {
      startScreen = const PersonalizationScreen();
    } else if (!UserBoxHelper.hasWalkthroughCheckpoint) {
      startScreen = const WalkthroughScreen();
    } else {
      startScreen = const HomeScreen();
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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF013A6E)),
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF002860),
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF01366B)),
        ),
        useMaterial3: true,
      ),
      home: startScreen,
      routes: {
        "/genericHome": (context) => const HomeScreen(),
      },
    );
  }
}
