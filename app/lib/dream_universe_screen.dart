import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart';

class _Node {
  final String label;
  final Color color;
  final double weight;
  _Node(this.label, this.color, this.weight);
}

class DreamUniverseScreen extends StatefulWidget {
  const DreamUniverseScreen({super.key});

  @override
  State<DreamUniverseScreen> createState() => _DreamUniverseScreenState();
}

class _DreamUniverseScreenState extends State<DreamUniverseScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _result;

  static const _peopleColor = softViolet;
  static const _placeColor = Color(0xFF7FC8C0);
  static const _symbolColor = starGold;
  static const _emotionColor = Color(0xFFE89BB0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<_Node> _buildNodes() {
    final r = _result!;
    final nodes = <_Node>[];
    for (final e in ((r['topEmotions'] as List?) ?? []).take(4)) {
      final m = e as Map;
      nodes.add(_Node(m['emotion']?.toString() ?? '', _emotionColor,
          (m['count'] as num?)?.toDouble() ?? 1));
    }
    for (final p in ((r['people'] as List?)?.cast<String>() ?? []).take(4)) {
      nodes.add(_Node(p, _peopleColor, 1));
    }
    for (final p in ((r['locations'] as List?)?.cast<String>() ?? []).take(4)) {
      nodes.add(_Node(p, _placeColor, 1));
    }
    for (final s in ((r['symbols'] as List?)?.cast<String>() ?? []).take(4)) {
      nodes.add(_Node(s, _symbolColor, 1));
    }
    return nodes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dream Universe'),
        actions: [
          IconButton(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mapping your dream universe…'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Could not load: $_error',
                        textAlign: TextAlign.center),
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final count = _result!['dreamCount'] as int? ?? 0;
    final nodes = _buildNodes();
    if (count == 0 || nodes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Your universe is still forming.\nCapture a few dreams with emotions and details, then return.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'The people, places, symbols and feelings woven through your $count dreams.',
            textAlign: TextAlign.center,
            style: TextStyle(color: warmText.withValues(alpha: 0.7)),
          ),
        ),
        Expanded(child: _constellation(nodes)),
        _legend(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _constellation(List<_Node> nodes) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final center = Offset(w / 2, h / 2);
        final radius = (min(w, h) / 2) - 70;
        final positions = <Offset>[];
        for (int i = 0; i < nodes.length; i++) {
          final angle = (2 * pi * i / nodes.length) - pi / 2;
          positions.add(Offset(
            center.dx + radius * cos(angle),
            center.dy + radius * sin(angle),
          ));
        }
        return Stack(
          children: [
            CustomPaint(
              size: Size(w, h),
              painter: _LinesPainter(center, positions),
            ),
            Positioned(
              left: center.dx - 34,
              top: center.dy - 34,
              child: _centerNode(),
            ),
            for (int i = 0; i < nodes.length; i++)
              Positioned(
                left: (positions[i].dx - 50).clamp(0.0, w - 100),
                top: positions[i].dy - 18,
                child: SizedBox(
                    width: 100, child: Center(child: _nodeChip(nodes[i]))),
              ),
          ],
        );
      },
    );
  }

  Widget _centerNode() {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(colors: [starGold, Color(0xFFB5832F)]),
        boxShadow: [
          BoxShadow(
              color: starGold.withValues(alpha: 0.5),
              blurRadius: 24,
              spreadRadius: 2),
        ],
      ),
      child: const Icon(Icons.nightlight_round, color: onGold, size: 30),
    );
  }

  Widget _nodeChip(_Node node) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: node.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: node.color.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(color: node.color.withValues(alpha: 0.25), blurRadius: 10),
        ],
      ),
      child: Text(node.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: node.color, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }

  Widget _legend() {
    Widget dot(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        dot(_emotionColor, 'Emotions'),
        dot(_peopleColor, 'People'),
        dot(_placeColor, 'Places'),
        dot(_symbolColor, 'Symbols'),
      ],
    );
  }
}

class _LinesPainter extends CustomPainter {
  final Offset center;
  final List<Offset> positions;
  _LinesPainter(this.center, this.positions);

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFFF2ECE0).withValues(alpha: 0.12)
      ..strokeWidth = 1;
    final dot = Paint()
      ..color = const Color(0xFFF2ECE0).withValues(alpha: 0.25);
    for (final p in positions) {
      canvas.drawLine(center, p, line);
      canvas.drawCircle(p, 2, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _LinesPainter old) =>
      old.center != center || old.positions != positions;
}