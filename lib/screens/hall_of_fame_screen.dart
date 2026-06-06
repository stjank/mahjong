import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/hall_of_fame.dart';
import '../layouts/layouts.dart';

class HallOfFameScreen extends StatelessWidget {
  const HallOfFameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hof = context.watch<HallOfFame>();

    return Scaffold(
      backgroundColor: const Color(0xFF1B4332),
      appBar: AppBar(
        title: const Text(
          'Hall of Fame',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: allLayouts.map((layout) {
          final entries = hof.getEntries(layout.id);
          return _LayoutSection(layout: layout, entries: entries);
        }).toList(),
      ),
    );
  }
}

class _LayoutSection extends StatelessWidget {
  final LayoutDef layout;
  final List<HofEntry> entries;

  const _LayoutSection({required this.layout, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              layout.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No records yet',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            )
          else
            ...entries.asMap().entries.map((e) {
              final rank = e.key + 1;
              final entry = e.value;
              return _EntryRow(rank: rank, entry: entry);
            }),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final int rank;
  final HofEntry entry;

  const _EntryRow({required this.rank, required this.entry});

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final medal = rank <= 3 ? _medals[rank - 1] : '   $rank.';
    final time = _formatSeconds(entry.seconds);
    final date = _formatDate(entry.date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              medal,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          Text(
            date,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  static String _formatSeconds(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
