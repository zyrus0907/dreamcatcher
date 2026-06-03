import 'package:audioplayers/audioplayers.dart';
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
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _sourceLoaded = false;
  bool _loadingAudio = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _dream = widget.dream;
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _sourceLoaded = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  bool get _isPinned => _dream['pinned'] == true;

  Future<void> _togglePin() async {
    final newVal = !_isPinned;
    try {
      await supabase
          .from('dreams')
          .update({'pinned': newVal}).eq('id', _dream['id']);
      setState(() {
        _dream = {..._dream, 'pinned': newVal};
        _changed = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not update pin: $e')));
      }
    }
  }

  Future<void> _togglePlay() async {
    final path = _dream['audio_path'] as String?;
    if (path == null) return;
    try {
      if (_isPlaying) {
        await _player.pause();
        setState(() => _isPlaying = false);
      } else if (_sourceLoaded) {
        await _player.resume();
        setState(() => _isPlaying = true);
      } else {
        setState(() => _loadingAudio = true);
        final url = await supabase.storage
            .from('recordings')
            .createSignedUrl(path, 3600);
        await _player.play(UrlSource(url));
        setState(() {
          _isPlaying = true;
          _sourceLoaded = true;
          _loadingAudio = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play audio: $e')),
        );
        setState(() {
          _loadingAudio = false;
          _isPlaying = false;
        });
      }
    }
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
        await _player.stop();
        setState(() {
          _dream = Map<String, dynamic>.from(data);
          _isPlaying = false;
          _sourceLoaded = false;
          _changed = true;
        });
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
    final audioPath = _dream['audio_path'] as String?;
    final created =
        DateTime.tryParse(_dream['created_at'] as String? ?? '')?.toLocal();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(_changed),
        ),
        title: Text((title == null || title.isEmpty) ? 'Dream' : title),
        actions: [
          IconButton(
            icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: _isPinned ? starGold : null),
            tooltip: _isPinned ? 'Unpin' : 'Pin',
            onPressed: _togglePin,
          ),
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
          if (audioPath != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadingAudio ? null : _togglePlay,
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              label: Text(_loadingAudio
                  ? 'Loading…'
                  : (_isPlaying ? 'Pause voice note' : 'Play voice note')),
            ),
          ],
          if (emotions.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Emotions', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: emotions.map((e) => Chip(label: Text(e))).toList()),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Tags', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((t) => Chip(label: Text('#$t'))).toList()),
          ],
        ],
      ),
    );
  }
}