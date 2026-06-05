enum TileCategory {
  characters,
  bamboo,
  circles,
  wind,
  dragon,
  flower,
  season,
}

class TileType {
  final TileCategory category;
  final int value; // 1-9 for suits; 1-4 for wind/flower/season; 1-3 for dragon
  final String displayText;

  const TileType({
    required this.category,
    required this.value,
    required this.displayText,
  });

  /// Asset filename (without extension) inside assets/tiles/.
  String get imageName {
    switch (category) {
      case TileCategory.characters:
        return 'pinyin$value';
      case TileCategory.bamboo:
        return 'bamboo$value';
      case TileCategory.circles:
        return 'circle$value';
      case TileCategory.wind:
        return 'pinyin${9 + value}'; // pinyin10–13
      case TileCategory.dragon:
        if (value == 3) return 'tile'; // White Dragon → blank tile image
        return 'pinyin${13 + value}'; // pinyin14–15
      case TileCategory.flower:
        const names = ['peony', 'orchid', 'chrysanthemum', 'lotus'];
        return names[value - 1];
      case TileCategory.season:
        const names = ['spring', 'summer', 'fall', 'winter'];
        return names[value - 1];
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TileType &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          value == other.value;

  @override
  int get hashCode => category.hashCode ^ value.hashCode;

  @override
  String toString() => displayText;
}

/// Returns true if two tile types can be matched together.
bool tilesMatch(TileType a, TileType b) {
  // Flowers cross-match within category
  if (a.category == TileCategory.flower && b.category == TileCategory.flower) {
    return true;
  }
  // Seasons cross-match within category
  if (a.category == TileCategory.season && b.category == TileCategory.season) {
    return true;
  }
  // Otherwise exact match
  return a == b;
}

// ── Characters (萬) ──────────────────────────────────────────────────────────
const _characterLabels = ['一萬', '二萬', '三萬', '四萬', '五萬', '六萬', '七萬', '八萬', '九萬'];

final List<TileType> characterTiles = List.generate(
  9,
  (i) => TileType(
    category: TileCategory.characters,
    value: i + 1,
    displayText: _characterLabels[i],
  ),
);

// ── Bamboo (竹) ──────────────────────────────────────────────────────────────
final List<TileType> bambooTiles = List.generate(
  9,
  (i) => TileType(
    category: TileCategory.bamboo,
    value: i + 1,
    displayText: '${i + 1}竹',
  ),
);

// ── Circles (筒) ─────────────────────────────────────────────────────────────
final List<TileType> circleTiles = List.generate(
  9,
  (i) => TileType(
    category: TileCategory.circles,
    value: i + 1,
    displayText: '${i + 1}○',
  ),
);

// ── Winds ─────────────────────────────────────────────────────────────────────
const _windLabels = ['東', '南', '西', '北'];

final List<TileType> windTiles = List.generate(
  4,
  (i) => TileType(
    category: TileCategory.wind,
    value: i + 1,
    displayText: _windLabels[i],
  ),
);

// ── Dragons ───────────────────────────────────────────────────────────────────
const _dragonLabels = ['中', '發', '白'];

final List<TileType> dragonTiles = List.generate(
  3,
  (i) => TileType(
    category: TileCategory.dragon,
    value: i + 1,
    displayText: _dragonLabels[i],
  ),
);

// ── Flowers ───────────────────────────────────────────────────────────────────
const _flowerLabels = ['梅', '蘭', '菊', '竹'];

final List<TileType> flowerTiles = List.generate(
  4,
  (i) => TileType(
    category: TileCategory.flower,
    value: i + 1,
    displayText: _flowerLabels[i],
  ),
);

// ── Seasons ───────────────────────────────────────────────────────────────────
const _seasonLabels = ['春', '夏', '秋', '冬'];

final List<TileType> seasonTiles = List.generate(
  4,
  (i) => TileType(
    category: TileCategory.season,
    value: i + 1,
    displayText: _seasonLabels[i],
  ),
);

/// Full bag of 144 tile types (with duplicates as per game rules).
///
/// - Characters 1-9 × 4 = 36
/// - Bamboo 1-9 × 4 = 36
/// - Circles 1-9 × 4 = 36
/// - Winds × 4 each = 16
/// - Dragons × 4 each = 12
/// - Flowers × 1 each = 4
/// - Seasons × 1 each = 4
/// Total = 144
List<TileType> buildTileBag() {
  final bag = <TileType>[];

  for (final t in characterTiles) {
    for (int i = 0; i < 4; i++) bag.add(t);
  }
  for (final t in bambooTiles) {
    for (int i = 0; i < 4; i++) bag.add(t);
  }
  for (final t in circleTiles) {
    for (int i = 0; i < 4; i++) bag.add(t);
  }
  for (final t in windTiles) {
    for (int i = 0; i < 4; i++) bag.add(t);
  }
  for (final t in dragonTiles) {
    for (int i = 0; i < 4; i++) bag.add(t);
  }
  for (final t in flowerTiles) {
    bag.add(t); // only 1 copy each
  }
  for (final t in seasonTiles) {
    bag.add(t); // only 1 copy each
  }

  assert(bag.length == 144, 'Tile bag must have 144 tiles, got ${bag.length}');
  return bag;
}
