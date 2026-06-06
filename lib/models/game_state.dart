import 'dart:math';
import 'package:flutter/foundation.dart';
import 'tile.dart';
import 'tile_type.dart';
import '../layouts/layouts.dart';

/// Immutable record of a removed pair (for undo).
class _RemovedPair {
  final Tile first;
  final Tile second;
  const _RemovedPair(this.first, this.second);
}

class GameState extends ChangeNotifier {
  LayoutDef _layout = allLayouts.first;
  List<Tile> _tiles = [];
  int? _selectedTileId;
  int _score = 0;
  bool _gameOver = false;
  bool _gameWon = false;
  List<int> _hintIds = [];

  final _undoStack = <_RemovedPair>[];
  final _random = Random();

  // ── Public read-only getters ──────────────────────────────────────────────

  LayoutDef get layout => _layout;
  List<Tile> get tiles => _tiles;
  int? get selectedTileId => _selectedTileId;
  int get score => _score;
  bool get gameOver => _gameOver;
  bool get gameWon => _gameWon;
  List<int> get hintIds => _hintIds;

  int get tilesRemaining => _tiles.where((t) => !t.removed).length;

  bool get hasMovesAvailable => _findMatchingPair() != null;

  void selectLayout(LayoutDef layout) {
    _layout = layout;
    notifyListeners();
  }

  // ── Layout definition ─────────────────────────────────────────────────────

  /// Returns the list of all (x, y, layer) positions for the Portrait Pyramid.
  // ── Game initialization ───────────────────────────────────────────────────

  void initGame() {
    _undoStack.clear();
    _selectedTileId = null;
    _score = 0;
    _gameOver = false;
    _gameWon = false;
    _hintIds = [];

    final positions = List.of(_layout.positions)..shuffle(_random);
    final tileBag = buildTileBag(_layout.tileCount)..shuffle(_random);

    assert(positions.length == tileBag.length);

    _tiles = List.generate(positions.length, (i) {
      final pos = positions[i];
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

  // ── Shuffle all remaining tiles ───────────────────────────────────────────

  void shuffleFreeTiles() {
    _hintIds = [];
    _selectedTileId = null;

    // Redistribute types across ALL remaining tiles so buried tiles can surface.
    final remaining = _tiles.where((t) => !t.removed).toList();
    if (remaining.length < 2) return;

    final types = remaining.map((t) => t.type).toList()..shuffle(_random);
    for (int i = 0; i < remaining.length; i++) {
      final idx = _tiles.indexWhere((t) => t.id == remaining[i].id);
      _tiles[idx] = _tiles[idx].copyWith(type: types[i], selected: false);
    }

    // Guarantee at least one free matching pair after the shuffle.
    _ensureFreePair();

    _gameOver = false;
    notifyListeners();
  }

  /// If no free matching pair exists, swap a non-free tile's type with a free
  /// tile so that two free tiles share a matching type. Preserves type counts.
  void _ensureFreePair() {
    if (_findMatchingPair() != null) return;

    final free = _tiles.where((t) => !t.removed && t.isFree(_tiles)).toList();
    if (free.length < 2) return;

    for (final anchor in free) {
      // Find a free tile that doesn't already match anchor.
      final mismatchIdx = _tiles.indexWhere((t) =>
          !t.removed &&
          t.isFree(_tiles) &&
          t.id != anchor.id &&
          !tilesMatch(t.type, anchor.type));
      if (mismatchIdx < 0) continue;

      // Find a non-free tile whose type matches anchor — swap it in.
      final donorIdx = _tiles.indexWhere((t) =>
          !t.removed && !t.isFree(_tiles) && tilesMatch(t.type, anchor.type));
      if (donorIdx < 0) continue;

      final displaced = _tiles[mismatchIdx].type;
      _tiles[mismatchIdx] = _tiles[mismatchIdx].copyWith(type: _tiles[donorIdx].type);
      _tiles[donorIdx] = _tiles[donorIdx].copyWith(type: displaced);
      return;
    }
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
