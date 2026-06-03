import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'auth_gate.dart';
import 'new_dream_screen.dart';
import 'dream_detail_screen.dart';
import 'search_screen.dart';
import 'dream_recovery_screen.dart';
import 'pattern_analysis_screen.dart';
import 'dream_universe_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const DreamCatcherApp());
}

final supabase = Supabase.instance.client;

// ── DreamCatcher palette: warm starlight on a deep night sky ──
const nightBg = Color(0xFF101331);
const nightSurface = Color(0xFF1B1F44);
const starGold = Color(0xFFEAB873);
const softViolet = Color(0xFFB3A4E8);
const warmText = Color(0xFFF2ECE0);
const onGold = Color(0xFF2A1E05);

class DreamCatcherApp extends StatelessWidget {
  const DreamCatcherApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: softViolet,
      brightness: Brightness.dark,
    ).copyWith(
      primary: starGold,
      onPrimary: onGold,
      secondary: softViolet,
      surface: nightSurface,
      onSurface: warmText,
    );

    final baseDark = ThemeData(brightness: Brightness.dark);

    return MaterialApp(
      title: 'DreamCatcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: nightBg,
        textTheme: GoogleFonts.nunitoTextTheme(baseDark.textTheme)
            .apply(bodyColor: warmText, displayColor: warmText),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: warmText,
        ),
        cardTheme: CardThemeData(
          color: nightSurface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: nightSurface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: starGold, width: 1.5)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: starGold,
            foregroundColor: onGold,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: nightSurface,
          selectedColor: starGold,
          side: BorderSide.none,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
          .order('pinned', ascending: false)
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

  void _go(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  String? _topEmotion() {
    final counts = <String, int>{};
    for (final d in _dreams) {
      for (final e in ((d['emotions'] as List?) ?? [])) {
        counts[e as String] = (counts[e] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sidebar(),
                  Expanded(child: _mainContent(wide: true)),
                ],
              );
            }
            return Column(
              children: [
                _topBarNarrow(),
                Expanded(child: _mainContent(wide: false)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sidebar() {
    return Container(
      width: 250,
      color: nightSurface,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.nightlight_round, color: starGold),
              const SizedBox(width: 10),
              Text('DreamCatcher',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 32),
          _navItem(Icons.book_outlined, 'My Dreams', active: true, onTap: () {}),
          _navItem(Icons.auto_awesome, 'Recover',
              onTap: () => _go(const DreamRecoveryScreen())),
          _navItem(Icons.insights, 'Patterns',
              onTap: () => _go(const PatternAnalysisScreen())),
          _navItem(Icons.search, 'Search',
              onTap: () => _go(const SearchScreen())),
          _navItem(Icons.bubble_chart, 'Universe',
              onTap: () => _go(const DreamUniverseScreen())),
          const Spacer(),
          Text('Dreams captured',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: warmText.withValues(alpha: 0.6))),
          Text('${_dreams.length}',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: starGold, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _navItem(Icons.logout, 'Sign out',
              onTap: () => supabase.auth.signOut()),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label,
      {bool active = false, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: active ? starGold.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color:
                        active ? starGold : warmText.withValues(alpha: 0.8)),
                const SizedBox(width: 12),
                Text(label,
                    style: TextStyle(
                        color: active ? starGold : warmText,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBarNarrow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
      child: Row(
        children: [
          const Icon(Icons.nightlight_round, color: starGold),
          const SizedBox(width: 8),
          Text('DreamCatcher',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const Spacer(),
          IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: () => _go(const DreamRecoveryScreen())),
          IconButton(
              icon: const Icon(Icons.insights),
              onPressed: () => _go(const PatternAnalysisScreen())),
          IconButton(
              icon: const Icon(Icons.bubble_chart),
              onPressed: () => _go(const DreamUniverseScreen())),
          IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _go(const SearchScreen())),
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => supabase.auth.signOut()),
        ],
      ),
    );
  }

  Widget _mainContent({required bool wide}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final recent = _recentDreamsCard();
    final glance = _atAGlanceCard();
    final quick = _quickAccessCard();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('Welcome back ✨',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
              FilledButton.icon(
                onPressed: _openNewDream,
                icon: const Icon(Icons.add),
                label: const Text('New dream'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: recent),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [glance, const SizedBox(height: 16), quick],
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                recent,
                const SizedBox(height: 16),
                glance,
                const SizedBox(height: 16),
                quick,
              ],
            ),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: nightSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _recentDreamsCard() {
    if (_dreams.isEmpty) {
      return _card(
        title: 'Recent dreams',
        child: const Text('No dreams yet. Tap "New dream" to start.'),
      );
    }
    final shown = _dreams.take(8).toList();
    return _card(
      title: 'Recent dreams',
      child: Column(
        children: shown.map((dream) {
          final title = (dream['title'] as String?)?.trim();
          final content = (dream['content'] as String?) ?? '';
          final emotions = (dream['emotions'] as List?)?.cast<String>() ?? [];
          final hasAudio = dream['audio_path'] != null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openDream(dream),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: nightBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: softViolet.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.nightlight_round,
                          size: 18, color: softViolet),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (dream['pinned'] == true)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(Icons.push_pin,
                                      size: 14, color: starGold),
                                ),
                              Expanded(
                                child: Text(
                                  (title == null || title.isEmpty)
                                      ? 'Untitled dream'
                                      : title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasAudio)
                                const Icon(Icons.mic,
                                    size: 16, color: starGold),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: warmText.withValues(alpha: 0.7),
                                  fontSize: 13)),
                          if (emotions.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: emotions.take(4).map((e) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: starGold.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(e,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: starGold,
                                          fontWeight: FontWeight.w600)),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _atAGlanceCard() {
    final top = _topEmotion();
    return _card(
      title: 'At a glance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Dreams captured'),
              Text('${_dreams.length}',
                  style: const TextStyle(
                      color: starGold, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Most felt emotion'),
              Text(top ?? '—',
                  style: const TextStyle(
                      color: softViolet, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAccessCard() {
    Widget tile(IconData icon, String label, VoidCallback onTap) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: starGold),
              const SizedBox(width: 12),
              Text(label),
              const Spacer(),
              Icon(Icons.arrow_outward,
                  size: 16, color: warmText.withValues(alpha: 0.5)),
            ],
          ),
        ),
      );
    }

    return _card(
      title: 'Quick access',
      child: Column(
        children: [
          tile(Icons.auto_awesome, 'Recover a dream',
              () => _go(const DreamRecoveryScreen())),
          tile(Icons.insights, 'See your patterns',
              () => _go(const PatternAnalysisScreen())),
          tile(Icons.search, 'Search dreams',
              () => _go(const SearchScreen())),
          tile(Icons.bubble_chart, 'Explore your universe',
              () => _go(const DreamUniverseScreen())),
        ],
      ),
    );
  }
}