import 'package:flutter/material.dart';
import 'main.dart';
import 'new_dream_screen.dart'; // for kEmotionOptions
import 'dream_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _keywordController = TextEditingController();
  final _tagController = TextEditingController();
  final Set<String> _selectedEmotions = {};
  DateTimeRange? _dateRange;

  bool _loading = false;
  bool _hasSearched = false;
  List<Map<String, dynamic>> _results = [];

  @override
  void dispose() {
    _keywordController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      initialDateRange: _dateRange,
    );
    if (range != null) setState(() => _dateRange = range);
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _hasSearched = true;
    });

    try {
      // Start with the base query, then add only the filters that are set.
      var query = supabase.from('dreams').select();

      final keyword = _keywordController.text.trim();
      if (keyword.isNotEmpty) {
        query = query.or('title.ilike.%$keyword%,content.ilike.%$keyword%');
      }
      if (_selectedEmotions.isNotEmpty) {
        // "overlaps" = dream has ANY of the selected emotions.
        query = query.overlaps('emotions', _selectedEmotions.toList());
      }
      final tag = _tagController.text.trim();
      if (tag.isNotEmpty) {
        query = query.contains('tags', [tag]);
      }
      if (_dateRange != null) {
        final start = DateTime(_dateRange!.start.year,
            _dateRange!.start.month, _dateRange!.start.day);
        final end = DateTime(_dateRange!.end.year, _dateRange!.end.month,
            _dateRange!.end.day, 23, 59, 59);
        query = query
            .gte('created_at', start.toIso8601String())
            .lte('created_at', end.toIso8601String());
      }

      final data = await query.order('created_at', ascending: false);
      setState(() {
        _results = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $error')),
        );
        setState(() => _loading = false);
      }
    }
  }

  void _clear() {
    setState(() {
      _keywordController.clear();
      _tagController.clear();
      _selectedEmotions.clear();
      _dateRange = null;
      _results = [];
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search dreams'),
        actions: [
          TextButton(onPressed: _clear, child: const Text('Clear')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _keywordController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: const InputDecoration(
                    labelText: 'Keyword',
                    hintText: 'Search titles and dream text',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tagController,
                  decoration: const InputDecoration(
                    labelText: 'Theme / tag',
                    hintText: 'e.g. ocean',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Emotions',
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kEmotionOptions.map((emotion) {
                    final selected = _selectedEmotions.contains(emotion);
                    return FilterChip(
                      label: Text(emotion),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _selectedEmotions.add(emotion);
                          } else {
                            _selectedEmotions.remove(emotion);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.date_range),
                        label: Text(_dateRange == null
                            ? 'Any date'
                            : '${_dateRange!.start.day}/${_dateRange!.start.month} – ${_dateRange!.end.day}/${_dateRange!.end.month}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _loading ? null : _search,
                        child: const Text('Search'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? const Center(child: Text('Set filters and tap Search.'))
                    : _results.isEmpty
                        ? const Center(child: Text('No dreams matched.'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _results.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final dream = _results[index];
                              final title =
                                  (dream['title'] as String?)?.trim();
                              final content =
                                  (dream['content'] as String?) ?? '';
                              return Card(
                                child: ListTile(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DreamDetailScreen(dream: dream),
                                    ),
                                  ),
                                  title: Text(
                                      (title == null || title.isEmpty)
                                          ? 'Untitled dream'
                                          : title),
                                  subtitle: Text(content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  trailing: const Icon(Icons.chevron_right),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}