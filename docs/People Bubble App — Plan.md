# People Bubble App — Plan

Nov 5, 2026 · @Jade L

## Overview

An Android-first app for remembering what the people I care about like and dislike. People and things are bubbles (nodes), joined by styled lines (edges). The app has two views of the same data: a freeform bubble canvas and a collapsible list.

Design principles:

- **Simple by default.** Adding a person, adding a like, and moving things around take one or two taps. Styling and advanced tools sit one level deeper.
- **Graph, not tree.** A thing can belong to several people (two friends who both love sushi share one Sushi node).
- **Types do the styling.** Pick a type and the item looks right; hand-styling is the exception.
- **Mostly for me first.** Built for personal use, structured so it could ship to the Play Store later.

## Platform and tech stack

Build it in **Flutter (Dart)**. The heart of the app is a custom canvas with drag, pinch-zoom and long-press, which Flutter draws and handles well. One codebase covers Android now and iOS later, and Play Store publishing is routine.

| Layer | Choice | Why |
| --- | --- | --- |
| UI framework | Flutter | Custom canvas, smooth gestures, Android + iOS |
| Canvas | `CustomPainter` inside `InteractiveViewer` | Full control of shapes, dashed lines, waypoints; built-in pan/zoom |
| State | Riverpod | Testable, scales from a small app to a store app |
| Database | SQLite via `drift` | Relational fits nodes/edges/types; typed queries; migrations |
| Backup | JSON export/import | Human-readable, portable, base for future sync |

Alternatives considered: .NET MAUI keeps you in C# but has weaker custom-canvas and gesture support. A web app wrapped in Capacitor iterates fastest but feels less native.

## Data model

The data is a directed graph: nodes joined by edges, with edges optionally bent through shared waypoints. Hierarchical edges must never form a loop, which keeps the list view finite.

| Entity | Fields | Notes |
| --- | --- | --- |
| Node | id, label, x, y, type ids (list), style overrides (nullable) | Root = a node with no incoming hierarchical edge, so one root or several is automatic |
| Edge | id, source node, target node, type id, label (optional), waypoint ids (ordered), style overrides (nullable) | Source = parent, target = child; exactly two ends |
| Waypoint | id, x, y | Shared by any number of edges; dragging one waypoint onto another merges them (clamping) |
| NodeType | id, name, parent type id, style fields (nullable) | Class-like; see Type system |
| EdgeType | id, name, parent type id, style fields (nullable), hierarchical (bool, default true) | Non-hierarchical edges ignore the parent/child structure |

Node style fields: font family, font color, font size, bold, shape, shape width/height, fill color, outline color, outline width, outline style (solid/dotted/dashed).

Edge style fields: width, dash pattern (solid/dotted/dashed), color, arrowhead (none/end).

Rules:

- Creating a hierarchical edge that would form a loop is blocked with a message.
- Deleting a node deletes its edges; waypoints no edge uses are cleaned up.
- A node with several parents is one node, drawn once on the canvas.

## Type system

Types work like classes: each type has one parent type, inherits its parent's style, and sets only the fields it cares about. A node can carry several types at once, as long as no two of them set the same field to different values. Edge types follow the same rules.

Example hierarchy (`Node` is the built-in base type):

| Type | Parent | Sets |
| --- | --- | --- |
| Node | (base) | App defaults for every field |
| Person | Node | Rounded box, large size, thick outline, large bold text |
| Partner | Person | Outline color pink, custom font |
| Board Gamer | Person | Outline style dotted |
| Friend | Person | Outline color blue |

Allowed: Board Gamer + Partner, Board Gamer + Friend, Board Gamer alone. Blocked: Friend + Partner, because both set outline color.

### How a node's final style is worked out

1. Start from the app defaults (base `Node`).
2. For each assigned type, walk from its top ancestor down to the type itself, applying every field that is set.
3. Apply the node's own overrides last.

Because conflicting types can't be combined, the order of assigned types never changes the result.

### Conflict check

- Resolve each assigned type's full field set (itself plus ancestors).
- Two types conflict if any field has a different value in each. Fields they share from a common ancestor are equal, so they never conflict.
- Assigning a type and one of its own ancestors is redundant; keep only the more specific one.
- In the type picker, conflicting types are greyed out with a short reason ("conflicts with Partner: outline color").
- Editing a type so that it would conflict on existing nodes is blocked, and the app lists the affected nodes.

### Edge types

Same inheritance and conflict rules, but an edge has exactly one type. Example: `Likes` (green, solid) → `Loves` (pink, thicker). The `hierarchical` flag is inherited too, so a `Related` type set to non-hierarchical passes that on to its subtypes.

## Bubble view

The main view is an infinite canvas where everything is moved by touch and acted on through a radial wheel.

### Gestures

| Gesture | On empty canvas | On a node | On a line | On a waypoint |
| --- | --- | --- | --- | --- |
| Tap | Deselect | Select | Select | Select |
| Drag | Pan | Move node | Insert a waypoint at that spot and move it | Move waypoint (snap-merge onto another waypoint to clamp) |
| Pinch | Zoom | Zoom | Zoom | Zoom |
| Long-press | Wheel: add node here | Node wheel | Line wheel | Waypoint wheel |
| Double-tap | Zoom to fit | Edit label | Edit label | (none) |

### Radial wheels

The wheel opens under the finger; slide toward a slice and lift to choose. Each wheel has at most 6 slices, with More opening a second ring.

- **Node:** add child, link to existing, edit label, change types, delete, More (style overrides, select subtree, focus).
- **Line:** change type, edit label, add waypoint, delete, More (style overrides, reverse direction).
- **Waypoint:** unclamp (split shared waypoint), delete waypoint.
- **Empty canvas:** new node here (root), paste, zoom to fit.

### Drawing

- Lines render as polylines through their waypoints, optionally smoothed.
- Labels sit at the midpoint of the line's longest segment.
- Selected items show a highlight; when an edge is selected, its waypoints become visible handles.
- Hit areas are at least 48 dp so thin lines stay easy to tap.

## List view

A collapsible outline built by walking hierarchical edges down from every root. It is the fastest way to add and review entries.

### What each row shows

- Node label, styled with its type colors at a small size, plus the line type that connects it to the row above ("loves", "dislikes").
- A link marker on a node that has more than one parent. Tapping it lists the other parents and jumps to any of them.
- A shared node shows its full subtree under every parent, collapsed by default after its first appearance.

### Shadow rows (non-hierarchical links)

- A non-hierarchical edge appears as a faded "shadow" row under both of its ends, labeled with the edge type.
- A shadow row has no children and no expand arrow.
- Tapping a shadow row jumps to the real node: the list scrolls and expands to it, with a brief highlight.

### Adding from the list

Every row has a + button that opens one sheet with two tabs:

1. **New:** type a label, pick node types (conflicts greyed out), pick the line type. Creates the node and the line together.
2. **Existing:** search all nodes, pick one, pick the line type. Creates only the line, so the item becomes shared.

The line type defaults to the last one used, so entering a run of "likes" takes one tap each. Nodes created here are auto-placed on the canvas (see Auto-placement).

### Other actions

Swipe a row to edit or delete. Long-press a row to drag it under a different parent, which moves the edge.

## Auto-placement

New nodes land near their parent, or well clear of everything if they have no parent, and never fully covering an existing node.

### Node with one or more parents

1. **Anchor:** the parent's position, or the average position of all parents.
2. **Preferred direction:** away from the parent's own parent, so trees fan outward. For a root parent, use the widest gap between its existing children.
3. **Candidates:** points on rings around the anchor (radius = parent size + 1.5 × child size, then larger rings), every 20° starting from the preferred direction.
4. **Score each candidate:** overlap area with existing node boxes (padded by 16 dp), plus a small penalty for distance from the anchor and for turning away from the preferred direction.
5. Take the first candidate with zero overlap. If none has zero after 4 rings, take the lowest score; partial overlap is allowed, full cover is not.

### Node with no parent

1. Search outward in a spiral from the center of the current screen.
2. Accept the first spot with at least 3 node-widths of clearance from every other node.
3. If the screen has no such spot, place the node just outside the bounding box of all nodes and pan to it.

### After placement

The canvas pans just enough to show the new node, so it's never placed off-screen silently.

## Storage and backup

All data lives on the phone in SQLite; JSON export is the backup and the future path to sync.

- Tables: `nodes`, `node_type_links` (node ↔ type), `edges`, `edge_waypoints` (edge, waypoint, order), `waypoints`, `node_types`, `edge_types`. Use a `schema_version` field and drift migrations from day one.
- Positions save when a drag ends, not on every frame.
- Undo/redo: keep an in-memory command stack of 50 steps per session.
- Export: one JSON file with every table plus the schema version, shared through Android's share sheet. Import either replaces everything or merges, matching records by id.
- Seeded on first launch: base `Node`, `Person`, `Thing`; edge types `Likes` (green), `Loves` (pink), `Dislikes` (red), and a non-hierarchical `Related` (grey, dotted).

## Build phases

The list view comes before the canvas, so the app is usable after phase 3. Each phase ends with something runnable on the phone.

1. **Setup:** Flutter, Android Studio emulator plus a real phone over USB, project skeleton, Riverpod, drift.
2. **Data layer:** tables, type inheritance and style resolution, the conflict check, cycle check, seed types. Unit tests for resolution and conflicts.
3. **List view:** tree from roots, expand/collapse, shared markers, shadow rows, the add sheet (New and Existing), edit and delete.
4. **Canvas basics:** draw nodes (shapes, text, outlines) and straight edges from saved positions; pan and zoom.
5. **Canvas editing:** select, drag nodes, auto-placement, double-tap to edit.
6. **Radial wheel:** node, line and canvas wheels for the core actions.
7. **Waypoints:** add, drag, merge (clamp), unclamp; polyline drawing and line labels.
8. **Type editor:** create, edit and nest node and edge types; pick multiple types with conflicts greyed out; per-item overrides behind More.
9. **Safety and polish:** undo/redo, JSON export/import, empty states, performance check with about 300 nodes.
10. **Later:** AI features, integrations, Play Store release (see next section).

## Future and open decisions

### Later features

- **AI quick-add:** type "Sam loves sushi, hates cilantro" and the app proposes the nodes and lines for one-tap confirmation. Keep all writes going through one service layer so AI and UI share the same path.
- **AI recall:** ask "gift ideas for Sam" and get suggestions drawn from Sam's likes.
- **Integrations:** contact photos for Person nodes, birthday reminders, cloud sync.
- **Play Store:** privacy policy (all data local), app icon, store listing, signed release build.

### Open decisions

- [x] Can a node have no type at all, or does it fall back to base `Node`? (Decided: falls back to `Node`.)
- [x] Should an edge be allowed to have more than one type, like nodes? (Decided: one type only.)
- [x] Should shared subtrees in the list expand fully under every parent, or only under the first? (Decided: full subtree everywhere, collapsed after the first.)
