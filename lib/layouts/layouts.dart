/// A layout definition: name, description, and the (x, y, layer) positions
/// of every tile in the board (half-unit grid, even coordinates only).
class LayoutDef {
  final String id;
  final String name;
  final String description;
  final List<(int x, int y, int layer)> positions;

  const LayoutDef({
    required this.id,
    required this.name,
    required this.description,
    required this.positions,
  });

  int get tileCount => positions.length;
}

// ── Layout definitions (ordered small → large) ────────────────────────────────

/// Small pyramid — 4 cols wide, narrows over 4 layers. (48 tiles)
final LayoutDef layoutSmallPyramid = LayoutDef(
  id: 'small_pyramid',
  name: 'Small Pyramid',
  description: 'Quick game, compact pyramid\n48 tiles · 4 layers',
  positions: _build(() {
    final p = <(int, int, int)>[];
    // L0: 4×5=20
    for (int x = 0; x <= 6; x += 2) {
      for (int y = 0; y <= 8; y += 2) p.add((x, y, 0));
    }
    // L1: 4×4=16
    for (int x = 0; x <= 6; x += 2) {
      for (int y = 0; y <= 6; y += 2) p.add((x, y, 1));
    }
    // L2: 2×4=8
    for (int x = 2; x <= 4; x += 2) {
      for (int y = 0; y <= 6; y += 2) p.add((x, y, 2));
    }
    // L3: 2×2=4
    for (int x = 2; x <= 4; x += 2) {
      for (int y = 2; y <= 4; y += 2) p.add((x, y, 3));
    }
    assert(p.length == 48, 'SmallPyramid: expected 48, got ${p.length}');
    return p;
  }),
);

/// Small cross — 2-wide vertical bar with side arms, rising peak. (48 tiles)
final LayoutDef layoutSmallCross = LayoutDef(
  id: 'small_cross',
  name: 'Small Cross',
  description: 'Quick game, cross shape\n48 tiles · 4 layers',
  positions: _build(() {
    final p = <(int, int, int)>[];
    // L0 (24): vertical bar + side arms
    for (int x = 2; x <= 4; x += 2) {      // vertical: 2×8=16
      for (int y = 0; y <= 14; y += 2) p.add((x, y, 0));
    }
    for (int y = 4; y <= 10; y += 2) {     // left arm: 1×4=4
      p.add((0, y, 0));
    }
    for (int y = 4; y <= 10; y += 2) {     // right arm: 1×4=4
      p.add((6, y, 0));
    }
    // L1 (12): x∈{2,4} × y∈{2..12}
    for (int x = 2; x <= 4; x += 2) {
      for (int y = 2; y <= 12; y += 2) p.add((x, y, 1));
    }
    // L2 (8): x∈{2,4} × y∈{4..10}
    for (int x = 2; x <= 4; x += 2) {
      for (int y = 4; y <= 10; y += 2) p.add((x, y, 2));
    }
    // L3 (4): x∈{2,4} × y∈{6,8}
    for (int x = 2; x <= 4; x += 2) {
      for (int y = 6; y <= 8; y += 2) p.add((x, y, 3));
    }
    assert(p.length == 48, 'SmallCross: expected 48, got ${p.length}');
    return p;
  }),
);

/// Tall portrait pyramid — 8 cols × 9 rows base, 5 layers. (144 tiles)
final LayoutDef layoutPortraitPyramid = LayoutDef(
  id: 'portrait_pyramid',
  name: 'Pyramid',
  description: 'Classic tall pyramid\n144 tiles · 5 layers',
  positions: _build(() {
    final p = <(int, int, int)>[];
    for (int x = 0; x <= 14; x += 2) {
      for (int y = 0; y <= 16; y += 2) p.add((x, y, 0));
    }
    for (int x = 2; x <= 12; x += 2) {
      for (int y = 2; y <= 12; y += 2) p.add((x, y, 1));
    }
    for (int x = 4; x <= 10; x += 2) {
      for (int y = 4; y <= 12; y += 2) p.add((x, y, 2));
    }
    for (int x = 4; x <= 10; x += 2) {
      for (int y = 6; y <= 10; y += 2) p.add((x, y, 3));
    }
    for (int x = 6; x <= 8; x += 2) {
      for (int y = 6; y <= 8; y += 2) p.add((x, y, 4));
    }
    assert(p.length == 144);
    return p;
  }),
);

/// Twin Towers — two identical 4-wide pyramids side by side. (144 tiles)
final LayoutDef layoutTwinTowers = LayoutDef(
  id: 'twin_towers',
  name: 'Twin Towers',
  description: 'Two side-by-side pyramids\n144 tiles · 4 layers',
  positions: _build(() {
    final p = <(int, int, int)>[];
    for (final xOff in [0, 10]) {
      for (int x = xOff; x <= xOff + 6; x += 2) {
        for (int y = 0; y <= 10; y += 2) p.add((x, y, 0));
      }
      for (int x = xOff; x <= xOff + 6; x += 2) {
        for (int y = 0; y <= 10; y += 2) p.add((x, y, 1));
      }
      for (int x = xOff; x <= xOff + 6; x += 2) {
        for (int y = 2; y <= 8; y += 2) p.add((x, y, 2));
      }
      for (int x = xOff + 2; x <= xOff + 4; x += 2) {
        for (int y = 2; y <= 8; y += 2) p.add((x, y, 3));
      }
    }
    assert(p.length == 144);
    return p;
  }),
);

/// Cross — vertical bar with horizontal arms, stacked to a peak. (144 tiles)
final LayoutDef layoutCross = LayoutDef(
  id: 'cross',
  name: 'Cross',
  description: 'Cross with rising center\n144 tiles · 5 layers',
  positions: _build(() {
    final p = <(int, int, int)>[];
    for (int x = 4; x <= 10; x += 2) {
      for (int y = 0; y <= 20; y += 2) p.add((x, y, 0));
    }
    for (int x = 0; x <= 2; x += 2) {
      for (int y = 6; y <= 12; y += 2) p.add((x, y, 0));
    }
    for (int x = 12; x <= 14; x += 2) {
      for (int y = 6; y <= 12; y += 2) p.add((x, y, 0));
    }
    for (int x = 4; x <= 10; x += 2) {
      for (int y = 2; y <= 18; y += 2) p.add((x, y, 1));
    }
    for (int x = 4; x <= 10; x += 2) {
      for (int y = 4; y <= 16; y += 2) p.add((x, y, 2));
    }
    for (int x = 4; x <= 10; x += 2) {
      for (int y = 6; y <= 12; y += 2) p.add((x, y, 3));
    }
    for (int x = 6; x <= 8; x += 2) {
      for (int y = 8; y <= 10; y += 2) p.add((x, y, 4));
    }
    assert(p.length == 144, 'Cross: expected 144, got ${p.length}');
    return p;
  }),
);

/// All layouts ordered small → large by tile count.
final List<LayoutDef> allLayouts = [
  layoutSmallPyramid,   //  48 tiles
  layoutSmallCross,     //  48 tiles
  layoutPortraitPyramid, // 144 tiles
  layoutTwinTowers,     // 144 tiles
  layoutCross,          // 144 tiles
];

List<(int, int, int)> _build(List<(int, int, int)> Function() fn) => fn();
