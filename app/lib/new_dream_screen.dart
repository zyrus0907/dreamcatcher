import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';

const kEmotionOptions = [
  'Happy', 'Peaceful', 'Excited', 'Scared',
  'Anxious', 'Sad', 'Angry', 'Confused', 'Nostalgic',
];

class NewDreamScreen extends StatefulWidget {
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

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  Uint8List? _audioBytes; // a freshly recorded clip waiting to be uploaded

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
    _recorder.dispose();
    super.dispose();
  }

  List<String> _parseTags() {
    return _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _recorder.stop();
        setState(() => _isRecording = false);
        if (path != null) {
          // Fetch the recorded audio's bytes so we can upload them on save.
          final bytes = await http.readBytes(Uri.parse(path));
          setState(() => _audioBytes = bytes);
        }
      } else {
        if (await _recorder.hasPermission()) {
          await _recorder.start(const RecordConfig(encoder: AudioEncoder.opus), path: 'dream_recording');
          setState(() {
            _isRecording = true;
            _audioBytes = null;
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission was denied.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording error: $e')),
        );
        setState(() => _isRecording = false);
      }
    }
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
    final values = <String, dynamic>{
      'title': _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
      'content': content,
      'emotions': _selectedEmotions.toList(),
      'tags': _parseTags(),
    };

    try {
      // If a new recording exists, upload it first, then link its path.
      if (_audioBytes != null) {
        final userId = supabase.auth.currentUser!.id;
        final audioPath =
            '$userId/${DateTime.now().millisecondsSinceEpoch}.webm';
        await supabase.storage.from('recordings').uploadBinary(
              audioPath,
              _audioBytes!,
              fileOptions: const FileOptions(contentType: 'audio/webm'),
            );
        values['audio_path'] = audioPath;
      }

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
    final hasExistingAudio =
        _isEditing && widget.dream?['audio_path'] != null;

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
            maxLines: 6,
            decoration: const InputDecoration(
                hintText: 'What did you dream about?',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          Text('Voice note', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _toggleRecording,
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                label: Text(_isRecording
                    ? 'Stop'
                    : (_audioBytes == null ? 'Record' : 'Re-record')),
              ),
              const SizedBox(width: 12),
              if (_isRecording)
                const Text('Recording…')
              else if (_audioBytes != null)
                const Text('Recording captured ✓')
              else if (hasExistingAudio)
                const Text('Existing recording kept'),
            ],
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