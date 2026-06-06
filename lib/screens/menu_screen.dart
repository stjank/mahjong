import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/game_state.dart';
import '../layouts/layouts.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B4332),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '麻將',
                  style: TextStyle(
                    fontSize: 72,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'MAHJONG SOLITAIRE',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 32),
                const _LayoutPicker(),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        context.read<GameState>().initGame();
                        Navigator.pushNamed(context, '/game');
                      },
                      child: const Text('New Game'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amber,
                        side: const BorderSide(color: Colors.amber),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/hof'),
                      child: const Icon(Icons.emoji_events),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _RulesPanel(),
                const SizedBox(height: 24),
                const Text(
                  'Tile artwork by Code Inferno (codeinferno.com)\nCC BY 3.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 8),
                const _VersionLabel(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Layout picker ─────────────────────────────────────────────────────────────

class _LayoutPicker extends StatelessWidget {
  const _LayoutPicker();

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 24, bottom: 10),
          child: Text(
            'LAYOUT',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: allLayouts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final layout = allLayouts[i];
              final selected = layout.id == gameState.layout.id;
              return GestureDetector(
                onTap: () => gameState.selectLayout(layout),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 140,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.amber.withAlpha(40)
                        : Colors.black26,
                    border: Border.all(
                      color: selected ? Colors.amber : Colors.white24,
                      width: selected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        layout.name,
                        style: TextStyle(
                          color: selected ? Colors.amber : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        layout.description,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Rules panel ───────────────────────────────────────────────────────────────

class _RulesPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: Colors.white70, fontSize: 14, height: 1.6);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW TO PLAY',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 10),
          Text('• Tap a free tile, then tap a matching free tile to remove the pair.', style: style),
          Text('• A tile is FREE if nothing is stacked on top of it,\n  and it has an open left OR right side.', style: style),
          Text('• Characters, Bamboo and Circles match by number.', style: style),
          Text('• Winds and Dragons match their own type.', style: style),
          Text('• Any two Flower tiles match. Any two Season tiles match.', style: style),
          Text('• Clear all tiles to win!', style: style),
        ],
      ),
    );
  }
}

// ── Version label ─────────────────────────────────────────────────────────────

class _VersionLabel extends StatefulWidget {
  const _VersionLabel();

  @override
  State<_VersionLabel> createState() => _VersionLabelState();
}

class _VersionLabelState extends State<_VersionLabel> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = 'v${info.version}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _version,
      style: const TextStyle(color: Colors.white24, fontSize: 11),
    );
  }
}
