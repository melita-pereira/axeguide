import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive_flutter/hive_flutter.dart';
// Link widget is web-only helper; import it when available.
import 'package:url_launcher/link.dart' if (dart.library.html) 'package:url_launcher/link.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Initialize Supabase
  await Supabase.initialize(
    url: 'https://iquyvtssulidxvqthmvl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlxdXl2dHNzdWxpZHh2cXRobXZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkzNzU2MzMsImV4cCI6MjA3NDk1MTYzM30.kl4TsT3jJrkvE2sHuYmVV-e6_fDhuQFttaT_Zb6Ehu0',
  );
  await Hive.initFlutter();
  await Hive.openBox('userPreferences');
  await Hive.openBox('locationCache');
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;
Future<List<Map<String,dynamic>>> getLocations() async {
  final response = await supabase.from('locations').select().order('name');
  return List<Map<String,dynamic>>.from(response);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<bool> _openUrl(String urlString) async {
    if (urlString.isEmpty) return false;
    final uri = Uri.tryParse(urlString);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      return false;
    }
  }


  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<Map<String,dynamic>>>(
        future: getLocations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No locations found'));
          } else {
            final locations = snapshot.data!;
            return ListView.builder(
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final location = locations[index];
                return ListTile(
                  title: Text(location['name'] ?? 'Unknown'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(location['description'] ?? 'No description'),
                      Text(location['town'] ?? ''),
                      Text(location['hours'] ?? ''),
                      // map_link is kept hidden behind the 'Open map' control below
                      Text(location['building_connection'] ?? ''),
                      // Show a clickable placeholder if map_link exists, otherwise show nothing
                      if ((location['map_link'] ?? '').toString().isNotEmpty)
                        // Use Link widget on web (if available) for opening in new tab; fallback to TextButton that calls _openUrl.
                        Builder(builder: (context) {
                          final url = location['map_link'].toString();
                          // On web, the Link widget will be available and can be used directly in the tree.
                          // If Link isn't available at runtime, we still provide the TextButton fallback.
                          try {
                            return Link(
                              uri: Uri.parse(url),
                              target: LinkTarget.blank,
                              builder: (context, followLink) => TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: followLink,
                                icon: const Icon(Icons.map, size: 16, color: Colors.blue),
                                label: const Text(
                                  'Open map',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            );
                          } catch (_) {
                            return TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final ok = await _openUrl(url);
                                  if (!ok) {
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Could not open link')),
                                    );
                                  }
                                },
                              icon: const Icon(Icons.map, size: 16, color: Colors.blue),
                              label: const Text(
                                'Open map',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Colors.blue,
                                ),
                              ),
                            );
                          }
                        }),
                    ],
                  ),
                  isThreeLine: true,
                );
              },
            );
          }
        },
      ),
    );
  }
}
