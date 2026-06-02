import 'package:flutter/material.dart';
import 'main.dart';
import 'new_dream_screen.dart';

class DreamDetailScreen extends StatefulWidget {
  final Map<String, dynamic> dream;
  const DreamDetailScreen({super.key, required this.dream});

  @override
  State<DreamDetailScreen> createState() => _DreamDetailScreenState();
}

class _DreamDetailScreenState extends State<DreamDetailScreen> {
  late Map<String, dynamic> _dream;

  @override
  void initState() {
    super.initState();
    _dream = widget.dream;
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NewDreamScreen(dream: _dream)),
    );
    if (saved == true) {
      try {
        final data = await supabase
            .from('dreams')
            .select()
            .eq('id', _dream['id'])
            .single();
        setState(() => _dream = Map<String, dynamic>.from(data));
      } catch (_) {
        if (mounted) Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete dream?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await supabase.from('dreams').delete().eq('id', _dream['id']);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (_dream['title'] as String?)?.trim();
    final content = (_dream['content'] as String?) ?? '';
    final emotions = (_dream['emotions'] as List?)?.cast<String>() ?? [];
    final tags = (_dream['tags'] as List?)?.cast<String>() ?? [];
    final created =
        DateTime.tryParse(_dream['created_at'] as String? ?? '')?.toLocal();

    return Scaffold(
      appBar: AppBar(
        title: Text((title == null || title.isEmpty) ? 'Dream' : title),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit), tooltip: 'Edit', onPressed: _edit),
          IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (created != null)
            Text('${created.day}/${created.month}/${created.year}',
                style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Text(content, style: Theme.of(context).textTheme.bodyLarge),
          if (emotions.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Emotions', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    emotions.map((e) => Chip(label: Text(e))).toList()),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Tags', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    tags.map((t) => Chip(label: Text('#$t'))).toList()),
          ],
        ],
      ),
    );
  }
}