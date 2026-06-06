import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/game_state.dart';
import '../services/hall_of_fame.dart';
import '../widgets/board_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _winDialogShown = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gs = context.read<GameState>();
    if (!gs.gameWon) _winDialogShown = false;
  }

  Future<void> _maybeShowWinDialog(GameState gameState) async {
    if (!gameState.gameWon || _winDialogShown) return;
    _winDialogShown = true;

    // Record to hall of fame and find rank
    final hof = context.read<HallOfFame>();
    final rank = await hof.addEntry(
      gameState.layout.id,
      gameState.elapsed.inSeconds,
    );

    if (!mounted) return;

    final timeStr = _formatDuration(gameState.elapsed);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1B4332),
          title: const Text(
            'You Win! 🎉',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              if (rank != null)
                Text(
                  rank == 1
                      ? '🥇 New record!'
                      : rank == 2
                          ? '🥈 Rank #$rank'
                          : rank == 3
                              ? '🥉 Rank #$rank'
                              : 'Rank #$rank',
                  style: TextStyle(
                    color: rank == 1 ? Colors.amber : Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 4),
              Text(
                'Score: ${gameState.score}',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/hof');
              },
              child: const Text('Records'),
            ),
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
                const Icon(Icons.grid_on, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${gameState.score}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                _TimerDisplay(gameState: gameState),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Undo',
                onPressed:
                    gameState.canUndo ? () => gameState.undoLastMove() : null,
              ),
              IconButton(
                icon: Icon(
                  Icons.lightbulb_outline,
                  color:
                      gameState.hintIds.isNotEmpty ? Colors.amber : null,
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
              IconButton(
                icon: const Icon(Icons.shuffle),
                tooltip: 'Shuffle (+10s)',
                onPressed: gameState.gameWon
                    ? null
                    : () => gameState.shuffleFreeTiles(),
              ),
              IconButton(
                icon: const Icon(Icons.home),
                tooltip: 'Menu',
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/', (_) => false);
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: gameState.tiles.isEmpty
                    ? const Center(
                        child: Text('Loading…',
                            style: TextStyle(color: Colors.white)))
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

// ── Timer display (ticks independently, doesn't rebuild the board) ─────────

class _TimerDisplay extends StatefulWidget {
  final GameState gameState;
  const _TimerDisplay({required this.gameState});

  @override
  State<_TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<_TimerDisplay> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !widget.gameState.gameWon) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(widget.gameState.elapsed),
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 16,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

String _formatDuration(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final GameState gameState;
  const _BottomBar({required this.gameState});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final remaining = gameState.tilesRemaining;
    final noMoves =
        !gameState.gameWon && !gameState.hasMovesAvailable && remaining > 0;

    return Container(
      color: const Color(0xFF0D2818),
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomInset),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$remaining tiles remaining',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (noMoves)
            const Text(
              'No moves — tap shuffle',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            ),
        ],
      ),
    );
  }
}
