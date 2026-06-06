import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/tile.dart';

// ── Configuration constants ───────────────────────────────────────────────────

const double kTileW = 52.0;
const double kTileH = 68.0;
const double kTileGapX = 4.0;  // horizontal gap between adjacent tiles
const double kTileGapY = 4.0;  // vertical gap between adjacent tiles
const double kLayerOffsetX = 0.0; // no horizontal shift — layers align vertically
const double kLayerOffsetY = 8.0; // px shift up per layer (stacking illusion)
const double kBoardPadding = 24.0;

/// Computes the canvas size needed for [positions] given the current tile constants.
Size layoutBoardSize(List<(int x, int y, int layer)> positions) {
  if (positions.isEmpty) return const Size(300, 400);
  int maxX = 0, maxY = 0, maxLayer = 0;
  for (final p in positions) {
    if (p.$1 > maxX) maxX = p.$1;
    if (p.$2 > maxY) maxY = p.$2;
    if (p.$3 > maxLayer) maxLayer = p.$3;
  }
  final w = (maxX + 2) * ((kTileW + kTileGapX) / 2) + kBoardPadding * 2;
  final h = (maxY + 2) * ((kTileH + kTileGapY) / 2) + kBoardPadding * 2
      + maxLayer * kLayerOffsetY;
  return Size(w, h);
}

// ── Coordinate helper ─────────────────────────────────────────────────────────

Offset tileOrigin(Tile tile) {
  final px = tile.x * ((kTileW + kTileGapX) / 2) - tile.layer * kLayerOffsetX + kBoardPadding;
  final py = tile.y * ((kTileH + kTileGapY) / 2) - tile.layer * kLayerOffsetY + kBoardPadding;
  return Offset(px, py);
}

// ── BoardWidget ───────────────────────────────────────────────────────────────

class BoardWidget extends StatelessWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final tiles = gameState.tiles;
    final boardSize = layoutBoardSize(gameState.layout.positions);

    // Sort tiles back-to-front so higher layers render on top of lower ones.
    final sorted = tiles.where((t) => !t.removed).toList()
      ..sort((a, b) =>
          a.layer != b.layer ? a.layer.compareTo(b.layer) : a.y.compareTo(b.y));

    final tileWidgets = sorted.map((tile) {
      final origin = tileOrigin(tile);
      return Positioned(
        key: ValueKey(tile.id),
        left: origin.dx,
        top: origin.dy,
        width: kTileW,
        height: kTileH,
        child: _TileImage(
          imageName: tile.type.imageName,
          isFree: tile.isFree(tiles),
          isSelected: tile.id == gameState.selectedTileId,
          isHint: gameState.hintIds.contains(tile.id),
        ),
      );
    }).toList();

    // FittedBox scales the board to fill the available space while keeping it
    // fixed in place — no InteractiveViewer means no accidental panning.
    // Tap coordinates inside GestureDetector are automatically in board space.
    return FittedBox(
      fit: BoxFit.contain,
      child: GestureDetector(
        onTapUp: (details) => _handleTap(details.localPosition, tiles, gameState),
        child: SizedBox(
          width: boardSize.width,
          height: boardSize.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: tileWidgets,
          ),
        ),
      ),
    );
  }

  void _handleTap(Offset pos, List<Tile> tiles, GameState gameState) {
    Tile? found;
    int foundLayer = -1;
    for (final tile in tiles) {
      if (tile.removed) continue;
      final origin = tileOrigin(tile);
      final rect = Rect.fromLTWH(origin.dx, origin.dy, kTileW, kTileH);
      if (rect.contains(pos) && tile.layer > foundLayer) {
        found = tile;
        foundLayer = tile.layer;
      }
    }
    if (found != null) gameState.selectTile(found.id);
  }
}

// ── Tile image widget ─────────────────────────────────────────────────────────

const _greyscaleMatrix = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, -20,
  0.2126, 0.7152, 0.0722, 0, -20,
  0.2126, 0.7152, 0.0722, 0, -20,
  0,      0,      0,      1,   0,
]);

class _TileImage extends StatelessWidget {
  final String imageName;
  final bool isFree;
  final bool isSelected;
  final bool isHint;

  const _TileImage({
    required this.imageName,
    required this.isFree,
    required this.isSelected,
    required this.isHint,
  });

  @override
  Widget build(BuildContext context) {
    Widget img = Image.asset(
      'assets/tiles/$imageName.png',
      fit: BoxFit.fill,
      gaplessPlayback: true,
    );

    // Blocked → greyscale + darkened
    if (!isFree) {
      img = ColorFiltered(colorFilter: _greyscaleMatrix, child: img);
    }

    // Selected or hinted → coloured border
    if (isSelected || isHint) {
      img = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF0277BD) : const Color(0xFFF9A825),
            width: 3,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: img,
      );
    }

    return img;
  }
}
