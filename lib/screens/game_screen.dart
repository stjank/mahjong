import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../widgets/board_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _winDialogShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset dialog tracker when game is reset (tiles reload)
    final gs = context.read<GameState>();
    if (!gs.gameWon) _winDialogShown = false;
  }

  void _maybeShowWinDialog(GameState gameState) {
    if (!gameState.gameWon || _winDialogShown) return;
    _winDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1B4332),
          title: const Text(
            'You Win!',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Congratulations!\nFinal score: ${gameState.score}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(context);
                setState(() => _winDialogShown = false);
                gameState.resetGame();
              },
              child: const Text('Play Again'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
              },
              child: const Text('Main Menu'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        _maybeShowWinDialog(gameState);

        return Scaffold(
          backgroundColor: const Color(0xFF1B4332),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D2818),
            foregroundColor: Colors.white,
            title: Row(
              children: [
                const Icon(Icons.grid_on, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Score: ${gameState.score}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              // Undo button
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Undo',
                onPressed: gameState.canUndo
                    ? () => gameState.undoLastMove()
                    : null,
              ),
              // Hint button
              IconButton(
                icon: Icon(
                  Icons.lightbulb_outline,
                  color: gameState.hintIds.isNotEmpty ? Colors.amber : null,
                ),
                tooltip: 'Hint',
                onPressed: () {
                  if (gameState.hintIds.isNotEmpty) {
                    gameState.clearHint();
                  } else {
                    gameState.showHint();
                  }
                },
              ),
              // Menu button
              IconButton(
                icon: const Icon(Icons.home),
                tooltip: 'Menu',
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: gameState.tiles.isEmpty
                    ? const Center(
                        child: Text(
                          'Loading...',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : const BoardWidget(),
              ),
              _BottomBar(gameState: gameState),
            ],
          ),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  final GameState gameState;
  const _BottomBar({required this.gameState});

  @override
  Widget build(BuildContext context) {
    final remaining = gameState.tilesRemaining;
    final noMoves =
        !gameState.gameWon && !gameState.hasMovesAvailable && remaining > 0;

    return Container(
      color: const Color(0xFF0D2818),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$remaining tiles remaining',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (noMoves)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: const Icon(Icons.shuffle, size: 18),
              label: const Text('No Moves! Shuffle'),
              onPressed: () => gameState.shuffleFreeTiles(),
            ),
        ],
      ),
    );
  }
}
