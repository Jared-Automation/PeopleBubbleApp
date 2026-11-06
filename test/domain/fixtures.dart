import 'package:people_bubble/domain/style.dart';
import 'package:people_bubble/domain/types.dart';

const pink = 0xFFE91E63;
const blue = 0xFF1E88E5;

/// The canonical example from the spec:
/// Node → Person → {Partner (pink outline, custom font), Board Gamer (dotted),
/// Friend (blue outline)}.
final canonicalNodeTypes = TypeHierarchy.nodes([
  const NodeTypeDef(
    id: 'node',
    name: 'Node',
    parentId: null,
    style: NodeStyle.appDefaults,
    builtIn: true,
  ),
  const NodeTypeDef(
    id: 'person',
    name: 'Person',
    parentId: 'node',
    style: NodeStyle(
      shape: NodeShape.roundedRect,
      width: 140,
      outlineWidth: 3,
      bold: true,
      fontSize: 18,
    ),
  ),
  const NodeTypeDef(
    id: 'partner',
    name: 'Partner',
    parentId: 'person',
    style: NodeStyle(outlineColor: pink, fontFamily: 'serif'),
  ),
  const NodeTypeDef(
    id: 'gamer',
    name: 'Board Gamer',
    parentId: 'person',
    style: NodeStyle(outlineStyle: LineStyle.dotted),
  ),
  const NodeTypeDef(
    id: 'friend',
    name: 'Friend',
    parentId: 'person',
    style: NodeStyle(outlineColor: blue),
  ),
  const NodeTypeDef(
    id: 'thing',
    name: 'Thing',
    parentId: 'node',
    style: NodeStyle(shape: NodeShape.ellipse),
  ),
]);

/// Edge → Likes (green) → Loves (pink, thicker); Edge → Related (dotted,
/// non-hierarchical).
final canonicalEdgeTypes = TypeHierarchy.edges([
  const EdgeTypeDef(
    id: 'edge',
    name: 'Edge',
    parentId: null,
    style: EdgeStyle.appDefaults,
    builtIn: true,
  ),
  const EdgeTypeDef(
    id: 'likes',
    name: 'Likes',
    parentId: 'edge',
    style: EdgeStyle(color: 0xFF43A047),
  ),
  const EdgeTypeDef(
    id: 'loves',
    name: 'Loves',
    parentId: 'likes',
    style: EdgeStyle(color: pink, width: 3),
  ),
  const EdgeTypeDef(
    id: 'related',
    name: 'Related',
    parentId: 'edge',
    style: EdgeStyle(lineStyle: LineStyle.dotted, hierarchical: false),
  ),
]);
