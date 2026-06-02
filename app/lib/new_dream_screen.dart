import 'package:flutter/material.dart';
import 'main.dart';

const kEmotionOptions = [
  'Happy', 'Peaceful', 'Excited', 'Scared',
  'Anxious', 'Sad', 'Angry', 'Confused', 'Nostalgic',
];

class NewDreamScreen extends StatefulWidget {
  // null = creating a new dream; non-null = editing this one.
  final Map<String, dynamic>? dream;
  const NewDreamScreen({super.key, this.dream});

  @override
  State<NewDreamScreen> createState() => _NewDreamScreenState();
}

class _NewDreamScreenState extends State<NewDreamScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;
  late final Set<String> _selectedEmotions;
  bool _saving = false;

  bool get _isEditing => widget.dream != null;

  @override
  void initState() {
    super.initState();
    final dream = widget.dream;
    _titleController =
        TextEditingController(text: dream?['title'] as String? ?? '');
    _contentController =
        TextEditingController(text: dream?['content'] as String? ?? '');
    final tags = (dream?['tags'] as List?)?.cast<String>() ?? [];
    _tagsController = TextEditingController(text: tags.join(', '));
    final emotions = (dream?['emotions'] as List?)?.cast<String>() ?? [];
    _selectedEmotions = emotions.toSet();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  List<String> _parseTags() {
    return _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please write something about your dream.')),
      );
      return;
    }

    setState(() => _saving = true);
    final values = {
      'title': _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
      'content': content,
      'emotions': _selectedEmotions.toList(),
      'tags': _parseTags(),
    };

    try {
      if (_isEditing) {
        await supabase
            .from('dreams')
            .update(values)
            .eq('id', widget.dream!['id']);
      } else {
        await supabase.from('dreams').insert({
          'user_id': supabase.auth.currentUser!.id,
          ...values,
        });
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $error')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit dream' : 'New dream'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
                labelText: 'Title (optional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            autofocus: !_isEditing,
            maxLines: 6,
            decoration: const InputDecoration(
                hintText: 'What did you dream about?',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          Text('How did it feel?',
              style: Theme.of(context).textTheme.titleMedium),
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
          const SizedBox(height: 24),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags (comma separated)',
              hintText: 'e.g. flying, ocean, childhood',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}