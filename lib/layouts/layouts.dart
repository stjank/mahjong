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

// ── Layout definitions ────────────────────────────────────────────────────────

/// Tall portrait pyramid — 8 cols × 9 rows base, 5 layers. (144 tiles)
final LayoutDef layoutPortraitPyramid = LayoutDef(
  id: 'portrait_pyramid',
  name: 'Pyramid',
  description: 'Classic tall pyramid\n144 tiles · 5 layers',
  positions: _build(() {
    final p = <(int, int, int)>[];
    // L0: 8×9=72
    for (int x = 0; x <= 14; x += 2) {
      for (int y = 0; y <= 16; y += 2) p.add((x, y, 0));
    }
    // L1: 6×6=36
    for (int x = 2; x <= 12; x += 2) {
      for (int y = 2; y <= 12; y += 2) p.add((x, y, 1));
    }
    // L2: 4×5=20
    for (int x = 4; x <= 10; x += 2) {
      for (int y = 4; y <= 12; y += 2) p.add((x, y, 2));
    }
    // L3: 4×3=12
    for (int x = 4; x <= 10; x += 2) {
      for (int y = 6; y <= 10; y += 2) p.add((x, y, 3));
    }
    // L4: 2×2=4
    for (int x = 6; x <= 8; x += 2) {
      for (int y = 6; y <= 8; y += 2) p.add((x, y, 4));
    }
    assert(p.length == 144);
    return p;
  }),
);

/// Wide flat pyramid — 14 cols × 4 rows base, 4 layers. (144 tiles)
final LayoutDef layoutWidePyramid = LayoutDef(
  id: 'wide_pyramid',
  name: 'Wide Pyramid',
  description: 'Flat wide pyramid\n144 tiles · 4 layers',
  positions: _build(() {
    final p = <(int, int, int)>[];
    // L0: 14×4=56
    for (int x = 0; x <= 26; x += 2) {
      for (int y = 0; y <= 6; y += 2) p.add((x, y, 0));
    }
    // L1: 12×4=48
    for (int x = 2; x <= 24; x += 2) {
      for (int y = 0; y <= 6; y += 2) p.add((x, y, 1));
    }
    // L2: 8×4=32
    for (int x = 6; x <= 20; x += 2) {
      for (int y = 0; y <= 6; y += 2) p.add((x, y, 2));
    }
    // L3: 4×2=8
    for (int x = 10; x <= 16; x += 2) {
      for (int y = 2; y <= 4; y += 2) p.add((x, y, 3));
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
      // L0: 4×6=24
      for (int x = xOff; x <= xOff + 6; x += 2) {
        for (int y = 0; y <= 10; y += 2) p.add((x, y, 0));
      }
      // L1: 4×6=24
      for (int x = xOff; x <= xOff + 6; x += 2) {
        for (int y = 0; y <= 10; y += 2) p.add((x, y, 1));
      }
      // L2: 4×4=16
      for (int x = xOff; x <= xOff + 6; x += 2) {
        for (int y = 2; y <= 8; y += 2) p.add((x, y, 2));
      }
      // L3: 2×4=8
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
    // L0 (60): vertical bar + horizontal arms
    for (int x = 4; x <= 10; x += 2) {       // vertical: 4×11=44
      for (int y = 0; y <= 20; y += 2) p.add((x, y, 0));
    }
    for (int x = 0; x <= 2; x += 2) {        // left arm: 2×4=8
      for (int y = 6; y <= 12; y += 2) p.add((x, y, 0));
    }
    for (int x = 12; x <= 14; x += 2) {      // right arm: 2×4=8
      for (int y = 6; y <= 12; y += 2) p.add((x, y, 0));
    }
    // L1 (36): x∈{4..10} × y∈{2..18}
    for (int x = 4; x <= 10; x += 2) {
      for (int y = 2; y <= 18; y += 2) p.add((x, y, 1));
    }
    // L2 (28): x∈{4..10} × y∈{4..16}
    for (int x = 4; x <= 10; x += 2) {
      for (int y = 4; y <= 16; y += 2) p.add((x, y, 2));
    }
    // L3 (16): x∈{4..10} × y∈{6..12}
    for (int x = 4; x <= 10; x += 2) {
      for (int y = 6; y <= 12; y += 2) p.add((x, y, 3));
    }
    // L4 (4): x∈{6,8} × y∈{8,10}
    for (int x = 6; x <= 8; x += 2) {
      for (int y = 8; y <= 10; y += 2) p.add((x, y, 4));
    }
    assert(p.length == 144, 'Cross: expected 144, got ${p.length}');
    return p;
  }),
);

final List<LayoutDef> allLayouts = [
  layoutPortraitPyramid,
  layoutWidePyramid,
  layoutTwinTowers,
  layoutCross,
];

// Helper so const-like factory lambdas read cleanly.
List<(int, int, int)> _build(List<(int, int, int)> Function() fn) => fn();
