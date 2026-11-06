# CLAUDE.md — People Bubble App

Context for the coding agent working in this repo. The full product spec is the plan doc
at `docs/People Bubble App — Plan.md`. Read it first; this file adds the
background, decisions and working rules that aren't in it.

## The project in one paragraph

A personal Android app (Flutter) for remembering what the people Jared cares about like and
dislike. People and things are bubbles (nodes) joined by styled lines (edges). Two views of
the same data: a freeform bubble canvas (main) and a collapsible list. Mostly for personal
use; it may go on the Play Store later, so keep it structured like a real app.

## About the developer

- Jared, a CS/Physics student, mostly self-taught, with practical experience in several
  languages (notably C#/WinUI and Lua) and web development.
- Flutter/Dart may be new to him. When you introduce a Flutter or Dart concept for the first
  time (widgets vs. state, Riverpod providers, drift codegen, `CustomPainter`), explain it in
  a sentence or two. A C# comparison helps where one fits.
- Target device: his own Android phone. Test on a real device over USB as well as the emulator.

## Decisions already made (don't re-litigate without asking)

- **Stack:** Flutter + Dart, Riverpod for state, drift (SQLite) for storage, JSON export/import
  for backup.
- **Graph, not tree.** Nodes can have multiple parents (shared children). Hierarchical edges
  must never form a cycle; block that at creation time.
- **Edges are hierarchical by default.** An edge type can turn hierarchy off. Non-hierarchical
  edges show in the list view as faded "shadow" rows: no children, tapping one jumps to the
  real node.
- **Each edge has exactly two ends.** Waypoints are separate entities that several edges can
  share. Dragging one waypoint onto another merges them; this is "clamping".
- **Types are class-like:**
  - Single-parent inheritance; each type sets only the style fields it cares about (nullable).
  - A node can have multiple types if they don't conflict. Two types conflict when their fully
    resolved field sets give the same field different values. Values inherited from a common
    ancestor are equal, so they never conflict.
  - Assigning a type plus its own ancestor is redundant; keep the more specific one.
  - An edge has exactly one type.
  - Style resolution order: app defaults → each assigned type from its top ancestor down →
    the item's own overrides.
  - Editing a type in a way that would create conflicts on existing nodes is blocked, and the
    affected nodes are listed.
  - The user's canonical example: Person → {Partner (pink border, custom font), Board Gamer
    (dotted border), Friend (blue border)}. Partner+Board Gamer is OK; Partner+Friend is a
    conflict. Use this as a unit-test fixture.
- **Auto-placement:**
  - A node with parents goes near its parent (or the average of its parents), fanning away
    from the grandparent.
  - A node with no parent goes in clear space well away from other nodes.
  - Never fully cover an existing node.
  - Pan to show the new node. The algorithm is in the plan doc.
- **Mobile UX priority:**
  - Basic actions (add person, add like, move things) must be one or two taps.
  - Advanced styling lives behind "More".
  - Node and line actions go through a radial wheel opened by long-press.
  - Touch targets are at least 48 dp; thin lines need wide invisible hit areas.

## Resolved questions (confirmed Nov 5, 2026)

- Shadow rows appear under **both** ends of a non-hierarchical edge.
- A node with no type falls back to base `Node`.
- An edge has exactly one type.
- Shared subtrees show in full under every parent, collapsed after the first appearance.
- Seeded `Loves` is a subtype of `Likes`.

## Data-model decisions (confirmed Nov 6, 2026)

- IDs are UUID v4 strings. Built-in seed rows use fixed, readable IDs (e.g. `node-type-person`)
  so they match across devices on import.
- Style fields are stored as one JSON text column per row (types and per-item overrides),
  mapped to typed `NodeStyle` / `EdgeStyle` classes by a drift `TypeConverter`.
- Conflict check compares only the fields a type sets itself or through its ancestors,
  **excluding the base type's defaults**. (Otherwise every type would conflict with Partner.)
  A type and its own ancestor never conflict; the ancestor is dropped as redundant.
- Built-in base types `Node` and `Edge` are the roots of the two type trees, hold the default
  style, and can't be deleted. Base `Edge` has `hierarchical = true`; the flag is inherited.
- Node `x`/`y` are nullable: null means "not placed yet"; the canvas places it on first show.
- Every row has `createdAt` / `updatedAt`.

## List-view decisions (confirmed Nov 6, 2026)

- Swipe left on a child row offers **Unlink** (remove just that line) and **Delete** (the
  bubble everywhere, after a confirm that says how many lines go too). Root rows: Delete only.
- Add sheet defaults: **Thing** for children, **Person** for the "add person" button; the sheet
  remembers the last picks while open.
- Order: roots are people first, then A–Z. Children are grouped by line type (Loves, Likes,
  Dislikes, then others), A–Z within a group.
- Everything starts expanded except repeat appearances of shared bubbles. Expand state is
  in-memory only (per app run).
- After **Add** the sheet stays open with the name cleared and focused, for quick runs.
- The last-used line type persists across launches (`shared_preferences`).

## Project setup facts

- Application ID: `com.jade.peoplebubble`. Dart package: `people_bubble`.
- Flutter SDK lives at `C:\dev\flutter` (no spaces in the path).
- Riverpod: plain hand-written providers, no `riverpod_generator`.
- Test phone: Samsung Galaxy S24 (SM-S921U), Android 17.
- Git: local repo; the developer will create the GitHub remote.
- Dev data: use made-up fake people/likes (a debug-only seed), not real data.

## How to work

- Follow the build phases in the plan doc, in order. **Every phase must end with something
  that runs on the phone.** The list view (phase 3) comes before the canvas on purpose.
- Before starting a phase, state the plan briefly and confirm. Ask before changing the data
  model or the type rules.
- Put all data writes through one service/repository layer: UI → service → drift. Future AI
  features (natural-language quick-add) must be able to call the same layer.
- Keep pure logic in plain Dart with no Flutter imports, and unit-test it:
  - style resolution
  - type conflict detection
  - cycle detection
  - list-tree building (including shared nodes and shadow rows)
  - auto-placement scoring
- Use a `schema_version` and drift migrations from the first table.

## Suggested layout

```
lib/
  data/        drift tables, DAOs, JSON import/export
  domain/      models, style resolution, conflict check, cycle check, placement (pure Dart)
  services/    graph service (all writes go here)
  ui/
    canvas/    painter, gestures, radial wheel
    list/      tree list, add sheet
    types/     type editor
  main.dart
test/          unit tests for domain/
```

## Known pitfalls

- **`InteractiveViewer` vs. item dragging:** pan/zoom gestures fight with node drags. Decide
  per pointer-down whether the hit landed on an item. If it did, handle the drag yourself and
  disable the viewer's pan for that gesture.
- **Hit testing:** convert screen coordinates to canvas coordinates using the viewer's
  `TransformationController` matrix inverse.
- **Dashed/dotted lines:** `Canvas` has no built-in dash; build dashes from `PathMetrics`.
- **drift uses code generation:** run `dart run build_runner build` (or `watch`) after editing
  tables.
- **Drag performance:** save positions on drag end only, and repaint just the canvas. Check
  performance with about 300 nodes.
- **Cycles:** the list view and any recursive walk must guard against cycles even though
  creation blocks them, because an import could contain bad data.

## Seed data (first launch)

- Node types: base `Node`, `Person`, `Thing`.
- Edge types: `Likes` (green), `Loves` (pink), `Dislikes` (red), `Related` (grey, dotted,
  non-hierarchical).
