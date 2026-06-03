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

        // ── Emotions table ──
        Text('Most common emotions',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (topEmotions.isEmpty)
          const Text('No emotions tagged yet.')
        else
          DataTable(
            headingRowColor: WidgetStateProperty.all(
                starGold.withValues(alpha: 0.12)),
            columns: const [
              DataColumn(label: Text('Emotion')),
              DataColumn(label: Text('Times'), numeric: true),
            ],
            rows: topEmotions.map((e) {
              final m = e as Map;
              return DataRow(cells: [
                DataCell(Text(m['emotion']?.toString() ?? '')),
                DataCell(Text('${m['count']}')),
              ]);
            }).toList(),
          ),

        const SizedBox(height: 32),

        // ── Recurring elements table ──
        Text('Recurring elements',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(
            color: warmText.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            1: FlexColumnWidth(),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            _recurRow('People', people),
            _recurRow('Places', locations),
            _recurRow('Symbols & themes', symbols),
          ],
        ),
      ],
    );
  }

  TableRow _recurRow(String category, List<String> items) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(category,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(items.isEmpty ? '—' : items.join(', ')),
        ),
      ],
    );
  }
}