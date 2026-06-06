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

// Board bounding box: layer 0 reaches x=14 (→ extent 16) and y=16 (→ extent 18)
const double kBoardWidth  = 16 * ((kTileW + kTileGapX) / 2) + kBoardPadding * 2 + 5 * kLayerOffsetX;
const double kBoardHeight = 18 * ((kTileH + kTileGapY) / 2) + kBoardPadding * 2 + 5 * kLayerOffsetY;

// ── Coordinate helper ─────────────────────────────────────────────────────────

Offset tileOrigin(Tile tile) {
  final px = tile.x * ((kTileW + kTileGapX) / 2) - tile.layer * kLayerOffsetX + kBoardPadding;
  final py = tile.y * ((kTileH + kTileGapY) / 2) - tile.layer * kLayerOffsetY + kBoardPadding;
  return Offset(px, py);
}

// ── BoardWidget ───────────────────────────────────────────────────────────────

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

  void _fitBoard(Size viewport) {
    if (viewport == _lastViewport) return;
    _lastViewport = viewport;

    final scale = (viewport.width / kBoardWidth).clamp(0.3, 1.0);
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

        // Sort tiles back-to-front so higher layers paint over lower ones.
        final sorted = tiles.where((t) => !t.removed).toList()
          ..sort((a, b) =>
              a.layer != b.layer ? a.layer.compareTo(b.layer) : a.y.compareTo(b.y));

        final tileWidgets = sorted.map((tile) {
          final origin = tileOrigin(tile);
          final isFree = tile.isFree(tiles);
          final isSelected = tile.id == gameState.selectedTileId;
          final isHint = gameState.hintIds.contains(tile.id);

          return Positioned(
            key: ValueKey(tile.id),
            left: origin.dx,
            top: origin.dy,
            width: kTileW,
            height: kTileH,
            child: _TileImage(
              imageName: tile.type.imageName,
              isFree: isFree,
              isSelected: isSelected,
              isHint: isHint,
            ),
          );
        }).toList();

        return InteractiveViewer(
          transformationController: _transform,
          minScale: 0.3,
          maxScale: 3.0,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(40),
          child: GestureDetector(
            onTapUp: (details) => _handleTap(details.localPosition, tiles, gameState),
            child: SizedBox(
              width: kBoardWidth,
              height: kBoardHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: tileWidgets,
              ),
            ),
          ),
        );
      },
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
