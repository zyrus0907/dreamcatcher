import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'auth_gate.dart';
import 'new_dream_screen.dart';
import 'dream_detail_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const DreamCatcherApp());
}

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
      home: const AuthGate(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _dreams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDreams();
  }

  Future<void> _loadDreams() async {
    setState(() => _loading = true);
    try {
      final data = await supabase
          .from('dreams')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _dreams = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load dreams: $error')),
        );
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openNewDream() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NewDreamScreen()),
    );
    if (saved == true) _loadDreams();
  }

  Future<void> _openDream(Map<String, dynamic> dream) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DreamDetailScreen(dream: dream)),
    );
    if (changed == true) _loadDreams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dreams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => supabase.auth.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewDream,
        icon: const Icon(Icons.add),
        label: const Text('New dream'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _dreams.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No dreams yet.\nTap "New dream" to capture your first one.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDreams,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _dreams.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final dream = _dreams[index];
                      final title = (dream['title'] as String?)?.trim();
                      final content = (dream['content'] as String?) ?? '';
                      final created = DateTime.tryParse(
                              dream['created_at'] as String? ?? '')
                          ?.toLocal();
                      return Card(
                        child: ListTile(
                          onTap: () => _openDream(dream),
                          title: Text(
                            (title == null || title.isEmpty)
                                ? 'Untitled dream'
                                : title,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              if (created != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '${created.day}/${created.month}/${created.year}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}