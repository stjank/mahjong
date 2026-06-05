import 'dart:math';
import 'package:flutter/foundation.dart';
import 'tile.dart';
import 'tile_type.dart';

/// Immutable record of a removed pair (for undo).
class _RemovedPair {
  final Tile first;
  final Tile second;
  const _RemovedPair(this.first, this.second);
}

class GameState extends ChangeNotifier {
  List<Tile> _tiles = [];
  int? _selectedTileId;
  int _score = 0;
  bool _gameOver = false;
  bool _gameWon = false;
  List<int> _hintIds = [];

  final _undoStack = <_RemovedPair>[];
  final _random = Random();

  // ── Public read-only getters ──────────────────────────────────────────────

  List<Tile> get tiles => _tiles;
  int? get selectedTileId => _selectedTileId;
  int get score => _score;
  bool get gameOver => _gameOver;
  bool get gameWon => _gameWon;
  List<int> get hintIds => _hintIds;

  int get tilesRemaining => _tiles.where((t) => !t.removed).length;

  bool get hasMovesAvailable => _findMatchingPair() != null;

  // ── Layout definition ─────────────────────────────────────────────────────

  /// Returns the list of all (x, y, layer) positions for the Portrait Pyramid.
  /// Total: 72 + 36 + 20 + 12 + 4 = 144 tiles.
  /// The layout is taller than wide (8 cols × 9 rows base) to suit portrait screens.
  static List<(int x, int y, int layer)> _buildLayout() {
    final positions = <(int, int, int)>[];

    // Layer 0: x in {0,2,...,14} (8 values), y in {0,2,...,16} (9 values) → 72
    for (int x = 0; x <= 14; x += 2) {
      for (int y = 0; y <= 16; y += 2) {
        positions.add((x, y, 0));
      }
    }
    assert(
      positions.where((p) => p.$3 == 0).length == 72,
      'Layer 0 should have 72 tiles',
    );

    // Layer 1: x in {2,4,...,12} (6 values), y in {2,4,...,12} (6 values) → 36
    for (int x = 2; x <= 12; x += 2) {
      for (int y = 2; y <= 12; y += 2) {
        positions.add((x, y, 1));
      }
    }
    assert(
      positions.where((p) => p.$3 == 1).length == 36,
      'Layer 1 should have 36 tiles',
    );

    // Layer 2: x in {4,6,8,10} (4 values), y in {4,6,8,10,12} (5 values) → 20
    for (int x = 4; x <= 10; x += 2) {
      for (int y = 4; y <= 12; y += 2) {
        positions.add((x, y, 2));
      }
    }
    assert(
      positions.where((p) => p.$3 == 2).length == 20,
      'Layer 2 should have 20 tiles',
    );

    // Layer 3: x in {4,6,8,10} (4 values), y in {6,8,10} (3 values) → 12
    for (int x = 4; x <= 10; x += 2) {
      for (int y = 6; y <= 10; y += 2) {
        positions.add((x, y, 3));
      }
    }
    assert(
      positions.where((p) => p.$3 == 3).length == 12,
      'Layer 3 should have 12 tiles',
    );

    // Layer 4: x in {6,8} (2 values), y in {6,8} (2 values) → 4
    for (int x = 6; x <= 8; x += 2) {
      for (int y = 6; y <= 8; y += 2) {
        positions.add((x, y, 4));
      }
    }
    assert(
      positions.where((p) => p.$3 == 4).length == 4,
      'Layer 4 should have 4 tiles',
    );

    assert(positions.length == 144, 'Layout must have 144 positions, got ${positions.length}');
    return positions;
  }

  // ── Game initialization ───────────────────────────────────────────────────

  void initGame() {
    _undoStack.clear();
    _selectedTileId = null;
    _score = 0;
    _gameOver = false;
    _gameWon = false;
    _hintIds = [];

    final positions = _buildLayout();

    // Shuffle positions
    final shuffledPositions = List.of(positions)..shuffle(_random);

    // Build tile bag and shuffle
    final tileBag = buildTileBag()..shuffle(_random);

    assert(
      shuffledPositions.length == tileBag.length,
      'Position count (${shuffledPositions.length}) must equal tile bag size (${tileBag.length})',
    );

    _tiles = List.generate(144, (i) {
      final pos = shuffledPositions[i];
      return Tile(
        id: i,
        type: tileBag[i],
        x: pos.$1,
        y: pos.$2,
        layer: pos.$3,
      );
    });

    notifyListeners();
  }

  void resetGame() => initGame();

  // ── Tile selection ────────────────────────────────────────────────────────

  void selectTile(int id) {
    _hintIds = [];

    final tapped = _tileById(id);
    if (tapped == null || tapped.removed) return;
    if (!tapped.isFree(_tiles)) return;

    if (_selectedTileId == null) {
      // Nothing selected yet — select this tile
      _setSelected(id, true);
      _selectedTileId = id;
    } else if (_selectedTileId == id) {
      // Tapped the already-selected tile — deselect
      _setSelected(id, false);
      _selectedTileId = null;
    } else {
      final first = _tileById(_selectedTileId!)!;
      if (tilesMatch(first.type, tapped.type)) {
        // Match! Remove both tiles.
        _undoStack.add(_RemovedPair(
          first.copyWith(),
          tapped.copyWith(),
        ));
        _setRemoved(first.id);
        _setRemoved(tapped.id);
        _selectedTileId = null;
        _score += 10;

        // Check win condition
        if (_tiles.every((t) => t.removed)) {
          _gameWon = true;
          _gameOver = true;
        } else if (!hasMovesAvailable) {
          // No remaining moves — game over (player can shuffle though)
          _gameOver = true;
        }
      } else {
        // No match — deselect first, select new tile
        _setSelected(first.id, false);
        _setSelected(id, true);
        _selectedTileId = id;
      }
    }

    notifyListeners();
  }

  // ── Undo ──────────────────────────────────────────────────────────────────

  void undoLastMove() {
    if (_undoStack.isEmpty) return;
    _hintIds = [];

    final pair = _undoStack.removeLast();

    // Deselect any current selection
    if (_selectedTileId != null) {
      _setSelected(_selectedTileId!, false);
      _selectedTileId = null;
    }

    // Restore the two tiles
    for (int i = 0; i < _tiles.length; i++) {
      if (_tiles[i].id == pair.first.id) {
        _tiles[i] = _tiles[i].copyWith(removed: false, selected: false);
      } else if (_tiles[i].id == pair.second.id) {
        _tiles[i] = _tiles[i].copyWith(removed: false, selected: false);
      }
    }

    _score = (_score - 10).clamp(0, 999999);
    _gameOver = false;
    _gameWon = false;

    notifyListeners();
  }

  bool get canUndo => _undoStack.isNotEmpty;

  // ── Hint ─────────────────────────────────────────────────────────────────

  void showHint() {
    final pair = _findMatchingPair();
    if (pair != null) {
      _hintIds = [pair.$1.id, pair.$2.id];
    } else {
      _hintIds = [];
    }
    notifyListeners();
  }

  void clearHint() {
    _hintIds = [];
    notifyListeners();
  }

  // ── Shuffle remaining free tiles ─────────────────────────────────────────

  void shuffleFreeTiles() {
    _hintIds = [];

    final freeTiles = _tiles.where((t) => !t.removed && t.isFree(_tiles)).toList();
    if (freeTiles.length < 2) return;

    // Collect their types, shuffle them, reassign
    final types = freeTiles.map((t) => t.type).toList()..shuffle(_random);

    for (int i = 0; i < _tiles.length; i++) {
      final idx = freeTiles.indexWhere((ft) => ft.id == _tiles[i].id);
      if (idx >= 0) {
        _tiles[i] = _tiles[i].copyWith(type: types[idx], selected: false);
      }
    }

    _selectedTileId = null;
    _gameOver = false;

    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Tile? _tileById(int id) {
    try {
      return _tiles.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  void _setSelected(int id, bool value) {
    for (int i = 0; i < _tiles.length; i++) {
      if (_tiles[i].id == id) {
        _tiles[i] = _tiles[i].copyWith(selected: value);
        return;
      }
    }
  }

  void _setRemoved(int id) {
    for (int i = 0; i < _tiles.length; i++) {
      if (_tiles[i].id == id) {
        _tiles[i] = _tiles[i].copyWith(removed: true, selected: false);
        return;
      }
    }
  }

  /// Finds the first pair of free matching tiles, or null if none exist.
  (Tile, Tile)? _findMatchingPair() {
    final free = _tiles.where((t) => !t.removed && t.isFree(_tiles)).toList();
    for (int i = 0; i < free.length; i++) {
      for (int j = i + 1; j < free.length; j++) {
        if (tilesMatch(free[i].type, free[j].type)) {
          return (free[i], free[j]);
        }
      }
    }
    return null;
  }
}
