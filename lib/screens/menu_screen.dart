import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B4332),
      body: SafeArea(
        child: Center(
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
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  context.read<GameState>().initGame();
                  Navigator.pushNamed(context, '/game');
                },
                child: const Text('New Game'),
              ),
              const SizedBox(height: 48),
              _RulesPanel(),
              const SizedBox(height: 24),
              const Text(
                'Tile artwork by Code Inferno (codeinferno.com)\nCC BY 3.0',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
          Text('• Clear all 144 tiles to win!', style: style),
        ],
      ),
    );
  }
}
