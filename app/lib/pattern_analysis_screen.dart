import 'package:flutter/material.dart';
import 'main.dart';

class PatternAnalysisScreen extends StatefulWidget {
  const PatternAnalysisScreen({super.key});

  @override
  State<PatternAnalysisScreen> createState() => _PatternAnalysisScreenState();
}

class _PatternAnalysisScreenState extends State<PatternAnalysisScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await supabase.functions.invoke('super-processor');
      setState(() {
        _result = Map<String, dynamic>.from(res.data as Map);
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patterns'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _analyze,
            icon: const Icon(Icons.refresh),
            tooltip: 'Re-analyze',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Looking for patterns in your dreams…'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Could not analyze: $_error',
                        textAlign: TextAlign.center),
                  ),
                )
              : _buildResults(),
    );
  }

  Widget _buildResults() {
    final result = _result!;
    final count = result['dreamCount'] as int? ?? 0;
    final topEmotions = (result['topEmotions'] as List?) ?? [];
    final people = (result['people'] as List?)?.cast<String>() ?? [];
    final locations = (result['locations'] as List?)?.cast<String>() ?? [];
    final symbols = (result['symbols'] as List?)?.cast<String>() ?? [];

    if (count == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Capture a few dreams first, then come back to see your patterns.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Based on $count dream${count == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 24),
        _section(
          'Most common emotions',
          topEmotions.isEmpty
              ? const Text('No emotions tagged yet.')
              : Column(
                  children: topEmotions.map((e) {
                    final m = e as Map;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(m['emotion']?.toString() ?? ''),
                      trailing: Text('${m['count']}×'),
                    );
                  }).toList(),
                ),
        ),
        _section('Recurring people', _chips(people)),
        _section('Recurring places', _chips(locations)),
        _section('Recurring symbols & themes', _chips(symbols)),
      ],
    );
  }

  Widget _chips(List<String> items) {
    if (items.isEmpty) return const Text('Nothing recurring yet.');
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((i) => Chip(label: Text(i))).toList(),
    );
  }

  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 24),
      ],
    );
  }
}