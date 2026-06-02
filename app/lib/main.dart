import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

Future<void> main() async {
  // Make sure Flutter is ready before we do async setup.
  WidgetsFlutterBinding.ensureInitialized();

  // Connect to your Supabase backend using the values in supabase_config.dart.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const DreamCatcherApp());
}

// A shortcut to the Supabase client you can use anywhere later.
final supabase = Supabase.instance.client;

class DreamCatcherApp extends StatelessWidget {
  const DreamCatcherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DreamCatcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6C4DF6),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.nightlight_round, size: 72),
            const SizedBox(height: 16),
            Text(
              'DreamCatcher',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text('Connected to Supabase \u2713'),
          ],
        ),
      ),
    );
  }
}