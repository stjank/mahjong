import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/tile.dart';
import '../models/tile_type.dart';

// ── Configuration constants ───────────────────────────────────────────────────

const double kTileW = 52.0; // pixel width for one tile (2 half-units)
const double kTileH = 68.0; // pixel height for one tile (2 half-units)
const double kLayerOffsetX = 3.0; // horizontal pixel offset per layer (3D depth)
const double kLayerOffsetY = 3.0; // vertical pixel offset per layer
const double kBoardPadding = 24.0;

// ── Coordinate helpers ────────────────────────────────────────────────────────

/// Convert half-unit grid (x, y, layer) to canvas pixel top-left.
Offset tileOrigin(Tile tile) {
  // Each half-unit = kTileW/2 horizontally, kTileH/2 vertically.
  // A tile at grid (x, y) starts at pixel (x * kTileW/2, y * kTileH/2).
  // Offset by layer for the 3-D stacking effect.
  final px = tile.x * (kTileW / 2) - tile.layer * kLayerOffsetX + kBoardPadding;
  final py = tile.y * (kTileH / 2) - tile.layer * kLayerOffsetY + kBoardPadding;
  return Offset(px, py);
}

// ── BoardWidget ───────────────────────────────────────────────────────────────

// Board bounding box: layer 0 reaches x=14 (→ extent 16) and y=16 (→ extent 18)
const double kBoardWidth = 16 * (kTileW / 2) + kBoardPadding * 2 + 5 * kLayerOffsetX;
const double kBoardHeight = 18 * (kTileH / 2) + kBoardPadding * 2 + 5 * kLayerOffsetY;

class BoardWidget extends StatefulWidget {
  const BoardWidget({super.key});

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  final TransformationController _transform = TransformationController();
  Size _lastViewport = Size.zero;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  /// Scales and centres the board to fill the available viewport on first load
  /// and whenever the viewport size changes (e.g. keyboard appearance).
  void _fitBoard(Size viewport) {
    if (viewport == _lastViewport) return;
    _lastViewport = viewport;

    final scale = (viewport.width / kBoardWidth)
        .clamp(0.3, 1.0);
    final scaledW = kBoardWidth * scale;
    final scaledH = kBoardHeight * scale;
    final tx = (viewport.width - scaledW) / 2;
    final ty = (viewport.height - scaledH) / 2 > 0
        ? (viewport.height - scaledH) / 2
        : 0.0;

    _transform.value = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final tiles = gameState.tiles;

    return LayoutBuilder(
      builder: (context, constraints) {
        _fitBoard(Size(constraints.maxWidth, constraints.maxHeight));

        return InteractiveViewer(
          transformationController: _transform,
          minScale: 0.3,
          maxScale: 3.0,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(40),
          child: GestureDetector(
            onTapUp: (details) {
              _handleTap(details.localPosition, tiles, gameState);
            },
            child: CustomPaint(
              size: const Size(kBoardWidth, kBoardHeight),
              painter: BoardPainter(
                tiles: tiles,
                selectedId: gameState.selectedTileId,
                hintIds: gameState.hintIds,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(Offset pos, List<Tile> tiles, GameState gameState) {
    // Find the topmost non-removed tile whose bounding box contains pos.
    // We iterate from highest layer to lowest so topmost wins.
    Tile? found;
    int foundLayer = -1;

    for (final tile in tiles) {
      if (tile.removed) continue;
      final origin = tileOrigin(tile);
      final rect = Rect.fromLTWH(origin.dx, origin.dy, kTileW, kTileH);
      if (rect.contains(pos)) {
        if (tile.layer > foundLayer) {
          found = tile;
          foundLayer = tile.layer;
        }
      }
    }

    if (found != null) {
      gameState.selectTile(found.id);
    }
  }
}

// ── BoardPainter ──────────────────────────────────────────────────────────────

class BoardPainter extends CustomPainter {
  final List<Tile> tiles;
  final int? selectedId;
  final List<int> hintIds;

  const BoardPainter({
    required this.tiles,
    required this.selectedId,
    required this.hintIds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw tiles layer by layer (back to front), within each layer draw
    // bottom-to-top so tiles higher up visually overlap lower ones.
    final maxLayer = tiles.isEmpty
        ? 0
        : tiles.map((t) => t.layer).reduce((a, b) => a > b ? a : b);

    for (int layer = 0; layer <= maxLayer; layer++) {
      final layerTiles = tiles.where((t) => t.layer == layer && !t.removed).toList();
      // Sort by y descending so lower rows paint first (higher y = bottom of board)
      layerTiles.sort((a, b) => a.y.compareTo(b.y));
      for (final tile in layerTiles) {
        _drawTile(canvas, tile);
      }
    }
  }

  // ── Category colours ──────────────────────────────────────────────────────

  static Color _bgColor(Tile tile, bool isFree, bool isSelected, bool isHint) {
    if (isSelected) return const Color(0xFFB3E5FC); // sky blue
    if (isHint)     return const Color(0xFFFFF59D); // soft yellow
    if (!isFree)    return const Color(0xFFCFD8DC); // muted blue-grey
    switch (tile.type.category) {
      case TileCategory.characters: return const Color(0xFFFFCDD2); // rose
      case TileCategory.bamboo:     return const Color(0xFFC8E6C9); // mint
      case TileCategory.circles:    return const Color(0xFFBBDEFB); // sky
      case TileCategory.wind:       return const Color(0xFFE1BEE7); // lavender
      case TileCategory.dragon:     return const Color(0xFFFFECB3); // amber
      case TileCategory.flower:     return const Color(0xFFF8BBD0); // pink
      case TileCategory.season:     return const Color(0xFFFFCCBC); // peach
    }
  }

  static Color _textColor(Tile tile, bool isFree, bool isSelected) {
    if (isSelected) return const Color(0xFF01579B);
    if (!isFree)    return const Color(0xFF90A4AE); // muted grey
    switch (tile.type.category) {
      case TileCategory.characters: return const Color(0xFFC62828);
      case TileCategory.bamboo:     return const Color(0xFF2E7D32);
      case TileCategory.circles:    return const Color(0xFF1565C0);
      case TileCategory.wind:       return const Color(0xFF6A1B9A);
      case TileCategory.dragon:     return const Color(0xFFE65100);
      case TileCategory.flower:     return const Color(0xFFAD1457);
      case TileCategory.season:     return const Color(0xFFBF360C);
    }
  }

  void _drawTile(Canvas canvas, Tile tile) {
    final origin = tileOrigin(tile);
    final isFree = tile.isFree(tiles);
    final isSelected = tile.id == selectedId;
    final isHint = hintIds.contains(tile.id);

    // ── Soft drop shadow ─────────────────────────────────────────────────
    final shadowPaint = Paint()
      ..color = const Color(0x44000000); // 27% opacity black
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx + 2, origin.dy + 3, kTileW, kTileH),
        const Radius.circular(5),
      ),
      shadowPaint,
    );

    // ── Tile background ───────────────────────────────────────────────────
    final bg = _bgColor(tile, isFree, isSelected, isHint);
    final tileRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(origin.dx, origin.dy, kTileW, kTileH),
      const Radius.circular(5),
    );
    canvas.drawRRect(tileRect, Paint()..color = bg);

    // ── Subtle bevel ─────────────────────────────────────────────────────
    canvas.drawLine(
      Offset(origin.dx + 4, origin.dy + 1),
      Offset(origin.dx + kTileW - 4, origin.dy + 1),
      Paint()..color = Colors.white.withAlpha(160)..strokeWidth = 1.0,
    );
    canvas.drawLine(
      Offset(origin.dx + 1, origin.dy + 4),
      Offset(origin.dx + 1, origin.dy + kTileH - 4),
      Paint()..color = Colors.white.withAlpha(160)..strokeWidth = 1.0,
    );
    canvas.drawLine(
      Offset(origin.dx + 4, origin.dy + kTileH - 1),
      Offset(origin.dx + kTileW - 4, origin.dy + kTileH - 1),
      Paint()..color = Colors.black.withAlpha(40)..strokeWidth = 1.0,
    );

    // ── Selection / hint outline ──────────────────────────────────────────
    if (isSelected || isHint) {
      canvas.drawRRect(
        tileRect,
        Paint()
          ..color = isSelected ? const Color(0xFF0277BD) : const Color(0xFFF9A825)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // ── Tile label ────────────────────────────────────────────────────────
    final label = tile.type.displayText;
    final fontSize = label.length <= 1 ? 22.0 : (label.length == 2 ? 16.0 : 13.0);
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: fontSize,
          color: _textColor(tile, isFree, isSelected),
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(maxWidth: kTileW - 4);
    textPainter.paint(
      canvas,
      Offset(
        origin.dx + (kTileW - textPainter.width) / 2,
        origin.dy + (kTileH - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) =>
      oldDelegate.tiles != tiles ||
      oldDelegate.selectedId != selectedId ||
      oldDelegate.hintIds != hintIds;
}
