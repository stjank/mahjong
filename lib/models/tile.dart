import 'tile_type.dart';

class Tile {
  final int id;
  final TileType type;
  final int x; // half-unit grid x coordinate
  final int y; // half-unit grid y coordinate
  final int layer;
  bool selected;
  bool removed;

  Tile({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.layer,
    this.selected = false,
    this.removed = false,
  });

  /// A tile occupies columns [x, x+1] and rows [y, y+1] in the half-unit grid.

  /// Returns true if this tile is blocked from above by another tile on the
  /// next layer.  A tile at (x2, y2, layer+1) blocks this tile when
  ///   |x - x2| <= 1  AND  |y - y2| <= 1
  bool _isBlockedFromAbove(List<Tile> allTiles) {
    for (final other in allTiles) {
      if (other.removed) continue;
      if (other.layer != layer + 1) continue;
      if ((x - other.x).abs() <= 1 && (y - other.y).abs() <= 1) {
        return true;
      }
    }
    return false;
  }

  /// Has a left neighbor on the same layer:
  ///   other.x + 2 == this.x  AND  |y - other.y| <= 1
  bool _hasLeftNeighbor(List<Tile> allTiles) {
    for (final other in allTiles) {
      if (other.removed) continue;
      if (other.layer != layer) continue;
      if (other.id == id) continue;
      if (other.x + 2 == x && (y - other.y).abs() <= 1) {
        return true;
      }
    }
    return false;
  }

  /// Has a right neighbor on the same layer:
  ///   other.x - 2 == this.x  AND  |y - other.y| <= 1
  bool _hasRightNeighbor(List<Tile> allTiles) {
    for (final other in allTiles) {
      if (other.removed) continue;
      if (other.layer != layer) continue;
      if (other.id == id) continue;
      if (other.x - 2 == x && (y - other.y).abs() <= 1) {
        return true;
      }
    }
    return false;
  }

  /// A tile is free when it is not blocked from above AND has at least one
  /// open horizontal side (no left neighbour OR no right neighbour).
  bool isFree(List<Tile> allTiles) {
    if (_isBlockedFromAbove(allTiles)) return false;
    final left = _hasLeftNeighbor(allTiles);
    final right = _hasRightNeighbor(allTiles);
    return !left || !right;
  }

  Tile copyWith({
    int? id,
    TileType? type,
    int? x,
    int? y,
    int? layer,
    bool? selected,
    bool? removed,
  }) {
    return Tile(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      layer: layer ?? this.layer,
      selected: selected ?? this.selected,
      removed: removed ?? this.removed,
    );
  }
}
